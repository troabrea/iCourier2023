"""Run with python3 -m unittest discover -s tools -p 'test_android_release.py'."""
import contextlib
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import android_release as release


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for folder in ('android/signing', 'tools', 'whitelabel', 'lib/apps/pns', 'lib/apps/almapac'):
            (self.root / folder).mkdir(parents=True)
        (self.root / 'android/release.properties').write_text('versionCode=5202700\n')
        self.profile = self.root / 'android/signing/release.env'
        self.store = self.root / 'test.keystore'
        self.store.touch()
        self.write_profile()

    def write_profile(self, omitted=()):
        values = dict(zip(release.SIGNING_KEYS, (str(self.store), 'a $literal password', 'android', 'keypass')))
        self.profile.write_text('\n'.join(f"export {k}='{v}'" for k, v in values.items() if k not in omitted))
        self.profile.chmod(0o600)

    def test_version_source_and_limits(self):
        self.assertEqual(release.version_code(self.root), 5202700)
        for invalid in ('0', '-1', '2100000001', 'abc', '1\nversionCode=2'):
            (self.root / 'android/release.properties').write_text('versionCode=' + invalid)
            with self.assertRaises(release.ReleaseError):
                release.version_code(self.root)

    def test_published_version_ordering(self):
        self.assertIn('pendiente', release.check_version(5202700, None))
        self.assertIn('mayor', release.check_version(5202700, 5202605))
        for published in (5202700, 5202701, '58', True, 0):
            with self.assertRaises(release.ReleaseError):
                release.check_version(5202700, published)

    def test_profile_cannot_reuse_inherited_secrets(self):
        inherited = {key: 'wrong inherited value' for key in release.SIGNING_KEYS}
        inherited['PATH'] = 'preserved'
        env = release.read_profile(self.profile, inherited)
        self.assertEqual(env['ANDROID_KEYSTORE_PASSWORD'], 'a $literal password')
        self.assertEqual(env['PATH'], 'preserved')
        self.write_profile(omitted=['ANDROID_KEY_PASSWORD'])
        with self.assertRaisesRegex(release.ReleaseError, 'ANDROID_KEY_PASSWORD'):
            release.read_profile(self.profile, inherited)

    def test_profile_permissions_and_no_shell_execution(self):
        self.profile.chmod(0o644)
        with self.assertRaises(release.ReleaseError):
            release.read_profile(self.profile, {})
        self.profile.chmod(0o600)
        self.profile.write_text('echo DO_NOT_EXECUTE\n')
        with self.assertRaises(release.ReleaseError):
            release.read_profile(self.profile, {})

    def test_certificate_mismatch(self):
        release.require_fingerprint('A' * 64, ':'.join(['aa'] * 32))
        for expected in ('B' * 64, None, 'malformed'):
            with self.assertRaises(release.ReleaseError):
                release.require_fingerprint('A' * 64, expected)

    def test_entrypoint_exceptions(self):
        (self.root / 'lib/apps/pns/main_pns.dart').touch()
        (self.root / 'lib/apps/almapac/main_almapaq.dart').touch()
        self.assertEqual(release.entrypoint(self.root, 'picknsend'), 'lib/apps/pns/main_pns.dart')
        self.assertEqual(release.entrypoint(self.root, 'almapaq'), 'lib/apps/almapac/main_almapaq.dart')

    def test_help_list_unknown_and_pending(self):
        (self.root / 'tools/android_releases.json').write_text(json.dumps({'tupaq': {'profile': None}}))
        (self.root / 'whitelabel/tupaq.json').write_text('{}')
        with contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(release.main([], self.root), 2)
            self.assertEqual(release.main(['--list'], self.root), 0)
        self.assertIn('PENDIENTE', output.getvalue())
        for name in ('unknown', 'tupaq'):
            with self.assertRaises(release.ReleaseError):
                release.prepare(self.root, name, {})

    def test_manifest_from_bundle(self):
        xml = '<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.barolit.tupaq" android:versionCode="5202700" android:versionName="2027.0.2"/>'
        self.assertEqual(release.check_manifest(xml, 'com.barolit.tupaq', 5202700), '2027.0.2')
        for package, code in [('com.barolit.other', 5202700), ('com.barolit.tupaq', 58)]:
            with self.assertRaises(release.ReleaseError):
                release.check_manifest(xml, package, code)

    def test_external_profile_preserves_certificate_checks_without_copying(self):
        records = {'tupaq': {'profile': 'release', 'certificateSha256': 'A' * 64,
                            'lastPublishedVersionCode': None}}
        (self.root / 'tools/android_releases.json').write_text(json.dumps(records))
        (self.root / 'whitelabel/tupaq.json').write_text('{}')
        target = self.root / 'lib/apps/tupaq/main_tupaq.dart'
        target.parent.mkdir()
        target.touch()
        external = self.root / 'external.env'
        self.profile.rename(external)
        before = external.read_bytes()
        with patch.object(release, 'signing_fingerprint', return_value='A' * 64):
            release.prepare(self.root, 'tupaq', {}, str(external))
        self.assertFalse(self.profile.exists())
        self.assertEqual(external.read_bytes(), before)
        with patch.object(release, 'signing_fingerprint', return_value='B' * 64):
            with self.assertRaises(release.ReleaseError):
                release.prepare(self.root, 'tupaq', {}, str(external))
        with self.assertRaises(release.ReleaseError):
            release.prepare(self.root, 'tupaq', {}, 'relative.env')

    def test_all_flavors_use_common_version(self):
        text = (release.ROOT / 'android/app/build.gradle.kts').read_text()
        self.assertEqual(text.count('versionCode = '), 1)
        self.assertIn('versionCode = sharedAndroidVersionCode', text)
        records = json.loads((release.ROOT / 'tools/android_releases.json').read_text())
        for flavor in records:
            self.assertTrue((release.ROOT / release.entrypoint(release.ROOT, flavor)).is_file())


