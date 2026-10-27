#!/usr/bin/env python3
"""Integration check using temporary keys, courier, profiles, and encryption public key."""
import argparse
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile


def command(args, env=None):
    result = subprocess.run(args, env=env, capture_output=True)
    if result.returncode:
        raise RuntimeError('Temporary-key test command failed: ' + args[0])
    return result.stdout


def run(pepk, bc):
    script = Path(__file__).with_name('export_signing.py')
    spec = importlib.util.spec_from_file_location('export_signing', script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    actual_root = module.ROOT
    with tempfile.TemporaryDirectory(prefix='icourier-signing-test-') as work:
        root = Path(work)
        module.ROOT = root
        (root / 'tools').mkdir()
        shutil.copy2(actual_root / 'tools/AndroidSigning.java', root / 'tools/AndroidSigning.java')
        (root / 'whitelabel').mkdir()
        (root / 'whitelabel/demo.json').write_text('{"bundleId":"com.example.signingtest"}')
        profiles = root / 'android/signing'
        profiles.mkdir(parents=True)
        test_env = {**os.environ, 'ICOURIER_TEST_STORE_PASSWORD': 'temporary-passphrase-123'}
        for name in ['legacy', 'release']:
            store = root / (name + '.jks')
            command(['keytool', '-genkeypair', '-keystore', str(store), '-alias', name,
                     '-keyalg', 'RSA', '-keysize', '2048', '-validity', '1', '-dname', 'CN=Temporary test',
                     '-storepass:env', 'ICOURIER_TEST_STORE_PASSWORD',
                     '-keypass:env', 'ICOURIER_TEST_STORE_PASSWORD'], test_env)
            values = {'ANDROID_KEYSTORE_PATH': str(store), 'ANDROID_KEY_ALIAS': name,
                      'ANDROID_KEYSTORE_PASSWORD': test_env['ICOURIER_TEST_STORE_PASSWORD'],
                      'ANDROID_KEY_PASSWORD': test_env['ICOURIER_TEST_STORE_PASSWORD']}
            profile = profiles / (name + '.env')
            profile.write_text(''.join(k + '=' + shlex.quote(v) + '\n' for k, v in values.items()))
            profile.chmod(0o600)
        public = root / 'encryption_public_key.pem'
        # The private encryption key is test-only and remains in the temporary directory.
        private = root / 'temporary-encryption-private.pem'
        command(['openssl', 'genpkey', '-algorithm', 'RSA', '-pkeyopt', 'rsa_keygen_bits:4096', '-out', str(private)])
        command(['openssl', 'pkey', '-in', str(private), '-pubout', '-out', str(public)])
        env = module.read_profile(profiles / 'legacy.env', os.environ)
        expected = module.signing_fingerprint(root, env)
        output = root / 'artifacts'
        args = ['demo', '--app-signing-profile', 'legacy', '--upload-profile', 'release',
                '--expected-app-sha256', expected, '--encryption-key', str(public),
                '--pepk-jar', str(pepk), '--bcprov-jar', str(bc), '--output-dir', str(output)]
        with contextlib.redirect_stdout(io.StringIO()) as captured:
            assert module.main(args + ['--check']) == 0
        assert not output.exists(), 'Check must not create export artifacts'
        assert 'preflight-validado' in captured.getvalue()
        with contextlib.redirect_stdout(io.StringIO()) as captured:
            assert module.main(args) == 0
        assert test_env['ICOURIER_TEST_STORE_PASSWORD'] not in captured.getvalue()
        data = json.loads((output / 'enrollment-artifacts.json').read_text())
        assert data['playEnrollment'] == 'pendiente'
        assert data['appSigningCertificateSha256'] != data['uploadCertificateSha256']
        for record in data['artifacts'].values():
            f = Path(record['path'])
            assert f.stat().st_size > 0 and hashlib.sha256(f.read_bytes()).hexdigest() == record['sha256']
        encrypted = output / 'demo-app-signing-encrypted.pepk'
        assert encrypted.stat().st_mode & 0o077 == 0
        try:
            module.main(args)
        except module.ReleaseError:
            pass
        else:
            raise AssertionError('Existing export must not be overwritten')
        bad = args.copy()
        bad[bad.index('--expected-app-sha256') + 1] = '0' * 64
        try:
            module.main(bad + ['--check'])
        except module.ReleaseError:
            pass
        else:
            raise AssertionError('Wrong original certificate must be rejected')
        try:
            module.main(args + ['--bcprov-sha256', '0' * 64, '--check'])
        except module.ReleaseError:
            pass
        else:
            raise AssertionError('Unverified provider JAR must be rejected')
        assert not (root / 'tools/android_releases.json').exists()
    print('PASS: preflight, real PEPK export, distinct certificates, private output, no overwrite, wrong-key/provider rejection.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pepk-jar', required=True)
    parser.add_argument('--bcprov-jar', required=True)
    args = parser.parse_args()
    run(Path(args.pepk_jar).resolve(), Path(args.bcprov_jar).resolve())
