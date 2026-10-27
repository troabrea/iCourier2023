---
name: onboard-courier
description: Prepara el alta de un courier existente de iCourier en App Store Connect y Google Play; ejecuta el registro Apple con Fastlane cuando se solicita y guía el alta inicial manual en Play Console.
---

# Onboard courier

Opera desde la raíz con `whitelabel/` y `tools/onboard_stores.py`. Usa las mismas cuentas Apple Developer/App Store Connect y Google Play para los couriers, según la decisión del usuario. La identidad se obtiene del repositorio; los datos privados de cuenta se mantienen fuera del código y del vault.

## Resolver courier, plataformas y modo

Acepta `$onboard-courier 'xxx'`, donde `xxx` es un slug existente. Normaliza el nombre y verifica `whitelabel/<slug>.json`. Si no se especifican plataformas, prepara ambas: iOS y Android.

- **Plan:** una invocación sin modo o con «plan», «revisar» o «no ejecutar» inspecciona y entrega los pasos; no crea recursos ni genera builds.
- **Apply:** «modo apply», «registrar» o «dar de alta en las tiendas» autoriza ejecutar el registro Apple solicitado. En Android, prepara los datos para la creación manual en Play Console: el helper no crea apps ni carga el primer AAB.
- **Build/subida:** si se solicitan también IPA/AAB o TestFlight, continúa con la skill local `create-icourier-release` dentro del alcance solicitado. Alta y release tienen resultados distintos.

Para el procedimiento completo, configuración de cuentas o pasos del portal, lee la guía canónica [store-onboarding del vault](/Users/temis/Vault/Proyectos/iCourier2027/store-onboarding.md), equivalente a `~/Vault/Proyectos/iCourier2027/store-onboarding.md`. Si ese vault no está disponible, usa este entrypoint y la ayuda del helper; verifica las instrucciones actuales de Fastlane/Apple/Google antes de operar. No recrees una segunda guía en `docs/`.

## Plan y requisitos

1. Ejecuta `python3 tools/onboard_stores.py <slug> --json`. Este preflight requiere Python 3.9+ y macOS/plutil, comprueba identidad Android y las configuraciones Release de Runner/widget sin compilar.
2. Revisa bundle/package, App Group, equipo, versión/build, SKU e idioma primario. `es-DO` usa `es-MX` en App Store por defecto; `--apple-language es-ES` permite otra elección y no cambia el locale de la app. Conserva el SKU elegido para un alta ya iniciada.
3. Informa por plataforma qué queda listo, qué requiere credenciales y qué depende del portal. El plan indica `remoteState=no-consultado`: una identidad local válida no demuestra que el nombre, SKU o package estén disponibles.

## Apply Apple

Requiere Fastlane y `ICOURIER_APPLE_ID`, `ICOURIER_APPLE_TEAM_ID`, `ICOURIER_ASC_TEAM_ID`, o los flags equivalentes de `--help`. El Team ID Developer alfanumérico debe coincidir con Xcode; el ID App Store Connect es numérico. Reutiliza la cuenta ya configurada y solicita únicamente los datos faltantes. La autenticación y posible 2FA ocurren en Fastlane; no pidas contraseñas ni códigos en el chat.

```bash
python3 tools/onboard_stores.py <slug> --create-apple
```

El helper crea/reutiliza el App ID y registro de la app, App Group, capacidades y asociaciones; crea el App ID del widget con `skip_itc=true`. El widget comparte el grupo y no recibe otra ficha en App Store Connect. Los certificados/perfiles de distribución y la configuración APNs/Firebase son posteriores al registro.

Ante un fallo, revisa `build/store-onboarding/<slug>/<fecha>/apple.json` y el estado remoto antes de reintentar. Conserva identidad y SKU; no cambies equipos ni crees otro bundle para evadir el fallo. Si la sesión web de `produce` deja de funcionar, usa el portal con los mismos datos. Reporta por separado comandos aceptados y recursos comprobados: un retorno cero no acredita firma, TestFlight o publicación.

## Android

Para migrar una app existente a Play App Signing o resolver una exportación PEPK, usa [enrrollar-googleplay-signing](../enrrollar-googleplay-signing/SKILL.md); ese flujo conserva la firma original y registra por separado la clave de subida.

Entrega el nombre/package y los pasos de la guía para crear la app en la misma cuenta Play. El primer AAB firmado se carga manualmente y establece el package; después se puede integrar `supply` para actualizaciones, una integración que este helper todavía no implementa.

Para un courier nuevo sin certificado remoto de subida, el usuario debe elegir explícitamente el perfil local; registra su SHA-256 en `tools/android_releases.json` solo cuando haya autorizado esa asignación. Para una app ya existente, compara con su certificado de subida en Play Console. Compartir cuenta no implica compartir clave. `lastPublishedVersionCode` permanece desconocido hasta confirmar publicación.

Si está configurada la firma, `bash tools/build_android_bundle.sh --check <slug>` valida sin compilar. Genera el AAB solo cuando esté solicitado, mediante el flujo de release. En Play quedan el alta, Play App Signing, primera carga y declaraciones de ficha/acceso/privacidad/clasificación; describe su estado real en vez de marcarlas completadas por entregar instrucciones.

## Entrega

Por plataforma, indica resultado esperado y comprobado, identificadores, registro de ejecución si existe, y acciones pendientes antes/después del portal. Actualiza el vault únicamente si lo pide el usuario; conserva la separación entre marca integrada, ficha creada, build generado, build subido y app publicada.

Ejemplos:

```text
$onboard-courier dopack en ambas tiendas, modo plan
$onboard-courier dopack en ambas tiendas, modo apply
$onboard-courier dopack modo apply en iOS; además genera IPA y AAB sin subirlos
```