class RealSignatureTests(unittest.TestCase):
    """Exercise Java verification with disposable real keys; no production secrets."""
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.temp.name)
        cls.env = dict(os.environ, ANDROID_KEYSTORE_PATH=str(cls.root / 'test.jks'),
                       ANDROID_KEYSTORE_PASSWORD='fixture-store-password', ANDROID_KEY_ALIAS='fixture',
                       ANDROID_KEY_PASSWORD='fixture-key-password')
        subprocess.run(['keytool', '-genkeypair', '-keystore', cls.env['ANDROID_KEYSTORE_PATH'],
                        '-storetype', 'JKS', '-storepass:env', 'ANDROID_KEYSTORE_PASSWORD',
                        '-keypass:env', 'ANDROID_KEY_PASSWORD', '-alias', 'fixture',
                        '-keyalg', 'RSA', '-dname', 'CN=Test', '-validity', '1'],
                       env=cls.env, check=True, capture_output=True)
        cls.unsigned = cls.root / 'unsigned.aab'
        with zipfile.ZipFile(cls.unsigned, 'w') as bundle:
            bundle.writestr('base/manifest/AndroidManifest.xml', b'test-manifest')
            bundle.writestr('base/assets/test', b'original')
        cls.signed = cls.root / 'signed.aab'
        subprocess.run(['jarsigner', '-keystore', cls.env['ANDROID_KEYSTORE_PATH'],
                        '-storepass:env', 'ANDROID_KEYSTORE_PASSWORD', '-keypass:env', 'ANDROID_KEY_PASSWORD',
                        '-signedjar', str(cls.signed), str(cls.unsigned), 'fixture'],
                       env=cls.env, check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def test_private_key_passwords_and_alias(self):
        self.assertEqual(len(release.signing_fingerprint(release.ROOT, self.env)), 64)
        for key in ('ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_PASSWORD', 'ANDROID_KEY_ALIAS'):
            with self.assertRaises(release.ReleaseError):
                release.signing_fingerprint(release.ROOT, dict(self.env, **{key: 'wrong'}))

    def test_unsigned_modified_and_partially_signed_bundles(self):
        expected = release.signing_fingerprint(release.ROOT, self.env)
        self.assertEqual(release.signing_fingerprint(release.ROOT, self.env, self.signed), expected)
        with self.assertRaises(release.ReleaseError):
            release.signing_fingerprint(release.ROOT, self.env, self.unsigned)
        for action in ('modify', 'add'):
            changed = self.root / f'{action}.aab'
            with zipfile.ZipFile(self.signed) as src, zipfile.ZipFile(changed, 'w') as dst:
                for name in src.namelist():
                    data = src.read(name)
                    if action == 'modify' and name == 'base/assets/test':
                        data = b'tampered'
                    dst.writestr(name, data)
                if action == 'add':
                    dst.writestr('base/assets/unsigned', b'new unsigned content')
            with self.assertRaises(release.ReleaseError):
                release.signing_fingerprint(release.ROOT, self.env, changed)


if __name__ == '__main__':
    unittest.main()
