---
name: enrrollar-googleplay-signing
description: Migra couriers existentes de iCourier a Google Play App Signing, identifica la firma original, prepara PEPK compatible con Java y registra una clave de subida separada. Úsala para enrolamiento o fallos PEPK; el alta de apps nuevas corresponde a onboard-courier.
---

# Enrolar Google Play App Signing

Opera desde la raíz de iCourier. Resuelve los slugs contra `whitelabel/` y trata cada app por separado. El objetivo es conservar sus actualizaciones y separar **firma de la app** de **firma de subida**.

## Alcance

«Revisar» o «planificar» termina en un plan, sin exportar claves ni cambiar el portal. «Enrolar» o «migrar» autoriza preparar archivos y completar el enrolamiento solicitado, incluida la clave de subida elegida. Aprovecha la autorización existente y pide solo datos faltantes. Compilar, subir artefactos y publicar releases son acciones distintas; cuando se soliciten builds, continúa con [create-icourier-release](../create-icourier-release/SKILL.md).

## 1. Confirmar identidad y las dos claves

Lee el whitelabel y `tools/android_releases.json`, conserva el diff existente y consulta App signing en Play Console. El `profile` del registro local identifica la **clave de subida**, que puede diferir de la firma que reciben los usuarios.

Para una app que distribuye APK propios, identifica la firma original con el certificado de Play o un APK que el usuario confirme que subió. Ejecuta `apksigner verify --print-certs <apk>` y `aapt2 dump badging <apk>`; compara package y SHA-256 con el courier y los certificados locales. Leer el certificado público con `keytool -exportcert` puede funcionar sin contraseña; firmar/exportar la clave privada requiere validar ambas contraseñas.

Obtén rutas y aliases de `android/signing.example/` y perfiles privados existentes. **No asignes legacy/recent/release por memoria, nombre o antigüedad.** Compartir cuenta Play tampoco prueba compartir clave. Resuelve credenciales faltantes en el perfil privado local y mantenlas fuera del chat, argumentos visibles, logs y archivos versionados.

Elige la clave de subida con el usuario. `release` ya se usa para BMCargo y fixocargo, pero no es una regla para todos los couriers. Si la app ya está enrolada, inspecciona sus certificados antes de preparar otra migración.

**Listo:** package correcto, SHA-256 original confirmado y perfil de subida elegido, con credenciales verificadas. Un APK subido no confirma el último código publicado; conserva `lastPublishedVersionCode=null` mientras ese dato siga pendiente.

## 2. Preparar la exportación cifrada

En Play selecciona **Use existing app signing key from Java KeyStore**. Obtén de esa pantalla el comando, PEPK y `encryption_public_key.pem`. Usa la clave pública de ese proceso, sin reutilizar a ciegas la de otra app. El PEPK corresponde a la **firma original**; el PEM de upload certificate corresponde a la **clave de subida elegida**.

Antes de ejecutar PEPK lee [references/pepk.md](references/pepk.md): contiene el error de Java y el orden del classpath que lo resolvió. Usa [scripts/export_signing.py](scripts/export_signing.py), primero con `--check` y después con las mismas opciones sin ese flag. El helper valida certificados, credenciales y proveedor; entrega PEPK, certificados públicos y JSON en una carpeta nueva. No edita firmas, compila ni llama a Play.

**Listo:** PEPK terminó con código cero, archivos de esta ejecución no vacíos y hashes registrados. Esto confirma preparación local, no aceptación de Google. Corrige la causa de un fallo; no aumentes builds ni cambies claves para resolver errores PEPK.

## 3. Guardar y comprobar en Play

En la app correcta, carga el PEPK en **Upload private key**. En las instrucciones opcionales para una clave separada, carga el PEM de subida en **Upload your upload key certificate**. Guía Save/Enroll cuando las identidades y campos estén correctos. Si operas el navegador, utiliza la autorización existente para la migración solicitada.

Tras guardar, verifica **App signing key — In use** y compara los dos SHA-256. La huella de firma puede estar detrás de un botón de copiar/descargar: registra qué se comprobó realmente. Una captura que muestra la huella de subida permite validar esa clave aunque la de firma quede pendiente; no reportes esta última como comparada.

**Listo:** enrolamiento activo y certificado de subida confirmado contra la clave local. Guarda evidencia sin credenciales y distingue confirmaciones de inferencias. En Maps/OAuth/Firebase, las huellas relevantes son las de firma de los APK distribuidos, incluidas nuevas claves si se eligió una actualización de firma.

## 4. Configurar próximas subidas

Una vez confirmado el certificado de subida, actualiza solo el courier en `tools/android_releases.json`: `profile` y `certificateSha256` describen esa clave. Preserva `applicationId`, otros couriers y el último código publicado confirmado. Ejecuta `bash tools/build_android_bundle.sh --check <slug>`.

Si se pidió generar el release y ya existe un AAB firmado con la clave original, consérvalo con JSON/logs antes de generar otro con la clave de subida. Reutiliza el código solo si sabes que no se subió/ocupó; ante un resultado incierto consulta Play. No reapliques el incremento de versiones de un lote ya preparado. La entrega verificada se genera únicamente con `bash tools/build_android_bundle.sh <slug>`.

Entrega por courier: identidades de firma/subida, evidencia del enrolamiento, rutas/hashes, resultado del preflight y estado del AAB si se solicitó. Distingue preparado, enrolado, generado, subido y publicado. No infieras cuántas apps faltan migrar por el registro local: la lista real requiere consultar Play.

## Ejemplo y registro

`$enrrollar-googleplay-signing fixocargo; APK /ruta/app.apk; usar release como clave de subida`

Lee [references/fixocargo-20261001.md](references/fixocargo-20261001.md) para el caso inicial y los intentos fallidos. Para cambios del portal contrasta [Google: Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en) y [Android: app signing](https://developer.android.com/studio/publish/app-signing).
