"""Exercise version planning/apply on temporary copies, never build binaries."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[4]
HELPER = Path(__file__).with_name('prepare_release.rb')


class ReleasePreparationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name in ('pubspec.yaml', 'android/release.properties',
                     'tools/android_releases.json'):
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)
        shutil.copytree(ROOT / 'ios/Runner.xcodeproj', self.root / 'ios/Runner.xcodeproj')
        for slug in ('bmcargo', 'tupaq'):
            for name in (f'whitelabel/{slug}.json', f'lib/apps/{slug}/main_{slug}.dart'):
                target = self.root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / name, target)
        self.files = [self.root / name for name in (
            'pubspec.yaml', 'android/release.properties', 'ios/Runner.xcodeproj/project.pbxproj')]

    def run_helper(self, *args, success=True):
        result = subprocess.run(['/usr/bin/ruby', str(HELPER), '--root', str(self.root), *args],
                                text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
            return json.loads(result.stdout)
        self.assertNotEqual(result.returncode, 0)

    def objects(self):
        return json.loads(subprocess.check_output([
            'plutil', '-convert', 'json', '-o', '-', str(self.files[2])]))['objects']

    def test_plan_leaves_sources_untouched(self):
        before = [p.read_bytes() for p in self.files]
        plan = self.run_helper('--ios', 'bmcargo,tupaq', '--android', 'tupaq')
        self.assertEqual(before, [p.read_bytes() for p in self.files])
        self.assertEqual(len(plan['ios']), 2)
        self.assertEqual(plan['android'][0]['code'], plan['android'][0]['fromCode'] + 1)
        self.assertEqual(plan['ios'][0]['build'], plan['ios'][1]['build'])

    def test_apply_updates_only_selected_release_targets(self):
        before = self.objects()
        plan = self.run_helper('--ios', 'bmcargo,tupaq', '--android', 'tupaq', '--apply')
        after = self.objects()
        changed = 0
        for key, obj in before.items():
            if obj.get('isa') == 'XCBuildConfiguration' and obj.get('name') in ('Release-bmcargo', 'Release-tupaq') and 'CURRENT_PROJECT_VERSION' in obj.get('buildSettings', {}):
                expected = json.loads(json.dumps(obj))
                expected['buildSettings']['CURRENT_PROJECT_VERSION'] = str(plan['ios'][0]['build'])
                self.assertEqual(after[key], expected)
                changed += 1
            else:
                self.assertEqual(after[key], obj)
        self.assertEqual(changed, 4)  # Runner and widget for both couriers.
        self.assertIn(plan['pubspec']['to'], self.files[0].read_text())
        self.assertIn(f"versionCode={plan['android'][0]['code']}", self.files[1].read_text())

    def test_android_only_preserves_ios(self):
        before = [p.read_bytes() for p in (self.files[0], self.files[2])]
        self.run_helper('--android', 'tupaq', '--apply')
        self.assertEqual(before, [p.read_bytes() for p in (self.files[0], self.files[2])])

    def test_optional_version_preserves_android_code_for_ios_only(self):
        before = self.files[1].read_bytes()
        self.run_helper('--ios', 'tupaq', '--version', '2099.1.0', '--apply')
        self.assertEqual(before, self.files[1].read_bytes())
        self.assertIn('version: 2099.1.0+', self.files[0].read_text())
        configs = [o for o in self.objects().values() if o.get('name') == 'Release-tupaq'
                   and 'MARKETING_VERSION' in o.get('buildSettings', {})]
        self.assertEqual(len(configs), 2)
        self.assertTrue(all(o['buildSettings']['MARKETING_VERSION'] == '2099.1.0' for o in configs))

    def test_invalid_requests_never_write(self):
        before = [p.read_bytes() for p in self.files]
        self.run_helper('--ios', 'unknown', '--apply', success=False)
        self.run_helper('--ios', 'tupaq', '--version', '1.0.0', '--apply', success=False)
        self.assertEqual(before, [p.read_bytes() for p in self.files])


if __name__ == '__main__':
    unittest.main()
