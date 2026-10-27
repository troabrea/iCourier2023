# PEPK: proveedor Java y ejecución local

Lee esta referencia antes de exportar una clave de firma. Requisitos del helper: Python 3.9+, `pexpect`, Java 17+, `keytool`, `openssl`, perfiles privados compatibles con `tools/android_release.py`, JAR PEPK del portal y proveedor BC firmado. `--check` también valida las credenciales, pero no exporta claves/certificados ni escribe en Play.

## Fallo observado y solución comprobada

El 01-10-2026, PEPK para fixocargo terminó con:

```text
java.security.NoSuchAlgorithmException:
Cannot find any provider supporting RSA/NONE/OAEPWithSHA1AndMGF1Padding
```

La primera explicación, «Java local no incluye el algoritmo», era incompleta. El bytecode de PEPK mostró que `main` registra Bouncy Castle, incluido en su propio fat JAR. Añadir un proveedor firmado después de PEPK en el classpath, incluso con `security.provider.14` en una configuración adicional, **no** resolvió el fallo: se cargaban primero las clases empaquetadas de PEPK. Poner el JAR firmado de BC **antes** de PEPK sí funcionó. Las contraseñas/alias se habían validado; no había que cambiar la clave.

Configuración comprobada: Oracle Java 17.0.12, PEPK descargado de Google, BC `bcprov-jdk18on-1.79.jar`. Se verificó el digest del proveedor contra su artefacto oficial publicado en Maven Central:

- BC SHA-256: `0d81ecc3124536b539bce9aa3fe9621b7f84c9cee371b635a5b31c78b79ab1da`.
- PEPK SHA-256 de ese día: `aaccc0774b240aa5304bdad2a49865e92f229ca73209ecb6eaafe75dc858e24e`.
- [BC 1.79 firmado](https://repo.maven.apache.org/maven2/org/bouncycastle/bcprov-jdk18on/1.79/bcprov-jdk18on-1.79.jar) y [SHA-256](https://repo.maven.apache.org/maven2/org/bouncycastle/bcprov-jdk18on/1.79/bcprov-jdk18on-1.79.jar.sha256).

BC 1.79 es una configuración probada, no una exigencia universal. Para otro proveedor/versión, verifica su digest oficial y pásalo con `--bcprov-sha256`. Revisa cambios de PEPK con su `--help` y el comando actual del portal. Mantén estos JARs fuera de Git; pueden vivir bajo `build/tools/` o en la caché local de Gradle.

## Preflight y exportación

Obtén de la app correcta el PEM público de cifrado y PEPK. Descubrir un archivo de otra app por su nombre no demuestra que corresponda al enrolamiento actual. El PEPK de Google también está disponible en `https://www.gstatic.com/play-apps-publisher-rapid/signing-tool/prod/pepk.jar`; usa el enlace del portal como referencia primaria del proceso.

Sustituye courier, perfiles, huella original y rutas por los valores confirmados. Ejemplo del caso fixocargo:

```bash
python3 .agents/skills/enrrollar-googleplay-signing/scripts/export_signing.py fixocargo \
  --app-signing-profile legacy --upload-profile release \
  --expected-app-sha256 EAADC9D0E9235DF74401BF5278B98637506DD2C1C6BBD79B3E948A49A2FB387D \
  --encryption-key /ruta/descargada/encryption_public_key.pem \
  --pepk-jar /ruta/pepk.jar \
  --bcprov-jar /ruta/bcprov-jdk18on-1.79.jar \
  --check
```

Sin `--check` prepara los archivos. `--app-signing-env` y `--upload-signing-env` permiten usar perfiles privados externos existentes sin copiarlos. `--output-dir` admite una carpeta nueva/vacía; por defecto cada exportación crea un intento distinto bajo `build/releases/<courier>/play-app-signing/`.

El helper prueba `Cipher.getInstance(...)` con el mismo classpath de PEPK y confirma la ubicación del proveedor cargado. Luego ejecuta el main original de Google con **BC primero**, sin cambiar el JAR PEPK ni la configuración global de Java. Las contraseñas se envían por una PTY privada con eco/log desactivados; los argumentos contienen solo rutas, alias y opciones públicas. Cualquier error capturado se sanea. El main de PEPK registra BC, por lo que el helper no necesita el archivo `java.security.properties` usado durante el diagnóstico inicial.

Entrega: `<courier>-app-signing-encrypted.pepk`, `app-signing-certificate.pem`, `upload-certificate.pem`, `enrollment-artifacts.json`. El JSON conserva huellas, hashes, tamaños y estado `preparado-localmente`; no acredita aceptación del portal. El PEPK cifra la clave directamente dentro del proceso: no se guarda la clave privada sin cifrar.

## Validación del helper

Ejecuta la prueba con las rutas de los dos JARs:

```bash
python3 .agents/skills/enrrollar-googleplay-signing/scripts/test_export_signing.py \
  --pepk-jar /ruta/pepk.jar --bcprov-jar /ruta/bcprov-jdk18on-1.79.jar
```

La prueba crea un courier, claves/perfiles y PEM de cifrado temporales. Verifica exportación real de PEPK, certificados, rechazo de una firma original equivocada y protección de una salida existente. No lee credenciales de producción, cambia registros reales, compila apps ni opera Play.
