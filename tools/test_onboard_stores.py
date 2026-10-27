import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import onboard_stores as onboarding


class OnboardingTests(unittest.TestCase):
    def setUp(self):
        self.args = onboarding.parser().parse_args([
            "dopack", "--apple-id", "owner@example.com",
            "--apple-team-id", "78D5P35NL6", "--asc-team-id", "123456789",
        ])
        self.brand, _ = onboarding.load_brand(onboarding.ROOT, "dopack")
        self.ios = {"teamId": "78D5P35NL6", "version": "2027.0.2", "build": "65",
                    "widgetBundleId": "com.barolit.dopack.widget", "pushNotifications": True}
        with patch.object(onboarding, "read_ios", return_value=self.ios):
            self.plan = onboarding.make_plan(onboarding.ROOT, self.args)

    def test_plan_never_invokes_fastlane(self):
        with patch.object(onboarding, "read_ios", return_value=self.ios), \
                patch.object(onboarding, "create_apple") as create, \
                contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(onboarding.main(["dopack", "--json"]), 0)
        create.assert_not_called()
        self.assertEqual(json.loads(output.getvalue())["bundleId"], "com.barolit.dopack")

    def test_rejects_path_traversal_and_android_identity_conflict(self):
        with self.assertRaises(ValueError):
            onboarding.load_brand(onboarding.ROOT, "../dopack")
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "whitelabel").mkdir()
            (root / "tools").mkdir()
            (root / "whitelabel/dopack.json").write_text(json.dumps(self.brand))
            (root / "tools/android_releases.json").write_text(json.dumps({
                "dopack": {"applicationId": "com.other.app"},
            }))
            with self.assertRaisesRegex(ValueError, "Android"):
                onboarding.load_brand(root, "dopack")

    def test_does_not_create_a_separate_store_record_for_widget(self):
        steps = {step["step"]: step["arguments"] for step in self.plan["appleSteps"]}
        self.assertNotIn("--skip_itc", steps["app"])
        self.assertEqual(steps["widget"][-2:], ["--skip_itc", "true"])
        self.assertIn("--push-notification", steps["app-services"])
        self.assertNotIn("--push-notification", steps["widget-services"])

    def test_requires_explicit_matching_accounts_before_any_mutation(self):
        for changes in ({"apple_id": None}, {"apple_team_id": "OTHERTEAM1"},
                        {"asc_team_id": "78D5P35NL6"}):
            args = onboarding.parser().parse_args([
                "dopack", "--apple-id", "owner@example.com", "--apple-team-id", "78D5P35NL6",
                "--asc-team-id", "123456789",
            ])
            for key, value in changes.items():
                setattr(args, key, value)
            with patch.object(onboarding.subprocess, "run") as run, \
                    self.assertRaises(ValueError):
                onboarding.create_apple(onboarding.ROOT, args, self.plan)
            run.assert_not_called()

    def test_failure_stops_sequence_and_records_only_completed_attempts(self):
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(onboarding.shutil, "which", return_value="/bin/fastlane"), \
                patch.object(onboarding.subprocess, "run") as run, \
                contextlib.redirect_stdout(io.StringIO()):
            run.return_value.returncode = 1
            with self.assertRaisesRegex(ValueError, "Fastlane falló"):
                onboarding.create_apple(Path(folder), self.args, self.plan)
            self.assertEqual(run.call_count, 1)
            receipt = json.loads(next(Path(folder).rglob("apple.json")).read_text())
        self.assertEqual(receipt["status"], "interrumpido-o-fallido")
        self.assertEqual(receipt["steps"], [{"step": "app", "status": "fallido", "exitCode": 1}])
        self.assertNotIn("owner@example.com", json.dumps(receipt))

    def test_uses_selected_account_and_ignores_previous_produce_environment(self):
        with tempfile.TemporaryDirectory() as folder, \
                patch.dict(onboarding.os.environ, {"PRODUCE_SKIP_ITC": "true"}), \
                patch.object(onboarding.shutil, "which", return_value="/bin/fastlane"), \
                patch.object(onboarding.subprocess, "run") as run, \
                contextlib.redirect_stdout(io.StringIO()):
            run.return_value.returncode = 0
            onboarding.create_apple(Path(folder), self.args, self.plan)
            self.assertEqual(run.call_count, 7)
            for call in run.call_args_list:
                command = call.args[0]
                self.assertEqual(command[-6:], ["--username", "owner@example.com", "--team_id",
                                               "78D5P35NL6", "--itc_team_id", "123456789"])
                self.assertNotIn("PRODUCE_SKIP_ITC", call.kwargs["env"])
            receipt = json.loads(next(Path(folder).rglob("apple.json")).read_text())
        self.assertEqual(receipt["status"], "comandos-aceptados-pendiente-verificacion-remota")

    def test_checks_target_settings_instead_of_unrelated_project_configs(self):
        main = {"PRODUCT_BUNDLE_IDENTIFIER": self.brand["bundleId"],
                "APP_GROUP_ID": self.brand["appGroup"], "DEVELOPMENT_TEAM": "78D5P35NL6",
                "MARKETING_VERSION": "2027.0.2", "CURRENT_PROJECT_VERSION": "65"}
        widget = dict(main, PRODUCT_BUNDLE_IDENTIFIER=self.brand["bundleId"] + ".widget")
        objects = {
            "a": {"isa": "PBXNativeTarget", "name": "Runner", "buildConfigurationList": "al"},
            "b": {"isa": "PBXNativeTarget", "name": "ICourierWidget", "buildConfigurationList": "bl"},
            "al": {"buildConfigurations": ["ac"]}, "bl": {"buildConfigurations": ["bc"]},
            "ac": {"name": "Release-dopack", "buildSettings": main},
            "bc": {"name": "Release-dopack", "buildSettings": widget},
        }
        with patch.object(onboarding.shutil, "which", return_value="/usr/bin/plutil"), \
                patch.object(onboarding.subprocess, "check_output", side_effect=lambda *a, **k:
                             json.dumps({"objects": objects}).encode()):
            self.assertEqual(onboarding.read_ios(onboarding.ROOT, self.brand)["teamId"], "78D5P35NL6")
            widget["DEVELOPMENT_TEAM"] = "OTHERTEAM1"
            with self.assertRaisesRegex(ValueError, "DEVELOPMENT_TEAM"):
                onboarding.read_ios(onboarding.ROOT, self.brand)


if __name__ == "__main__":
    unittest.main()
