from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MANAGER = SCRIPT_DIR / "manage_whitelabel.py"
IOS_ROUTINE = SCRIPT_DIR / "configure_ios_flavor.rb"
REPO = SCRIPT_DIR.parents[3]


class ManageWhitelabelTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "whitelabel").mkdir()
        (self.root / "lib/apps").mkdir(parents=True)
        (self.root / "android/app").mkdir(parents=True)
        (self.root / "tools").mkdir()
        (self.root / "pubspec.yaml").write_text(
            "flutter:\n  assets:\n    - translations/\n#    - images/boxpaq/\n"
        )
        (self.root / "android/app/build.gradle.kts").write_text(
            "android {\n"
            "    productFlavors {\n"
            '        create("existing") {\n'
            '            dimension = "app"\n'
            '            applicationId = "com.barolit.existing"\n'
            "        }\n"
            "    }\n\n"
            "    productFlavors.configureEach {\n"
            '        manifestPlaceholders["urlScheme"] = name\n'
            "    }\n"
            "}\n"
        )
        (self.root / "tools/android_releases.json").write_text(
            json.dumps(
                {
                    "existing": {
                        "applicationId": "com.barolit.existing",
                        "certificateSha256": "KEEP",
                        "lastPublishedVersionCode": 123,
                        "profile": "release",
                    }
                },
                indent=2,
            )
            + "\n"
        )
        self.manifest = {
            "slug": "sample",
            "name": "Sample",
            "bundleId": "com.barolit.sample",
            "appGroup": "group.com.barolit.sample",
            "urlScheme": "sample",
            "companyId": "00000000-0000-4000-8000-000000000000",
            "firebaseProject": "example-project",
            "iosTeam": "TEAMID1234",
            "version": "2027.0.2",
            "build": 65,
            "icon": "/missing/icon.png",
            "fonts": {"head": "Head", "body": "Body"},
            "palettes": {
                "light": {
                    "primary": "#123456",
                    "onPrimary": "#FFFFFF",
                    "secondary": "#654321",
                    "onSecondary": "#FFFFFF",
                },
                "dark": {
                    "primary": "#ABCDEF",
                    "onPrimary": "#102030",
                    "secondary": "#FEDCBA",
                    "onSecondary": "#203040",
                },
            },
        }
        self.manifest_path = self.root / "manifest.json"
        self.manifest_path.write_text(json.dumps(self.manifest))

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def run_manager(self, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "python3",
                str(MANAGER),
                str(self.manifest_path),
                "--root",
                str(self.root),
                *arguments,
            ],
            check=check,
            capture_output=True,
            text=True,
        )

    def snapshot(self) -> str:
        digest = hashlib.sha256()
        for path in sorted(path for path in self.root.rglob("*") if path.is_file()):
            digest.update(str(path.relative_to(self.root)).encode())
            digest.update(path.read_bytes())
        return digest.hexdigest()

    def complete_registration(self) -> None:
        self.run_manager("--apply", "--skip-generators", "--skip-xcode")
        assets = self.root / "images/sample"
        assets.mkdir(parents=True)
        for name in (
            "appstore.png",
            "playstore.png",
            "brand_logo.png",
            "icon.png",
            "ic_launcher_background.png",
            "ic_launcher_foreground.png",
            "splash.png",
        ):
            (assets / name).write_bytes(b"png")
        android_firebase = self.root / "android/app/src/sample/google-services.json"
        android_firebase.parent.mkdir(parents=True)
        android_firebase.write_text("com.barolit.sample")
        ios_firebase = self.root / "ios/fbconfig/sample/GoogleService-Info.plist"
        ios_firebase.parent.mkdir(parents=True)
        ios_firebase.write_text("com.barolit.sample")
        dart_firebase = self.root / "lib/apps/sample/firebase_options_sample.dart"
        dart_firebase.write_text("com.barolit.sample")
        project = self.root / "ios/Runner.xcodeproj"
        (project / "xcshareddata/xcschemes").mkdir(parents=True)
        (project / "xcshareddata/xcschemes/sample.xcscheme").write_text("sample")
        (project / "project.pbxproj").write_text(
            'name = "Debug-sample"; name = "Profile-sample"; '
            'name = "Release-sample"; com.barolit.sample; '
            "group.com.barolit.sample; sample; com.barolit.sample.widget;"
        )

    def test_dry_run_never_writes(self) -> None:
        before = self.snapshot()
        result = self.run_manager()
        report = json.loads(result.stdout)
        self.assertEqual(report["mode"], "plan")
        self.assertEqual(before, self.snapshot())

    def test_apply_scaffolds_and_preserves_other_brands(self) -> None:
        before_existing = json.loads((self.root / "tools/android_releases.json").read_text())["existing"]
        self.run_manager("--apply", "--skip-generators", "--skip-xcode")

        self.assertTrue((self.root / "whitelabel/sample.json").is_file())
        self.assertTrue((self.root / "lib/apps/sample/main_sample.dart").is_file())
        self.assertIn('create("sample")', (self.root / "android/app/build.gradle.kts").read_text())
        releases = json.loads((self.root / "tools/android_releases.json").read_text())
        self.assertEqual(releases["existing"], before_existing)
        self.assertEqual(releases["sample"]["applicationId"], "com.barolit.sample")

    def test_partial_apply_recovers_missing_file(self) -> None:
        self.run_manager("--apply", "--skip-generators", "--skip-xcode")
        missing = self.root / "lib/apps/sample/main_sample.dart"
        missing.unlink()
        self.run_manager("--apply", "--skip-generators", "--skip-xcode")
        self.assertTrue(missing.is_file())

    def test_complete_duplicate_is_rejected(self) -> None:
        self.complete_registration()

        result = self.run_manager(
            "--apply", "--skip-generators", "--skip-xcode", check=False
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("already complete", result.stderr)

    def test_validate_rejects_conflicting_scaffold_file(self) -> None:
        self.complete_registration()
        entrypoint = self.root / "lib/apps/sample/main_sample.dart"
        entrypoint.write_text(entrypoint.read_text() + "// unexpected\n")

        result = self.run_manager("--validate", check=False)

        self.assertEqual(result.returncode, 1)
        report = json.loads(result.stdout)
        relative_entrypoint = str(entrypoint.relative_to(self.root))
        self.assertEqual(report["files"][relative_entrypoint], "conflict")

    def test_identity_collision_is_rejected(self) -> None:
        (self.root / "whitelabel/existing.json").write_text(
            json.dumps({"bundleId": "com.barolit.sample"})
        )
        result = self.run_manager(
            "--apply", "--skip-generators", "--skip-xcode", check=False
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("Identity collision", result.stderr)

    def test_ios_routine_is_idempotent(self) -> None:
        ios_root = self.root / "ios"
        shutil.copytree(REPO / "ios/Runner.xcodeproj", ios_root / "Runner.xcodeproj")
        storyboard = ios_root / "Runner/Base.lproj/LaunchScreenSample.storyboard"
        storyboard.parent.mkdir(parents=True)
        storyboard.write_text("storyboard")
        for _ in range(2):
            subprocess.run(
                [
                    "/usr/bin/ruby",
                    str(IOS_ROUTINE),
                    "--root",
                    str(self.root),
                    "--manifest",
                    str(self.manifest_path),
                    "--apply",
                ],
                check=True,
                capture_output=True,
                text=True,
            )
        project = (ios_root / "Runner.xcodeproj/project.pbxproj").read_text()
        for kind in ("Debug", "Profile", "Release"):
            self.assertEqual(project.count(f'name = "{kind}-sample";'), 3)
        self.assertEqual(project.count("LaunchScreenSample.storyboard in Resources"), 2)


if __name__ == "__main__":
    unittest.main()
