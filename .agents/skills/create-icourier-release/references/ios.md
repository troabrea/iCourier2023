# iOS: archive, IPA y TestFlight

## Qué manda en este repositorio

- `ios/Runner/Info.plist` y `ios/ICourierWidget/Info.plist` usan `MARKETING_VERSION` y `CURRENT_PROJECT_VERSION`, definidos por flavor en `ios/Runner.xcodeproj/project.pbxproj`. `--build-number`/`pubspec.yaml` por sí solos no sustituyen estos valores explícitos. App y widget deben tener idéntica versión/build.
- Los schemes compartidos deben archivar con `Release-<courier>`. Se compila el workspace `ios/Runner.xcworkspace`, con Pods y WidgetKit.
- `ios/ExportOptions.plist`: exportación local, `method=app-store-connect`, firma automática. `ios/ExportOptionsUpload.plist`: `destination=upload`, misma distribución. Ambos tienen `manageAppVersionAndBuildNumber=false`: se conserva el build revisado, Xcode no lo incrementa al exportar.
- `tools/build_ios_ipa.sh` es una lista histórica de comandos con TLS activo, no un selector de courier. `tool/build_matrix.sh` usa `--no-codesign` y no produce entregas TestFlight. Usa los comandos explícitos de esta referencia.
- `tool/configure_ios_widget.rb` regenera todas las configuraciones y schemes. No es un paso rutinario de release: el helper del skill edita solo las configuraciones Release seleccionadas.

## Preflight sin compilar

Lee los dos targets con `xcodeproj` y confirma versión/build idénticos, bundle ID y App Group conforme al whitelabel. El widget agrega `.widget` al bundle de la app. Comprueba el Team ID de los targets y de los plists de exportación; no supongas que un nuevo courier comparte equipo. Ante diferencias, resuelve el equipo y opciones de exportación adecuados antes de compilar.

```bash
xcodebuild -version
fvm flutter --version
/usr/bin/ruby -rxcodeproj -e 'puts Xcodeproj::VERSION'
xcodebuild -project ios/Runner.xcodeproj -scheme tupaq \
  -configuration Release-tupaq -sdk iphoneos -showBuildSettings -json
```

Del último comando extrae solo identidad, versión, firma y App Group; no publiques el volcado completo de entorno. Revisa cuenta de Xcode, identidad de distribución vigente y perfiles para app y widget con App Groups/Keychain compartido. Una configuración correcta no prueba que el portal aceptará la firma. No cambies certificados, entitlements o equipos para sortear un error de acceso.

## Compilar y verificar

Tras aplicar y revisar el plan, sustituye `courier`, `target`, `version` y `build` por los valores concretos del JSON; pasa argumentos citados. Los flags de Flutter mantienen sus metadatos alineados con Xcode, no reemplazan la edición previa de los targets.

```bash
fvm flutter build ipa --release --flavor "$courier" --target "$target" \
  --build-name "$version" --build-number "$build" \
  --export-options-plist=ios/ExportOptions.plist
```

Revisa salida y artefactos aunque el proceso retorne cero: algunas versiones de Flutter pueden conservar un archive cuando falla la exportación del IPA. Identifica las rutas **de esta ejecución** bajo `build/ios/archive/` y `build/ios/ipa/`; no selecciones por un wildcard que incluya entregas anteriores.

Antes del siguiente flavor, conserva archive, IPA, dSYMs y logs de esta ejecución en `build/releases/<courier>/ios/<version>/<build>/`. Usa rutas exactas y una carpeta de intento nueva si existe una entrega anterior; no reemplaces una entrega subida. Calcula SHA-256 y guarda un JSON con courier, target Dart, bundle ID, versión, build, equipo, hash y hora.

Comprueba en el archive y en el IPA extraído:

- `CFBundleIdentifier`, `CFBundleShortVersionString`, `CFBundleVersion` del `Runner.app` y `PlugIns/ICourierWidget.appex`, contra el plan.
- Firma con `codesign --verify --deep --strict <app>`; revisa por separado el widget y los entitlements con `codesign -d --entitlements :- <ruta>`. Confirma App Group/Keychain esperado y perfil de distribución, no debug.
- Decodifica perfiles con `security cms -D -i <embedded.mobileprovision>` en un archivo temporal privado; comprueba vencimiento, equipo, application identifier y permisos de app/widget. No publiques credenciales ni el contenido completo del perfil.

`codesign` comprueba integridad local, no sustituye la validación de App Store Connect.

## Subida autorizada

Con autenticación de Xcode disponible, reutiliza el **archive ya verificado y preservado**:

```bash
xcodebuild -exportArchive -archivePath "$archive_path" \
  -exportPath "$upload_output" \
  -exportOptionsPlist ios/ExportOptionsUpload.plist \
  -allowProvisioningUpdates
```

Este comando sube a Apple; no pertenece al preflight ni a «solo generar». Si necesita credenciales de App Store Connect, utiliza las ya configuradas en Xcode o una API key existente en almacenamiento seguro. Nunca imprimas el contenido `.p8`, contraseñas ni tokens. Con API key, valida primero los flags de autenticación en `xcodebuild -help`; no inventes un sistema de credenciales.

Conserva el resultado/identificador de subida y verifica en App Store Connect el bundle/version/build esperado. Aceptación de transporte y disponibilidad en TestFlight son estados distintos. Espera el procesamiento cuando sea posible, reporta incidencias de cumplimiento y valida el grupo de testers si fue solicitado. Generar/subir no implica enviar a revisión de App Store ni activar distribución pública o grupos nuevos.

## Evidencia y fuentes

Revisión local del 13-09-2026, **sin generar builds**: Xcode 26.6; FVM fija Flutter 3.38.1. `xcodebuild -showBuildSettings` confirmó para Runner de BMCargo y TuPaq `2027.0.2 (60)`. Lectura de `xcodeproj` confirmó el mismo par en sus widgets Release, equipo `78D5P35NL6`, bundle IDs `com.barolit.bmcargo` / `com.barolit.tupaq` y App Groups correspondientes. Debug/Profile conservaban números antiguos: no usarlos para decidir un release. Releer siempre los valores actuales. No se comprobó firma iOS en un archive nuevo, acceso de subida ni números ocupados en App Store Connect.

Procedimiento contrastado con [Flutter: iOS release](https://docs.flutter.dev/deployment/ios) y [Apple: upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds). Consulta sus requisitos actuales si el entorno cambia.
