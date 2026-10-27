# Migración de fixocargo — 01-10-2026

Registro del proceso real, no una configuración que deban heredar todas las marcas.

## Identificación

El usuario recordaba posiblemente `recent`. Su APK subido, `/Users/temis/Downloads/5203501.apk`, permitió verificar criptográficamente:

- Package `com.barolit.fixocargo`, versión `2025.1.0`, código `5203501`.
- Firma original SHA-256 `EAADC9D0E9235DF74401BF5278B98637506DD2C1C6BBD79B3E948A49A2FB387D`.
- Coincidencia exacta con `android.keystore`, alias `android`, perfil `legacy`.
- `recent`, alias `androidkey`, tenía otra huella (`35D941C4FBBBFED10124468595157E109A92DB537BABBBDE27B6796104367F0D`).

El primer AAB local `2027.0.3 (7202713)` se generó con `legacy`. Su SHA-256 fue `9d5b1cee2a98764554ea6617abd9ccb57bdcfcdc6994bfe9c92813499e57ab09`. Posteriormente el usuario eligió el mismo esquema usado en BMCargo: conservar la clave original en Google y registrar `release` para subir AAB.

## PEPK

En Play se seleccionó **Use existing app signing key from Java KeyStore**. El usuario descargó `/Users/temis/Downloads/encryption_public_key.pem` de esa pantalla. Los parámetros originales fueron `--rsa-aes-encryption --encryption-key-path=<pem>`, con la clave `legacy`.

`java -jar pepk.jar` falló con `RSA/NONE/OAEPWithSHA1AndMGF1Padding`. Un primer reintento con el proveedor firmado **después** de PEPK y configuración adicional de Java falló igual. La solución fue ejecutar el main de PEPK con el JAR firmado BC **primero** en el classpath, validado por SHA-256. Consulta [pepk.md](pepk.md) para los comandos reutilizables.

El resultado cifrado fue de 1616 bytes, SHA-256 `259ee269549335245ff94d9225191a4d14e6042b757439064ba9294812433a62`. PEPK terminó con código cero. Se preparó además el certificado público `release-upload-certificate.pem`, alias `upload`, procedente de `upload-keystore.jks`.

## Portal y próxima subida

El usuario cargó el PEPK en **Upload private key**, el certificado de `release` en **Upload your upload key certificate** y pulsó Save. La captura posterior mostró:

- **App signing key — In use**, base instalada 100%.
- Upload SHA-256 `5F3177B6E5FFA8193FC7C09DC19E49AED6983D420E4EAA59C6335FA059972BCC`, coincidente con `release`.

La huella original de firma no aparecía desplegada en esa captura: se documentó la clave importada y el estado activo, sin afirmar haber comparado esa huella remota. El certificado de subida sí se comparó directamente.

Se actualizó solo fixocargo en `tools/android_releases.json` a `profile=release` y su certificado de subida. Se conservó el AAB `legacy` bajo `build/releases/fixocargo/7202713/previous-legacy-20261001/`. Se regeneró con el mismo código aún no subido, sin reaplicar el incremento de versiones:

- Nuevo AAB `2027.0.3 (7202713)`, perfil `release`.
- SHA-256 `2ec3bd9f74e3a6de1be7e2359df7fab92b5aba57dced41d1afa8bfaff1b2fd73`.
- Firma, package y versión comprobados por `tools/build_android_bundle.sh`.

No se subió ni publicó un release durante este proceso. `lastPublishedVersionCode` permaneció `null`. El número de whitelabels pendientes de migración no se verificó en Play.

Evidencia local ignorada por Git: `build/releases/fixocargo/play-app-signing/enrollment-artifacts.json`, `build/releases/fixocargo/release-session-20261001/play-enrollment-confirmed.json`, y los JSON/logs de ambas entregas AAB. Este registro contiene datos públicos y decisiones; no guarda contraseñas, material privado de keystore ni contenido de las claves.
