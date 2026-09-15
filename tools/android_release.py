#!/usr/bin/env python3
"""Build one Android courier using a verified local signing profile. Python stdlib only."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
SIGNING_KEYS = (
    'ANDROID_KEYSTORE_PATH', 'ANDROID_KEYSTORE_PASSWORD',
    'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD',
)
BUNDLETOOL_VERSION = '1.18.3'
BUNDLETOOL_SHA256 = 'a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29'
ANDROID_NS = '{http://schemas.android.com/apk/res/android}'


class ReleaseError(Exception):
    pass


def version_code(root):
    text = (root / 'android/release.properties').read_text()
    values = re.findall(r'^versionCode=([0-9]+)\s*$', text, re.M)
    if len(values) != 1 or not 1 <= int(values[0]) <= 2100000000:
        raise ReleaseError('release.properties requiere un versionCode entre 1 y 2100000000.')
    return int(values[0])


def check_version(code, published):
    if published is None:
        return 'Último código publicado sin confirmar: comparación con Play pendiente.'
    if type(published) is not int or not 1 <= published <= 2100000000:
        raise ReleaseError('lastPublishedVersionCode debe ser un entero positivo o null.')
    if code <= published:
        raise ReleaseError(f'El código común {code} debe superar el publicado {published}.')
    return f'Código {code} mayor que el último publicado confirmado ({published}).'


def entrypoint(root, flavor):
    if flavor == 'picknsend':
        matches = [root / 'lib/apps/pns/main_pns.dart']
    else:
        matches = list((root / 'lib/apps').glob(f'*/main_{flavor}.dart'))
    if len(matches) != 1 or not matches[0].is_file():
        raise ReleaseError(f'Entrypoint ausente o ambiguo para {flavor}.')
    return str(matches[0].relative_to(root))


def read_profile(path, inherited):
    """Accept literal shell-style assignments, without executing shell code/expansions."""
    env = {k: v for k, v in inherited.items() if k not in SIGNING_KEYS}
    if not path.is_file():
        raise ReleaseError(f'Falta el perfil local {path}. Copia su plantilla de signing.example.')
    if path.stat().st_mode & 0o077:
        raise ReleaseError(f'El perfil requiere permisos privados: chmod 600 {path}')
    seen = set()
    for number, line in enumerate(path.read_text().splitlines(), 1):
        try:
            parts = shlex.split(line, comments=True, posix=True)
        except ValueError:
            raise ReleaseError(f'Comillas inválidas en el perfil, línea {number}.') from None
        if not parts:
            continue
        if parts[0] == 'export':
            parts = parts[1:]
        if len(parts) != 1 or '=' not in parts[0]:
            raise ReleaseError(f'Asignación inválida en el perfil, línea {number}.')
        key, value = parts[0].split('=', 1)
        if key not in SIGNING_KEYS or key in seen:
            raise ReleaseError(f'Variable desconocida o repetida en el perfil, línea {number}.')
        seen.add(key)
        env[key] = value
    missing = [key for key in SIGNING_KEYS if not env.get(key)]
    if missing:
        raise ReleaseError('Firma incompleta: ' + ', '.join(missing))
    keystore = Path(env['ANDROID_KEYSTORE_PATH'])
    if not keystore.is_absolute() or not keystore.is_file():
        raise ReleaseError('ANDROID_KEYSTORE_PATH debe apuntar a un archivo existente con ruta absoluta.')
    return env


def capture(command, env=None):
    result = subprocess.run(command, env=env, capture_output=True, text=True)
    if result.returncode:
        # Child processes can echo secret input. Only emit an operation-specific message.
        raise ReleaseError(f'Falló {Path(command[0]).name}; revisa sus requisitos y la configuración local.')
    return result.stdout


def signing_fingerprint(root, env, bundle=None):
    command = ['java', str(root / 'tools/AndroidSigning.java')]
    if bundle is not None:
        command.append(str(bundle))
    try:
        fingerprint = capture(command, env).strip()
    except ReleaseError:
        raise ReleaseError(
            'Keystore, alias o contraseñas incorrectos.' if bundle is None else
            'Firma AAB inválida, incompleta o distinta del certificado configurado.'
        ) from None
    if not re.fullmatch('[0-9A-F]{64}', fingerprint):
        raise ReleaseError('No se pudo obtener la huella del certificado.')
    return fingerprint


def require_fingerprint(actual, expected):
    normalized = (expected or '').replace(':', '').upper()
    if not re.fullmatch('[0-9A-F]{64}', normalized):
        raise ReleaseError('Falta una huella SHA-256 confirmada en android_releases.json.')
    if actual != normalized:
        raise ReleaseError('El certificado local no coincide con el registrado para este courier.')


def bundletool(root):
    """Use a pinned official tool, cached outside tracked files, verified before use."""
    cache = root / 'build/tools'
    cache.mkdir(parents=True, exist_ok=True)
    target = cache / f'bundletool-{BUNDLETOOL_VERSION}.jar'
    if not target.exists():
        url = (f'https://github.com/google/bundletool/releases/download/{BUNDLETOOL_VERSION}/'
               f'bundletool-all-{BUNDLETOOL_VERSION}.jar')
        print(f'Descargando bundletool {BUNDLETOOL_VERSION} para verificar el manifiesto...', flush=True)
        temporary = None
        try:
            with urllib.request.urlopen(url, timeout=60) as response, tempfile.NamedTemporaryFile(
                    dir=cache, delete=False) as output:
                temporary = Path(output.name)
                shutil.copyfileobj(response, output)
            if hashlib.sha256(temporary.read_bytes()).hexdigest() != BUNDLETOOL_SHA256:
                raise ReleaseError('La descarga de bundletool no coincide con su SHA-256 fijado.')
            temporary.replace(target)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
    if hashlib.sha256(target.read_bytes()).hexdigest() != BUNDLETOOL_SHA256:
        raise ReleaseError(f'El bundletool local no coincide con su SHA-256 fijado. Elimina {target} y reintenta.')
    return target


def check_manifest(xml, application_id, code):
    try:
        manifest = ET.fromstring(xml)
        actual = (manifest.get('package'), manifest.get(ANDROID_NS + 'versionCode'))
        if actual != (application_id, str(code)):
            raise ReleaseError('El paquete o código del AAB no coincide con el release solicitado.')
        return manifest.get(ANDROID_NS + 'versionName')
    except ET.ParseError:
        raise ReleaseError('No se pudo leer el manifiesto del AAB.') from None


def prepare(root, flavor, inherited, signing_profile=None):
    records = json.loads((root / 'tools/android_releases.json').read_text())
    if not re.fullmatch('[a-z0-9]+', flavor) or flavor not in records:
        raise ReleaseError(f'Courier desconocido: {flavor}. Usa --list.')
    if not (root / f'whitelabel/{flavor}.json').is_file():
        raise ReleaseError(f'No existe whitelabel/{flavor}.json.')
    record = records[flavor]
    profile = record['profile']
    if profile is None:
        raise ReleaseError(f'{flavor}: firma pendiente de verificar y asignar en android_releases.json.')
    if profile not in ('legacy', 'recent', 'release'):
        raise ReleaseError('Perfil desconocido en android_releases.json.')
    target = entrypoint(root, flavor)
    code = version_code(root)
    version_status = check_version(code, record['lastPublishedVersionCode'])
    profile_path = Path(signing_profile) if signing_profile else root / f'android/signing/{profile}.env'
    if signing_profile and not profile_path.is_absolute():
        raise ReleaseError('--signing-profile requiere una ruta absoluta.')
    env = read_profile(profile_path, inherited)
    fingerprint = signing_fingerprint(root, env)
    require_fingerprint(fingerprint, record['certificateSha256'])
    return record, target, code, version_status, env, fingerprint


def main(argv=None, root=ROOT):
    parser = argparse.ArgumentParser(description='Build AAB firmado de un courier; secretos en android/signing/.')
    parser.add_argument('courier', nargs='?')
    parser.add_argument('--signing-profile', help='Leer un perfil privado existente sin copiar secretos al clon.')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--list', action='store_true', help='Listar couriers y perfiles pendientes/confirmados.')
    mode.add_argument('--check', action='store_true', help='Validar firma y versión sin compilar.')
    args = parser.parse_args(argv)
    if args.list:
        if args.courier:
            parser.error('--list no recibe courier')
        records = json.loads((root / 'tools/android_releases.json').read_text())
        for flavor, record in sorted(records.items()):
            print(f"{flavor:16} {record['profile'] or 'PENDIENTE'}")
        return 0
    if not args.courier:
        parser.print_help()
        return 2
    flavor = args.courier.lower()
    record, target, code, status, env, fingerprint = prepare(root, flavor, os.environ, args.signing_profile)
    print(f"Courier: {flavor} | Perfil: {record['profile']} | Código Android: {code}", flush=True)
    print(f'Certificado SHA-256: {fingerprint}\n{status}', flush=True)
    if args.check:
        print('Validación local correcta. No se ha consultado Play Console.')
        return 0
    if shutil.which('fvm') is None:
        raise ReleaseError('FVM no está disponible en PATH.')
    tool = bundletool(root)
    bundle = root / f'build/app/outputs/bundle/{flavor}Release/app-{flavor}-release.aab'
    # Never report a stale bundle after a failed or skipped build.
    bundle.unlink(missing_ok=True)
    # Capture the build log outside the repo and redact configured secrets before display.
    with tempfile.TemporaryFile(mode='w+') as log:
        result = subprocess.run(
            ['fvm', 'flutter', 'build', 'appbundle', '--release', '-t', target, '--flavor', flavor],
            cwd=root, env=env, stdout=log, stderr=subprocess.STDOUT,
        )
        log.seek(0)
        output = log.read()
    for key in ('ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_PASSWORD'):
        output = output.replace(env[key], '<REDACTED>')
    print(output, end='', flush=True)
    if result.returncode:
        raise ReleaseError('Falló el build; no se entregó ningún AAB nuevo.')
    if not bundle.is_file():
        raise ReleaseError('El build no produjo el AAB esperado.')
    require_fingerprint(signing_fingerprint(root, env, bundle), fingerprint)
    xml = capture(['java', '-jar', str(tool), 'dump', 'manifest', f'--bundle={bundle}', '--module=base'])
    name = check_manifest(xml, record['applicationId'], code)
    destination = root / f'build/releases/{flavor}/{code}/{flavor}-{code}.aab'
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(bundle, destination)
    summary = {
        'courier': flavor, 'applicationId': record['applicationId'], 'versionCode': code,
        'versionName': name, 'profile': record['profile'], 'certificateSha256': fingerprint,
        'aabSha256': hashlib.sha256(destination.read_bytes()).hexdigest(),
        'lastPublishedVersionCode': record['lastPublishedVersionCode'],
        'playConsoleVerified': False,
    }
    destination.with_suffix('.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(f'Firma, paquete y versión verificados.\nAAB: {destination}')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ReleaseError, OSError, ValueError, KeyError) as error:
        # Our own errors contain no secrets; generic IO/config errors may quote input.
        message = str(error) if isinstance(error, ReleaseError) else 'No se pudo leer la configuración o ejecutar una herramienta requerida.'
        print(f'Error: {message}', file=sys.stderr)
        sys.exit(1)
