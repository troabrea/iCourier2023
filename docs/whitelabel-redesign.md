# WhiteLabel redesign

Esta implementación mantiene servicios, modelos y BLoCs operativos, y mueve la
identidad visual, las capacidades y la navegación a configuración local.

## Configuración

Cada marca tiene un archivo `whitelabel/<slug>.json`. El contrato documental es
`whitelabel/_schema.json`; el contrato ejecutable, con defaults compatibles, vive
en `BrandConfig` y se valida al cargar con `BrandConfigValidator`.

Los valores heredados se pueden volver a auditar contra el commit de origen con:

```sh
flutter pub run tool/extract_whitelabel.dart
```

La presencia de condiciones de marca y literales visuales en presentación se
controla con:

```sh
flutter pub run tool/audit_presentation.dart
```

Una capacidad visible es la intersección entre el permiso local de la marca y el
módulo informado por `Empresa`. Los cinco tabs se componen con `TabModule`; la
posición central siempre es `home`.

## Navegación y deep links

`AppRouter` es el único árbol de navegación. `AppDeepLinkParser` permite solo las
rutas públicas canónicas, y `PendingDestinationStore` conserva una ruta protegida
hasta que la sesión se autentica. Los Widgets abren únicamente
`<scheme>://paquete/:id`.

## Widgets

`WidgetSnapshotBuilder` genera `WidgetStateV1`. El bridge escribe el mismo JSON en
el App Group de iOS y en SharedPreferences de Android. WidgetKit y Glance nunca
llaman al backend. El snapshot vence a las cuatro horas y el cierre o expiración
de sesión reemplaza inmediatamente el estado por `signedOut`.

## Gates locales

```sh
flutter analyze
flutter test
(cd android && ./gradlew :app:testBmcargoDebugUnitTest)
./tool/build_matrix.sh android pilots
./tool/build_matrix.sh ios pilots
```

La matriz completa, intencionalmente explícita y secuencial, se ejecuta con:

```sh
./tool/build_matrix.sh all all
```

Los builds release Android solo usan firma si CI define
`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` y
`ANDROID_KEY_PASSWORD`. No hay credenciales ni rutas personales en Gradle.

Los builds iOS locales usan `--no-codesign`. TestFlight, closed testing y los
artefactos firmados se ejecutan exclusivamente desde CI o desde una máquina con
los perfiles autorizados.

## Lanzamiento

No existe un flag remoto ni una publicación parcial. BMCargo y Fixo Cargo son el
piloto interno. La publicación de las 35 marcas, el tag de la versión anterior y
la rama de hotfix son gates operativos posteriores a la aprobación de QA. Esta
rama no hace push, no abre PR y no integra cambios en `main` automáticamente.
