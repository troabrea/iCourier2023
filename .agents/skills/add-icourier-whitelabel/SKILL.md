---
name: add-icourier-whitelabel
description: Plan or add an iCourier Android/iOS whitelabel from approved identity, brand, icon, and Firebase inputs. Use only when the user explicitly invokes $add-icourier-whitelabel.
---

# Add iCourier Whitelabel

Use this skill only when explicitly invoked. Keep release builds and store publication in `$create-icourier-release`.

## Choose the mode

- `plan`: inspect only. Do not write files, create Firebase apps, install tools, or change the vault.
- `apply`: scaffold and validate the brand. Remote Firebase creation is allowed only after the user supplied a Firebase project and requested apply.

If the invocation does not name a mode, default to `plan`.

## Required inputs

Collect or confirm: slug, visible name, bundle/application ID, App Group, company UUID, Firebase project, icon source, palette, fonts, locale/currency/weight, navigation, capabilities, iOS team, and version/build policy. Read [manifest.md](references/manifest.md) for the canonical manifest.

Reject ambiguous identifiers. Require `urlScheme == slug` and `appGroup == group.<bundleId>` unless the user explicitly documents an exception.

## Plan

1. Create a temporary manifest; never save it in the repo during plan mode.
2. Run `python3 scripts/manage_whitelabel.py MANIFEST --root REPO`.
3. Report current, missing, conflicting, and remote surfaces: JSON, assets, Dart entrypoint/AppInfo, Gradle, release registry, Firebase files, Xcode configs, scheme, widget, and tests.
4. Include the exact expected diff and identify operations requiring external state.

Do not interpret a partial brand as absent. Report it as resumable when existing identity values match, or as a collision when they differ.

## Apply

1. Confirm the Git worktree and preserve unrelated changes.
2. Run the helper without `--apply` first. Stop on any conflict.
3. Run `python3 scripts/manage_whitelabel.py MANIFEST --root REPO --apply`. The helper is dry-run by default and fills matching partial states without duplicating them.
4. Inspect the generated images. Preserve the submitted 1024 icon as the iOS source. If background removal changes lettering, geometry, or color, reject that edit and use deterministic connected-background removal.
5. Before Firebase creation, use the ARM CLI explicitly (`/opt/homebrew/bin/firebase`) to list apps in the requested project and compare both package IDs. Never infer absence from display names.
6. Reuse matching apps. Create only missing Android/iOS apps. Download directly to:
   - `android/app/src/<slug>/google-services.json`
   - `ios/fbconfig/<slug>/GoogleService-Info.plist`
   - `lib/apps/<slug>/firebase_options_<slug>.dart`
7. Do not replace a generic Firebase config or silently rewrite `firebase.json`.
8. Run the Xcode routine again after splash generation so the localized storyboard is registered:
   `/usr/bin/ruby scripts/configure_ios_flavor.rb --root REPO --manifest MANIFEST --apply`
9. Run `python3 scripts/manage_whitelabel.py MANIFEST --root REPO --validate`.

## Validation

Run, in order:

1. `python3 /Users/temis/.codex/skills/.system/skill-creator/scripts/quick_validate.py SKILL_DIR`
2. `python3 -m unittest scripts/test_manage_whitelabel.py`
3. Brand configuration and presentation tests.
4. `flutter test` and `flutter analyze`.
5. Android Debug build with `--flavor <slug>` and its matching Dart entrypoint.
6. iOS Simulator build with the shared scheme/flavor.
7. Inspect Xcode settings for the app and widget, then launch both simulators and inspect splash, icon, login, light/dark theme, fonts, public tabs, and Firebase startup.

Reproduce any pre-existing golden failure against the baseline. Do not accept new regressions.

## Completion boundaries

- Do not increment shared versions unless explicitly requested.
- Do not create Apple production App IDs/profiles, signed IPA/AAB files, store listings, or releases.
- Do not claim authenticated, physical push, or store QA.
- Update the project vault only after validation evidence is known. Mark the task done only when the stated acceptance checks pass.
- Never commit or push automatically.
