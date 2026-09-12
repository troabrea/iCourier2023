# Releases Android por courier

El código de build Android se cambia **solo en `android/release.properties`**.
Todos los flavors usan actualmente `5202702` (corte del 11 de septiembre de 2026). La versión visible sigue en
`pubspec.yaml`; el build de iOS no cambia. No se incrementa ningún código automáticamente.

## Uso diario

Desde la raíz del repositorio (desde otro directorio, usa la ruta absoluta del script):

```bash
bash tools/build_android_bundle.sh --list
bash tools/build_android_bundle.sh --check tupaq
bash tools/build_android_bundle.sh tupaq
```

Sin argumentos muestra ayuda. Cada invocación genera un solo AAB release.
Requiere FVM/Flutter configurado, Python 3.9+ y JDK 17+ (`java` en PATH).
La primera compilación descarga bundletool 1.18.3 desde su release oficial de
Google en GitHub y valida su SHA-256 fijado en el script. Se conserva en
`build/tools/`; las ejecuciones siguientes pueden reutilizarlo sin red.

El script usa el perfil asignado en `tools/android_releases.json`. Limpia las
cuatro variables de firma heredadas antes de leerlo; no utiliza automáticamente
`~/.config/icourier/android-signing.env`. Ese archivo histórico se conserva,
pero la configuración activa vive en `android/signing/`.

`--check` valida ruta, alias, ambas contraseñas y certificado, además del código
común y la asignación. No compila ni consulta Google Play. Un perfil pendiente,
una huella distinta o credenciales incompletas detienen la operación.

El build se entrega únicamente tras comprobar criptográficamente todas sus
entradas, el certificado firmante y el paquete/código extraídos del manifiesto
**del AAB**, mediante bundletool. Destinos:

```text
build/releases/tupaq/5202702/tupaq-5202702.aab
build/releases/tupaq/5202702/tupaq-5202702.json
```

El JSON contiene paquete, versión, perfil, huella del certificado y SHA-256 del
AAB; nunca contiene contraseñas. Un rebuild del mismo courier/código reemplaza
esa entrega después de verificarlo. Si falla, no se entrega un archivo nuevo;
un artefacto de una ejecución anterior podría seguir en `build/releases/`.
Solo usa el archivo anunciado al finalizar una ejecución exitosa.

## Perfiles locales y plantillas

`android/signing/` está completamente ignorado por Git. Las plantillas de
`android/signing.example/` sí están versionadas e incluyen las rutas históricas
y aliases; las contraseñas están vacías. Los archivos `.keystore` y `.jks`
siguen ignorados y deben permanecer fuera del repositorio.

Para preparar una máquina nueva (no sobrescribas perfiles ya completados):

```bash
mkdir -p android/signing
chmod 700 android/signing
cp -n android/signing.example/*.env android/signing/
chmod 600 android/signing/*.env
```

Edita los cuatro valores del perfil correspondiente localmente. El formato
admite `export NOMBRE='valor'` o `NOMBRE='valor'`, una asignación por línea.
Los valores son literales: no se ejecuta código shell, no se expanden `$HOME`,
`~`, `$VARIABLE` ni `$(comando)`. Usa rutas absolutas. Para una contraseña con
comilla simple puedes concatenar segmentos al estilo shell: `'parte'"'"'resto'`.
No pegues contraseñas en chats, comandos, documentación o archivos versionados.

| Perfil | Keystore histórico | Alias |
|---|---|---|
| `legacy` | `android.keystore` | `android` |
| `recent` | `AndroidKey.keystore` | `androidkey` |
| `release` | `upload-keystore.jks` | `upload` |

Estos nombres identifican claves históricas; todos generan el mismo build type
Android `release`. No hay que editar Gradle para cambiar de courier.

## Incorporar un courier pendiente

1. En Play Console, consulta el **certificado de subida** de la app correspondiente.
   Copia su huella SHA-256. No lo confundas con el certificado de firma de la app:
   Play App Signing puede usar una clave distinta para los APK instalados.
2. Compara con los certificados de los tres keystores locales. Puedes utilizar
   `keytool -list -v -keystore /ruta/al/archivo -alias alias`; ingresa la contraseña
   cuando la solicite, nunca como argumento visible.
3. En `tools/android_releases.json`, asigna `profile` a `legacy`, `recent` o
   `release`, y coloca la huella confirmada en `certificateSha256`. Se admiten
   hexadecimales con o sin `:`. Conserva el `applicationId` del courier.
4. Registra `lastPublishedVersionCode` solo si verificaste el código publicado
   en Play. Deja `null` si no lo conoces. Un build o una subida aceptada no
   confirman una publicación.
