#!/usr/bin/env python3
"""Plan, scaffold, and validate one iCourier whitelabel.

The default mode is read-only. `--apply` writes only missing, deterministic
local scaffolding and refuses conflicting or already-complete registrations.
Firebase app creation remains an explicit skill step because it is remote.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


CORE_ASSETS = (
    "appstore.png",
    "playstore.png",
    "brand_logo.png",
    "icon.png",
    "ic_launcher_background.png",
    "ic_launcher_foreground.png",
    "splash.png",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--skip-generators", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--skip-xcode", action="store_true", help=argparse.SUPPRESS)
    return parser.parse_args()


def load_manifest(path: Path) -> dict[str, Any]:
    manifest = json.loads(path.read_text())
    required = {
        "slug",
        "name",
        "bundleId",
        "appGroup",
        "urlScheme",
        "companyId",
        "firebaseProject",
        "iosTeam",
        "version",
        "build",
        "icon",
        "fonts",
        "palettes",
    }
    missing = sorted(required - manifest.keys())
    if missing:
        raise ValueError(f"Missing manifest keys: {', '.join(missing)}")
    slug = manifest["slug"]
    if not re.fullmatch(r"[a-z][a-z0-9]*", slug):
        raise ValueError(f"Invalid slug: {slug}")
    if manifest["urlScheme"] != slug:
        raise ValueError("urlScheme must equal slug for iCourier flavors")
    if manifest["appGroup"] != f"group.{manifest['bundleId']}":
        raise ValueError("appGroup must be group.<bundleId>")
    if not re.fullmatch(r"[0-9a-fA-F-]{36}", manifest["companyId"]):
        raise ValueError("companyId must be a UUID")
    return manifest


def class_name(manifest: dict[str, Any]) -> str:
    explicit = manifest.get("className")
    if explicit:
        return str(explicit)
    return "".join(re.findall(r"[A-Za-z0-9]+", manifest["name"]))


def config_document(manifest: dict[str, Any]) -> str:
    payload = {
        "schema": 1,
        "slug": manifest["slug"],
        "name": manifest["name"],
        "tagline": manifest.get("tagline", ""),
        "bundleId": manifest["bundleId"],
        "urlScheme": manifest["urlScheme"],
        "appGroup": manifest["appGroup"],
        "locale": manifest.get("locale", "es-DO"),
        "currency": manifest.get("currency", "RD$"),
        "weightUnit": manifest.get("weightUnit", "lb"),
        "fonts": manifest["fonts"],
        "radius": manifest.get("radius", {"sm": 8, "md": 16, "lg": 24}),
        "assets": {
            "logoWide": f"images/{manifest['slug']}/brand_logo.png",
            "logoMark": f"images/{manifest['slug']}/icon.png",
        },
        "palettes": manifest["palettes"],
        "capabilities": manifest.get(
            "capabilities",
            {
                "delivery": True,
                "payments": True,
                "points": True,
                "prealerts": True,
                "widgets": True,
                "notifications": True,
            },
        ),
        "navigation": manifest.get(
            "navigation",
            {"tabs": ["news", "branches", "home", "calculator", "more"]},
        ),
    }
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n"


def appinfo_document(manifest: dict[str, Any]) -> str:
    slug = manifest["slug"]
    cls = class_name(manifest)
    topic = manifest.get("topic", slug.upper())
    currency = manifest.get("currency", "RD$").replace("$", r"\$")
    return f"""import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/{slug}/firebase_options_{slug}.dart';

import '../appinfo.dart';

class {cls}AppInfo extends AppInfo {{
  @override
  FirebaseOptions appFirebaseOptions =
      {cls}DefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = '{currency}';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => 'images/{slug}/brand_logo.png';
  @override
  String get brandLogoImageDark => 'images/{slug}/brand_logo.png';
  @override
  String get centerIconImage => 'images/{slug}/icon.png';

  @override
  String get androidAnalyticsAppId => '{topic}';

  @override
  String get iphoneAnalyticsAppId => '{topic}';

  @override
  String get companyId => '{manifest['companyId']}';

  @override
  String get metricsPrefixKey => '{topic}';

