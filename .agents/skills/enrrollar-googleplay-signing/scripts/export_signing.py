#!/usr/bin/env python3
"""Prepare local Play signing artifacts without enrolling, building, or editing the registry."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
from android_release import ReleaseError, read_profile, signing_fingerprint

BC_SHA256 = '0d81ecc3124536b539bce9aa3fe9621b7f84c9cee371b635a5b31c78b79ab1da'
MAIN = 'com.google.wireless.android.vending.developer.signing.tools.extern.export.ExportEncryptedPrivateKeyTool'
PROBE = '''import java.security.Security;
import javax.crypto.Cipher;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
class ProviderProbe {
  public static void main(String[] args) throws Exception {
    Security.addProvider(new BouncyCastleProvider());
    var provider = Cipher.getInstance("RSA/NONE/OAEPWithSHA1AndMGF1Padding").getProvider();
    if (!provider.getName().equals("BC")) throw new IllegalStateException("Unexpected provider");
    System.out.println(provider.getClass().getProtectionDomain().getCodeSource().getLocation());
  }
}
'''


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def normalize_sha(value):
    value = value.replace(':', '').upper()
    if len(value) != 64 or any(c not in '0123456789ABCDEF' for c in value):
        raise ReleaseError('Huella SHA-256 inválida.')
    return value


def capture(command, env=None):
    result = subprocess.run(command, env=env, capture_output=True)
    if result.returncode:
        raise ReleaseError(f'Falló {Path(command[0]).name}; revisa sus requisitos locales.')
    return result.stdout


def probe_provider(java, bc, pepk):
    # Signed BC first: PEPK also bundles repackaged classes with the same names.
    classpath = os.pathsep.join((str(bc), str(pepk)))
    with tempfile.TemporaryDirectory(prefix='icourier-pepk-probe-') as d:
        source = Path(d) / 'ProviderProbe.java'
        source.write_text(PROBE)
        result = capture([java, '-cp', classpath, str(source)]).decode().strip()
    location = urlparse(result)
    if (location.scheme != 'file' or location.netloc not in ('', 'localhost')
            or Path(unquote(location.path)).resolve() != bc):
        raise ReleaseError('BC no se cargó desde el JAR firmado esperado.')
    return classpath


def export_certificate(env, destination, expected):
    capture(['keytool', '-exportcert', '-rfc', '-keystore', env['ANDROID_KEYSTORE_PATH'],
             '-alias', env['ANDROID_KEY_ALIAS'], '-storepass:env', 'ANDROID_KEYSTORE_PASSWORD',
             '-file', str(destination)], env)
    der = capture(['openssl', 'x509', '-in', str(destination), '-outform', 'DER'])
    if hashlib.sha256(der).hexdigest().upper() != expected:
        raise ReleaseError('El certificado exportado difiere del perfil validado.')


def run_pepk(java, classpath, env, encryption_key, output):
    try:
        import pexpect
    except ImportError:
        raise ReleaseError('Falta pexpect en este Python; instala esa dependencia antes de exportar.') from None
    args = ['-cp', classpath, MAIN, '--keystore=' + env['ANDROID_KEYSTORE_PATH'],
            '--alias=' + env['ANDROID_KEY_ALIAS'], '--output=' + str(output),
            '--rsa-aes-encryption', '--encryption-key-path=' + str(encryption_key)]
    child = pexpect.spawn(java, args, encoding='utf-8', timeout=30, echo=False)
    child.logfile = None
    transcript = ''
    try:
        for _ in range(4):
            event = child.expect([r'(?i)Enter password for store[^\r\n]*:',
                                  r'(?i)Enter password for key[^\r\n]*:', pexpect.EOF])
            transcript += child.before
            if event == 2:
                break
            key = 'ANDROID_KEYSTORE_PASSWORD' if event == 0 else 'ANDROID_KEY_PASSWORD'
            child.sendline(env[key])
        else:
            raise ReleaseError('PEPK repitió prompts; revisa el perfil privado.')
    except pexpect.ExceptionPexpect:
        raise ReleaseError('PEPK no completó los prompts; revisa Java y el perfil privado.') from None
    finally:
        child.close(force=True)
    if child.exitstatus != 0 or not output.is_file() or not output.stat().st_size:
        for key in ('ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_PASSWORD'):
            transcript = transcript.replace(env[key], '<REDACTED>')
        raise ReleaseError('PEPK falló; salida saneada:\n' + transcript[-2000:])
    output.chmod(0o600)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('courier')
    parser.add_argument('--app-signing-profile', required=True, choices=('legacy', 'recent', 'release'))
    parser.add_argument('--upload-profile', required=True, choices=('legacy', 'recent', 'release'))
    parser.add_argument('--app-signing-env', help='Perfil privado alternativo, sin copiarlo al repositorio.')
    parser.add_argument('--upload-signing-env', help='Perfil privado alternativo, sin copiarlo al repositorio.')
    parser.add_argument('--expected-app-sha256', required=True, help='Huella confirmada en APK/Play.')
    parser.add_argument('--encryption-key', required=True)
    parser.add_argument('--pepk-jar', required=True)
    parser.add_argument('--bcprov-jar', required=True)
    parser.add_argument('--bcprov-sha256', default=BC_SHA256,
                        help='Fija BC 1.79 por defecto; verifica el digest oficial si cambias de JAR.')
    parser.add_argument('--java', help='Ejecutable Java 17+ para PEPK y el probe.')
    parser.add_argument('--output-dir', help='Carpeta nueva/vacía; por defecto crea un intento en build/releases/.')
    parser.add_argument('--check', action='store_true', help='Validar sin exportar claves ni certificados.')
    args = parser.parse_args(argv)
    if not args.courier or any(c not in 'abcdefghijklmnopqrstuvwxyz0123456789' for c in args.courier):
        raise ReleaseError('Usa un slug existente de whitelabel/.')
    brand = json.loads((ROOT / 'whitelabel' / (args.courier + '.json')).read_text())
    envs = []
    for name, alternative in [(args.app_signing_profile, args.app_signing_env),
                              (args.upload_profile, args.upload_signing_env)]:
        path = Path(alternative).expanduser() if alternative else ROOT / 'android/signing' / (name + '.env')
        envs.append(read_profile(path, os.environ))
    app_env, upload_env = envs
    expected = normalize_sha(args.expected_app_sha256)
    if signing_fingerprint(ROOT, app_env) != expected:
        raise ReleaseError('La clave original difiere de la huella confirmada de la app.')
    upload_sha = signing_fingerprint(ROOT, upload_env)
    bc, pepk, encryption = [Path(v).expanduser().resolve() for v in
                            (args.bcprov_jar, args.pepk_jar, args.encryption_key)]
    if not all(p.is_file() for p in (bc, pepk, encryption)):
        raise ReleaseError('Falta PEPK, proveedor BC o PEM público de Play Console.')
    if digest(bc).upper() != normalize_sha(args.bcprov_sha256):
        raise ReleaseError('El JAR BC difiere del SHA-256 verificado.')
    encryption_der = capture(['openssl', 'pkey', '-pubin', '-in', str(encryption), '-outform', 'DER'])
    java = args.java or shutil.which('java')
    if not java:
        raise ReleaseError('Java no está disponible.')
    classpath = probe_provider(java, bc, pepk)
    base = dict(courier=args.courier, applicationId=brand['bundleId'],
                appSigningProfile=args.app_signing_profile, appSigningCertificateSha256=expected,
                uploadProfile=args.upload_profile, uploadCertificateSha256=upload_sha,
                providerProbe='passed: signed BC before PEPK')
    if args.check:
        print(json.dumps(dict(base, status='preflight-validado'), indent=2))
        return 0
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    output = (Path(args.output_dir).expanduser().resolve() if args.output_dir else
              ROOT / 'build/releases' / args.courier / 'play-app-signing' / stamp)
    if output.exists() and any(output.iterdir()):
        raise ReleaseError('La salida contiene archivos; usa otra carpeta para preservar intentos.')
    output.mkdir(parents=True, exist_ok=True, mode=0o700)
    encrypted = output / (args.courier + '-app-signing-encrypted.pepk')
    app_cert, upload_cert = output / 'app-signing-certificate.pem', output / 'upload-certificate.pem'
    run_pepk(java, classpath, app_env, encryption, encrypted)
    export_certificate(app_env, app_cert, expected)
    export_certificate(upload_env, upload_cert, upload_sha)
    summary = dict(base, status='preparado-localmente', playEnrollment='pendiente',
                   createdAt=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   pepkJarSha256=digest(pepk), bcprovJarSha256=digest(bc),
                   encryptionPublicKeyDerSha256=hashlib.sha256(encryption_der).hexdigest(),
                   artifacts={p.name: dict(path=str(p), sha256=digest(p), bytes=p.stat().st_size)
                              for p in (encrypted, app_cert, upload_cert)})
    manifest = output / 'enrollment-artifacts.json'
    manifest.write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps(dict(summary, manifest=str(manifest)), indent=2))
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except ReleaseError as error:
        print('Error: ' + str(error), file=sys.stderr)
        sys.exit(1)
    except (OSError, ValueError, KeyError):
        print('Error: no se pudo leer la configuración o ejecutar una herramienta.', file=sys.stderr)
        sys.exit(1)