5. Ejecuta `--check <courier>` y luego genera su AAB.

TUPAQ está confirmado con `release` por una subida aceptada. Su último código
publicado continúa pendiente. Los demás couriers no tienen firma asignada.
No selecciones una por antigüedad o por el nombre del archivo.

Si no coincide ningún certificado, revisa los registros de subida y los
keystores disponibles antes de asignar una firma. Este flujo no cambia claves
ni solicita resets en Google Play.

## Versiones y publicación

Antes de una nueva publicación, aumenta `versionCode` en
`android/release.properties`. Debe ser un entero entre `1` y `2100000000`.
El script exige que supere el último publicado **confirmado** del courier.
Si ese dato falta, informa que la comparación queda pendiente; no afirma que
Play aceptará el release. `5202700` supera todos los códigos que estaban
configurados en este repositorio, pero no sustituye la comprobación en Play.

El nombre visible de versión no determina el orden de actualización. Un código
común puede usarse en apps distintas; para volver a publicar una misma app
necesitas un código nuevo. Tras confirmar la publicación, actualiza su
`lastPublishedVersionCode` en el registro y versiona ese cambio.

Las tareas release invocadas directamente desde Flutter/Gradle también fallan
si faltan variables de firma. Para validar además la correspondencia con el
courier y generar la entrega verificada, utiliza siempre este script. Debug
y la sincronización del IDE no requieren credenciales de producción.

## Verificación del flujo

```bash
python3 -m unittest discover -s tools -p 'test_android_release.py'
git check-ignore android/signing/release.env
```

Las pruebas crean claves temporales para verificar contraseñas incorrectas,
AAB sin firma, contenido alterado y entradas agregadas sin firmar. También
cubren perfiles pendientes, variables heredadas, comparación de versiones y
paquetes/códigos distintos del solicitado.

Referencias oficiales:
[App signing](https://developer.android.com/studio/publish/app-signing),
[Versioning](https://developer.android.com/studio/publish/versioning),
[bundletool](https://developer.android.com/tools/bundletool).

## Registro de implementación — 2026-09-10

Implementado en el worktree `iCourier-whitelabel-redesign`, rama
`redesign/fidelidad-visual`, sobre HEAD `66062514247c20dce0308492d75ae9305a9dd444`.
Los cambios de este flujo aún estaban sin commit al documentarlos.

Decisiones sustituidas: selección manual de `signingConfig` por comentarios;
una única firma supuestamente compartida por todas las marcas; y códigos Android
heredados de `pubspec.yaml` o fijados por flavor. Se conservaron las tres claves
históricas y se centralizó el código en `5202700`, mayor que el máximo local
anterior `5202605`. No se cambió el build iOS `58`.

Validación realizada durante la implementación, no repetida en esta actualización documental:

- 11 pruebas del flujo aprobadas, con claves temporales y rechazo de archivos
  sin firma, alterados o parcialmente firmados.
- Gradle confirmó `5202700` en 105 variantes; los grafos de tareas (`--dry-run`)
  permitieron debug sin credenciales y rechazaron release sin ellas.
- Comprobados permisos `600`, exclusión Git de perfiles/keystores y ausencia
  de las contraseñas locales en archivos versionados o nuevos no ignorados.
- AAB TUPAQ generado y verificado: `com.barolit.tupaq`, versión `2027.0.2`,
  código `5202700`, perfil `release`, tamaño aproximado 67.5 MB.
- Entrega: `build/releases/tupaq/5202700/tupaq-5202700.aab` y JSON adjunto.
  SHA-256 del AAB: `44219aee374f2cb9072d0e03b710b4864bf12b90f8af029e9a9d87c47638d067`.

El usuario reportó una carga aceptada con la clave correcta en un intento anterior;
posteriormente Play rechazó el rollout por falta de ruta de actualización.
El código `58` fue identificado como probable causa, se generó una entrega
intermedia `2027100` y finalmente se adoptó el código común `5202700`.
No consta carga, procesamiento ni publicación de la entrega final `5202700`.
Mantener `lastPublishedVersionCode=null` hasta confirmarlo en Play.

## Corte de configuración — 2026-09-11

El commit `99531f5` elevó el código común a `5202702` y el build iOS de
BMCargo/TUPAQ a `60` (`pubspec.yaml`: `2027.0.2+60`). El registro anterior
de `5202700` conserva su valor histórico; no acredita generación ni publicación
de `5202702`. Confirmar el código disponible en Play antes de un nuevo release.