  @override
  String get pushChannelTopic => '{topic}';

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}}
"""


def expected_text_files(root: Path, manifest: dict[str, Any]) -> dict[Path, str]:
    slug = manifest["slug"]
    cls = class_name(manifest)
    background = manifest.get("iconBackground", "#FFFFFF")
    dark_background = manifest["palettes"]["dark"].get("onPrimary", "#101820")
    return {
        root / "whitelabel" / f"{slug}.json": config_document(manifest),
        root / "lib" / "apps" / slug / f"appinfo_{slug}.dart": appinfo_document(manifest),
        root / "lib" / "apps" / slug / f"main_{slug}.dart": (
            "import '../../../main_shared.dart';\n"
            f"import 'appinfo_{slug}.dart';\n\n"
            "void main() {\n"
            f"  final appInfo = {cls}AppInfo();\n"
            "  mainShared(appInfo);\n"
            "}\n"
        ),
        root / f"flutter_launcher_icons-{slug}.yaml": (
            "flutter_icons:\n"
            f"  image_path_android: \"images/{slug}/playstore.png\"\n"
            f"  image_path_ios: \"images/{slug}/appstore.png\"\n"
            "  android: true\n  ios: true\n"
            f"  adaptive_icon_background: \"images/{slug}/ic_launcher_background.png\"\n"
            f"  adaptive_icon_foreground: \"images/{slug}/ic_launcher_foreground.png\"\n"
            "  min_sdk_android: 21\n  remove_alpha_ios: true\n"
            "  web:\n    generate: false\n  windows:\n    generate: false\n"
        ),
        root / f"flutter_native_splash-{slug}.yaml": (
            "flutter_native_splash:\n"
            f"  color: \"{background}\"\n  image: images/{slug}/splash.png\n"
            f"  color_dark: \"{dark_background}\"\n  image_dark: images/{slug}/splash.png\n"
            "  android_12:\n"
            f"    image: images/{slug}/splash.png\n    color: \"{background}\"\n"
            f"    icon_background_color: \"{background}\"\n"
            f"    image_dark: images/{slug}/splash.png\n    color_dark: \"{dark_background}\"\n"
            f"    icon_background_color_dark: \"{dark_background}\"\n"
            "  fullscreen: true\n"
        ),
    }


def text_status(path: Path, expected: str) -> str:
    if not path.exists():
        return "missing"
    return "matching" if path.read_text() == expected else "conflict"


def inventory(root: Path, manifest: dict[str, Any]) -> dict[str, Any]:
    slug = manifest["slug"]
    files = expected_text_files(root, manifest)
    statuses = {str(path.relative_to(root)): text_status(path, text) for path, text in files.items()}
    checks = validation_checks(root, manifest)
    return {
        "slug": slug,
        "mode": "plan",
        "files": statuses,
        "surfaces": checks,
        "collisions": identity_collisions(root, manifest),
        "firebaseProject": manifest["firebaseProject"],
        "remoteAction": "inspect IDs before create; resume existing matching apps",
    }


def identity_collisions(root: Path, manifest: dict[str, Any]) -> list[str]:
    slug = manifest["slug"]
    collisions: list[str] = []
    identity_fields = ("bundleId", "urlScheme", "appGroup")
    for path in (root / "whitelabel").glob("*.json"):
        if path.stem in {slug, "_schema"}:
            continue
        candidate = load_json(path)
        for field in identity_fields:
            if candidate.get(field) == manifest[field]:
                collisions.append(f"{field} is already used by {path.stem}")
    for path in (root / "lib/apps").glob("*/appinfo_*.dart"):
        if path.parent.name != slug and manifest["companyId"] in read(path):
            collisions.append(f"companyId is already used by {path.parent.name}")
    releases = load_json(root / "tools/android_releases.json")
    for existing_slug, release in releases.items():
        if existing_slug != slug and release.get("applicationId") == manifest["bundleId"]:
            collisions.append(f"applicationId is already used by {existing_slug}")
    return sorted(set(collisions))


def validation_checks(root: Path, manifest: dict[str, Any]) -> dict[str, bool]:
    slug = manifest["slug"]
    bundle = manifest["bundleId"]
    gradle = read(root / "android/app/build.gradle.kts")
    pubspec = read(root / "pubspec.yaml")
    xcode = read(root / "ios/Runner.xcodeproj/project.pbxproj")
    releases = load_json(root / "tools/android_releases.json")
    release = releases.get(slug, {}) if isinstance(releases, dict) else {}
    return {
        "json": (root / f"whitelabel/{slug}.json").is_file(),
        "assets": all((root / "images" / slug / asset).is_file() for asset in CORE_ASSETS),
        "entrypoint": (root / f"lib/apps/{slug}/main_{slug}.dart").is_file(),
        "appInfo": manifest["companyId"] in read(root / f"lib/apps/{slug}/appinfo_{slug}.dart"),
        "pubspec": f"- images/{slug}/" in pubspec,
        "androidFlavor": f'create("{slug}")' in gradle and bundle in gradle,
        "androidFirebase": bundle in read(root / f"android/app/src/{slug}/google-services.json"),
        "iosFirebase": bundle in read(root / f"ios/fbconfig/{slug}/GoogleService-Info.plist"),
        "firebaseOptions": bundle in read(root / f"lib/apps/{slug}/firebase_options_{slug}.dart"),
        "xcodeConfigurations": all(f'name = "{kind}-{slug}";' in xcode for kind in ("Debug", "Profile", "Release")),
        "xcodeIdentity": all(value in xcode for value in (bundle, manifest["appGroup"], manifest["urlScheme"])),
        "widget": f"{bundle}.widget" in xcode,
        "scheme": (root / f"ios/Runner.xcodeproj/xcshareddata/xcschemes/{slug}.xcscheme").is_file(),
        "releaseRegistry": release.get("applicationId") == bundle and all(release.get(key) is None for key in ("profile", "certificateSha256", "lastPublishedVersionCode")),
    }


def read(path: Path) -> str:
    return path.read_text() if path.exists() else ""


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def write_missing(files: dict[Path, str]) -> None:
    conflicts = [str(path) for path, expected in files.items() if text_status(path, expected) == "conflict"]
    if conflicts:
        raise RuntimeError("Conflicting files:\n" + "\n".join(conflicts))
    for path, expected in files.items():
        if not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(expected)


def patch_registries(root: Path, manifest: dict[str, Any]) -> None:
    slug = manifest["slug"]
    bundle = manifest["bundleId"]
    pubspec_path = root / "pubspec.yaml"
    pubspec = pubspec_path.read_text()
    asset_line = f"    - images/{slug}/\n"
    if asset_line not in pubspec:
        marker = "#    - images/boxpaq/"
        index = pubspec.find(marker)
        if index < 0:
            raise RuntimeError("Could not locate pubspec asset insertion marker")
        pubspec = pubspec[:index] + asset_line + pubspec[index:]
        pubspec_path.write_text(pubspec)

    gradle_path = root / "android/app/build.gradle.kts"
    gradle = gradle_path.read_text()
    block = f'''        create("{slug}") {{\n            dimension = "app"\n            applicationId = "{bundle}"\n        }}\n'''
    if f'create("{slug}")' not in gradle:
        marker = "    productFlavors.configureEach {"
        index = gradle.find(marker)
        if index < 0:
            raise RuntimeError("Could not locate Android flavor insertion marker")
        closing = gradle.rfind("    }\n\n", 0, index)
        if closing < 0:
            raise RuntimeError("Could not locate productFlavors closing brace")
        gradle = gradle[:closing] + block + gradle[closing:]
        gradle_path.write_text(gradle)

    registry_path = root / "tools/android_releases.json"
    registry = load_json(registry_path)
    expected = {
        "applicationId": bundle,
        "certificateSha256": None,
        "lastPublishedVersionCode": None,
        "profile": None,
    }
    current = registry.get(slug)
    if current is not None and current != expected:
        raise RuntimeError(f"Conflicting Android release entry for {slug}")
    registry[slug] = expected
    registry_path.write_text(json.dumps(dict(sorted(registry.items())), indent=2) + "\n")


def generate_assets(root: Path, manifest: dict[str, Any]) -> None:
    icon = Path(manifest["icon"]).expanduser().resolve()
    if not icon.is_file():
        raise RuntimeError(f"Icon source not found: {icon}")
    convert = shutil.which("magick") or shutil.which("convert")
    if not convert:
        raise RuntimeError("ImageMagick is required")
    slug = manifest["slug"]
    destination = root / "images" / slug
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(icon, destination / "appstore.png")
    background = manifest.get("iconBackground", "#FFFFFF")
    transparent = destination / ".transparent.png"
    commands = [
        [convert, str(icon), "-resize", "512x512", str(destination / "playstore.png")],
        [convert, str(icon), "-alpha", "on", "-fuzz", "5%", "-fill", "none", "-draw", "alpha 0,0 floodfill", str(transparent)],
        [convert, str(transparent), "-trim", "+repage", "-resize", "500x500>", "-gravity", "center", "-background", "none", "-extent", "512x512", str(destination / "brand_logo.png")],
        [convert, str(transparent), "-trim", "+repage", "-resize", "150x150>", "-gravity", "center", "-background", "none", "-extent", "167x167", str(destination / "icon.png")],
        [convert, "-size", "512x512", f"xc:{background}", str(destination / "ic_launcher_background.png")],
        [convert, str(transparent), "-trim", "+repage", "-resize", "330x330>", "-gravity", "center", "-background", "none", "-extent", "512x512", str(destination / "ic_launcher_foreground.png")],
        [convert, str(transparent), "-trim", "+repage", "-resize", "600x600>", "-gravity", "center", "-background", "none", "-extent", "1152x1152", str(destination / "splash.png")],
    ]
    for command in commands:
        subprocess.run(command, cwd=root, check=True, stdout=subprocess.DEVNULL)
    transparent.unlink()


def run_generators(root: Path, manifest_path: Path, manifest: dict[str, Any], skip_xcode: bool) -> None:
    slug = manifest["slug"]
    ios_script = Path(__file__).with_name("configure_ios_flavor.rb")
    ios_manifest = dict(manifest)
    ios_manifest_path = root / ".dart_tool" / f"{slug}_ios_manifest.json"
    ios_manifest_path.parent.mkdir(parents=True, exist_ok=True)
    ios_manifest_path.write_text(json.dumps(ios_manifest))
    if not skip_xcode:
        subprocess.run(["/usr/bin/ruby", str(ios_script), "--root", str(root), "--manifest", str(ios_manifest_path), "--apply"], check=True)
    subprocess.run(["dart", "run", "flutter_launcher_icons", "-f", f"flutter_launcher_icons-{slug}.yaml"], cwd=root, check=True)
    subprocess.run(["dart", "run", "flutter_native_splash:create", "--flavor", slug], cwd=root, check=True)
    if not skip_xcode:
        subprocess.run(["/usr/bin/ruby", str(ios_script), "--root", str(root), "--manifest", str(ios_manifest_path), "--apply"], check=True)


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    manifest = load_manifest(args.manifest.resolve())
    report = inventory(root, manifest)
    if args.validate:
        print(json.dumps(report, indent=2))
        files_match = all(status == "matching" for status in report["files"].values())
        surfaces_match = all(report["surfaces"].values())
        return 0 if files_match and surfaces_match and not report["collisions"] else 1
    if not args.apply:
        print(json.dumps(report, indent=2))
        return 0

    core = report["files"]
    if report["collisions"]:
        raise RuntimeError("Identity collision: " + "; ".join(report["collisions"]))
    if core and all(status == "matching" for status in core.values()) and all(report["surfaces"].values()):
        raise RuntimeError(f"Whitelabel {manifest['slug']} is already complete")
    if any(status == "conflict" for status in core.values()):
        raise RuntimeError("Apply refused because one or more scaffold files conflict")

    write_missing(expected_text_files(root, manifest))
    patch_registries(root, manifest)
    if not args.skip_generators:
        generate_assets(root, manifest)
        run_generators(root, args.manifest, manifest, args.skip_xcode)
    print(json.dumps(inventory(root, manifest), indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2)
