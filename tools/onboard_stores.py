#!/usr/bin/env python3
"""Plan store onboarding; optionally create Apple records through fastlane produce."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import plistlib
import re
import shlex
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def load_brand(root, slug):
    if not re.fullmatch(r"[a-z0-9]+(?:[a-z0-9_-]*[a-z0-9])?", slug):
        raise ValueError("Slug inválido; usa el nombre del archivo en whitelabel/.")
    brand = json.loads((root / "whitelabel" / (slug + ".json")).read_text())
    if brand.get("slug") != slug:
        raise ValueError("El slug del whitelabel no coincide con su archivo.")
    for field in ("name", "bundleId", "appGroup"):
        if not isinstance(brand.get(field), str) or not brand[field].strip():
            raise ValueError("Falta el campo " + field)
    if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", brand["bundleId"]):
        raise ValueError("Bundle ID inválido.")
    if not re.fullmatch(r"group\.[A-Za-z0-9.-]+", brand["appGroup"]):
        raise ValueError("App Group inválido.")
    registry = json.loads((root / "tools/android_releases.json").read_text())
    android = registry.get(slug)
    if not android or android.get("applicationId") != brand["bundleId"]:
        raise ValueError("La identidad Android no coincide con el whitelabel.")
    return brand, android


def read_ios(root, brand):
    """Read target-specific Release settings without invoking a build."""
    if not shutil.which("plutil"):
        raise ValueError("Se requiere macOS/plutil para comprobar la identidad Xcode.")
    project = json.loads(subprocess.check_output([
        "plutil", "-convert", "json", "-o", "-",
        str(root / "ios/Runner.xcodeproj/project.pbxproj"),
    ], stderr=subprocess.PIPE))
    objects = project["objects"]
    settings = {}
    for target in objects.values():
        if target.get("isa") != "PBXNativeTarget":
            continue
        if target.get("name") not in ("Runner", "ICourierWidget"):
            continue
        configs = objects[target["buildConfigurationList"]]["buildConfigurations"]
        for config_id in configs:
            config = objects[config_id]
            if config.get("name") == "Release-" + brand["slug"]:
                settings[target["name"]] = config["buildSettings"]
    targets = {"Runner": brand["bundleId"]}
    if "ICourierWidget" in settings or brand.get("capabilities", {}).get("widgets"):
        targets["ICourierWidget"] = brand["bundleId"] + ".widget"
    for target, bundle_id in targets.items():
        config = settings.get(target, {})
        if config.get("PRODUCT_BUNDLE_IDENTIFIER") != bundle_id:
            raise ValueError("Bundle ID Xcode distinto o Release ausente: " + target)
        if config.get("APP_GROUP_ID") != brand["appGroup"]:
            raise ValueError("App Group Xcode distinto: " + target)
        if not config.get("DEVELOPMENT_TEAM"):
            raise ValueError("Falta DEVELOPMENT_TEAM en " + target)
    main = settings["Runner"]
    for target in targets:
        for field in ("DEVELOPMENT_TEAM", "MARKETING_VERSION", "CURRENT_PROJECT_VERSION"):
            if settings[target].get(field) != main.get(field):
                raise ValueError("App y widget difieren en " + field)
    with (root / "ios/Runner/Runner.entitlements").open("rb") as stream:
        entitlements = plistlib.load(stream)
    return {
        "teamId": main["DEVELOPMENT_TEAM"],
        "version": main.get("MARKETING_VERSION"),
        "build": main.get("CURRENT_PROJECT_VERSION"),
        "widgetBundleId": targets.get("ICourierWidget"),
        "pushNotifications": "aps-environment" in entitlements,
    }


def apple_steps(brand, ios, language, sku):
    """Argument arrays keep names/identifiers literal, without a shell."""
    app = brand["bundleId"]
    group = brand["appGroup"]
    steps = [
        ("app", ["create", "--app_identifier", app, "--app_name", brand["name"],
                 "--sku", sku, "--language", language, "--platform", "ios"]),
        ("app-group", ["group", "--group_identifier", group,
                       "--group_name", brand["name"] + " Shared"]),
    ]
    services = ["enable_services", "--app_identifier", app, "--app-group"]
    if ios["pushNotifications"]:
        services.append("--push-notification")
    steps.extend([
        ("app-services", services),
        ("app-group-association", ["associate_group", "--app_identifier", app, group]),
    ])
    if ios["widgetBundleId"]:
        widget = ios["widgetBundleId"]
        steps.extend([
            ("widget", ["create", "--app_identifier", widget,
                        "--app_name", brand["name"] + " Widget", "--skip_itc", "true"]),
            ("widget-services", ["enable_services", "--app_identifier", widget, "--app-group"]),
            ("widget-group-association", ["associate_group", "--app_identifier", widget, group]),
        ])
    return steps


def make_plan(root, args):
    brand, android = load_brand(root, args.courier)
    ios = read_ios(root, brand)
    language = args.apple_language
    if language is None:
        # es-DO is not an App Store primary language; expose the fallback in the plan.
        language = "es-MX" if brand.get("locale", "").startswith("es") else "en-US"
    sku = args.sku or "icourier-" + brand["slug"]
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", sku):
        raise ValueError("SKU inválido; usa letras, números, puntos, guiones o guiones bajos.")
    if not re.fullmatch(r"[a-z]{2}(?:-[A-Z]{2})?", language):
        raise ValueError("Usa un código de idioma App Store, por ejemplo es-MX o es-ES.")
    steps = apple_steps(brand, ios, language, sku)
    return {
        "courier": brand["slug"], "name": brand["name"],
        "bundleId": brand["bundleId"], "appGroup": brand["appGroup"],
        "locale": brand.get("locale"), "applePrimaryLanguage": language, "sku": sku,
        "ios": ios,
        "android": {
            "applicationId": android["applicationId"],
            "signingProfile": android.get("profile"),
            "certificateSha256": android.get("certificateSha256"),
            "firstUpload": "manual-en-play-console",
        },
        "appleSteps": [{"step": name, "arguments": command} for name, command in steps],
        "remoteState": "no-consultado",
    }


def show_plan(plan):
    print("Alta en tiendas: " + plan["name"])
    print("Bundle / package: " + plan["bundleId"])
    print("App Group: " + plan["appGroup"])
    print("Equipo Xcode: " + plan["ios"]["teamId"])
    print("Idioma App Store: " + plan["applePrimaryLanguage"] + " | SKU: " + plan["sku"])
    print("\nOperaciones Apple (requieren Apple ID y posible 2FA):")
    for item in plan["appleSteps"]:
        print("  " + shlex.join(["fastlane", "produce"] + item["arguments"]))
    print("\nGoogle Play — alta inicial en https://play.google.com/console:")
    print("  1. Todas las apps → Crear app. Nombre: " + plan["name"] + "; idioma: español.")
    print("  2. Selecciona app/juego y gratuita/de pago; acepta las declaraciones aplicables.")
    print("  3. Asigna una clave de SUBIDA y su SHA-256 en tools/android_releases.json.")
    if not plan["android"]["signingProfile"] or not plan["android"]["certificateSha256"]:
        print("     PENDIENTE: no hay firma Android completa para este courier.")
    slug = plan["courier"]
    print("  4. Verifica: bash tools/build_android_bundle.sh --check " + slug)
    print("     Genera: bash tools/build_android_bundle.sh " + slug)
    print("  5. Prueba interna → Crear versión. Configura Play App Signing y carga el primer AAB.")
    print("     Su package debe ser " + plan["bundleId"] + ".")
    print("  6. Completa ficha, privacidad, seguridad de datos, acceso y clasificación.")
    print("\nEl alta no incluye certificados/perfiles iOS, APNs/Firebase, builds ni publicación.")
    print("La existencia remota y la disponibilidad del nombre/SKU aún no están comprobadas.")


def create_apple(root, args, plan):
    required = {
        "ICOURIER_APPLE_ID": args.apple_id,
        "ICOURIER_APPLE_TEAM_ID": args.apple_team_id,
        "ICOURIER_ASC_TEAM_ID": args.asc_team_id,
    }
    missing = [key for key, value in required.items() if not value]
    if missing:
        raise ValueError("Faltan datos de cuenta: " + ", ".join(missing))
    if args.apple_team_id != plan["ios"]["teamId"]:
        raise ValueError("El equipo elegido no coincide con Xcode; configura app y widget antes del alta.")
    if not re.fullmatch(r"[A-Z0-9]{10}", args.apple_team_id):
        raise ValueError("Apple Developer Team ID inválido.")
    if not args.asc_team_id.isdigit():
        raise ValueError("App Store Connect Team ID debe ser numérico; no es el Developer Team ID.")
    executable = shutil.which("fastlane")
    if not executable:
        raise ValueError("Fastlane no está instalado. Consulta .agents/skills/onboard-courier/SKILL.md y la guía store-onboarding del vault iCourier2027.")
    # An isolated cwd avoids reading project/user-written Appfiles, Fastfiles or .env files.
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    output = root / "build/store-onboarding" / plan["courier"] / stamp
    output.mkdir(parents=True, mode=0o700)
    receipt = {"courier": plan["courier"], "bundleId": plan["bundleId"],
               "developerTeamId": args.apple_team_id, "ascTeamId": args.asc_team_id,
               "startedAt": stamp, "status": "en-curso", "steps": []}
    receipt_path = output / "apple.json"
    env = os.environ.copy()
    # Identity must come from this invocation, not a previous courier's Produce config.
    for key in list(env):
        if key.startswith("PRODUCE_") or key == "ITC_USERS":
            del env[key]
    env["FASTLANE_SKIP_UPDATE_CHECK"] = "1"
    env["FASTLANE_OPT_OUT_USAGE"] = "1"

    def save():
        receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
        receipt_path.chmod(0o600)

    save()
    try:
        for item in plan["appleSteps"]:
            command = [executable, "produce"] + item["arguments"] + [
                "--username", args.apple_id, "--team_id", args.apple_team_id,
                "--itc_team_id", args.asc_team_id,
            ]
            result = {"step": item["step"], "status": "en-curso"}
            receipt["steps"].append(result)
            save()
            print("\nApple: " + item["step"], flush=True)
            completed = subprocess.run(command, cwd=output, env=env, check=False)
            result["exitCode"] = completed.returncode
            result["status"] = "comando-aceptado" if completed.returncode == 0 else "fallido"
            save()
            if completed.returncode:
                raise ValueError("Fastlane falló en " + item["step"] + "; revisa Apple antes de reanudar.")
        receipt["status"] = "comandos-aceptados-pendiente-verificacion-remota"
    except (OSError, ValueError, KeyboardInterrupt):
        receipt["status"] = "interrumpido-o-fallido"
        raise
    finally:
        save()
        print("Registro local (sin contraseñas): " + str(receipt_path))
    print("Verifica app, widget y asociaciones en Apple; Fastlane no acredita firma ni publicación.")


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("courier", help="Slug en whitelabel/, por ejemplo dopack")
    result.add_argument("--json", action="store_true", help="Plan JSON, sin conexiones ni cambios")
    result.add_argument("--create-apple", action="store_true", help="Ejecuta el alta remota en Apple")
    result.add_argument("--apple-language", help="Idioma App Store; español usa es-MX por defecto")
    result.add_argument("--sku", help="SKU estable; por defecto icourier-<courier>")
    result.add_argument("--apple-id", default=os.environ.get("ICOURIER_APPLE_ID"))
    result.add_argument("--apple-team-id", default=os.environ.get("ICOURIER_APPLE_TEAM_ID"))
    result.add_argument("--asc-team-id", default=os.environ.get("ICOURIER_ASC_TEAM_ID"))
    return result


def main(argv=None):
    args = parser().parse_args(argv)
    try:
        if args.json and args.create_apple:
            raise ValueError("--json solo muestra el plan; no lo combines con --create-apple.")
        plan = make_plan(ROOT, args)
        if args.json:
            print(json.dumps(plan, indent=2, ensure_ascii=False))
        else:
            show_plan(plan)
        if args.create_apple:
            create_apple(ROOT, args, plan)
        return 0
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError) as error:
        print("Error: " + str(error), file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("Interrumpido. Comprueba el estado remoto antes de reanudar.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    sys.exit(main())
