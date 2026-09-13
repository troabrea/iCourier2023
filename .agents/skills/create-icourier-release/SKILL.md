---
name: create-icourier-release
description: Prepara releases de iCourier para uno o varios couriers de este repositorio, incrementando builds y opcionalmente la versión; genera IPA/TestFlight o AAB Android con la firma y configuración de cada whitelabel.
---

# Releases iCourier

Skill local de este proyecto. Ejecuta desde la raíz que contiene `pubspec.yaml`, `whitelabel/`, `ios/Runner.xcodeproj` y `tools/android_releases.json`. Los paths de comandos son relativos a esa raíz.

## Resolver la solicitud

Convierte la petición en dos listas de slugs: iOS y Android, admitiendo uno o varios couriers y distintas plataformas por courier. Normaliza BMCargo → `bmcargo`, TuPaq → `tupaq`; valida los slugs contra `whitelabel/*.json`. Si faltan couriers o plataforma y el contexto no los determina, solicita solo ese dato.

- Por defecto conserva la versión visible e incrementa el build de las plataformas solicitadas una sola vez por lote.
- Acepta una versión explícita `X.Y.Z`; si piden patch/minor/major, calcula el valor y muéstralo antes de aplicarlo. Ante versiones iniciales distintas, aclara qué versión común desean.
- «Revisar», «planificar» o «no generar todavía» termina en el plan: sin `--apply`, compilaciones ni subidas.
- «Generar IPA/AAB» entrega archivos locales. «Subir a TestFlight» autoriza la subida; «para TestFlight» sin verbo de subida prepara el IPA y deja indicado ese siguiente paso. Usa la autorización ya existente en la conversación; evita pedirla de nuevo. Generar AAB no publica en Play.

Ejemplos de invocación:

```text
$create-icourier-release solo plan: iOS bmcargo,tupaq; Android tupaq
$create-icourier-release genera IPA para bmcargo y tupaq, y AAB para tupaq
$create-icourier-release sube bmcargo y tupaq a TestFlight; versión 2027.0.3
```

## Preflight y versión

1. Revisa el diff y los cambios del usuario que se incluirían; conserva el estado de trabajo. Resuelve los entrypoints reales: `picknsend` usa `lib/apps/pns/main_pns.dart`. Mantén el Flutter de `.fvmrc` mediante FVM.
2. Para Android, lee [la guía del repositorio](../../../docs/android-releases.md) y ejecuta `bash tools/build_android_bundle.sh --check <courier>` para cada solicitado. Para iOS, lee [el procedimiento iOS](references/ios.md) y verifica las configuraciones, versión, widget y firma descritos allí. Estos preflights no compilan.
3. Consulta builds ya subidos/procesándose en App Store Connect y códigos publicados/subidos en Play cuando tengas acceso; los números locales no garantizan disponibilidad remota. Si no puedes comprobarlo, informa ese límite sin bloquear la generación local autorizada. Si hay un conflicto conocido, actualiza primero la base local al último número confirmado y vuelve a calcular; nunca reintentes una subida con un número conocido como ocupado.
4. Obtén el plan con el helper:

```bash
/usr/bin/ruby .agents/skills/create-icourier-release/scripts/prepare_release.rb \
  --ios bmcargo,tupaq --android tupaq
# Opcional: --version 2027.0.3
```

El JSON muestra versión, build, courier, bundle/package ID y entrypoint. El helper solo modifica archivos con `--apply`; nunca compila ni sube. Requiere Ruby con `xcodeproj`, igual que `tool/configure_ios_widget.rb`.

**Semántica del incremento:** iOS usa `max(build de pubspec, builds Release seleccionados) + 1` compartido entre los couriers iOS del lote. Actualiza `CURRENT_PROJECT_VERSION` en `Runner` y `ICourierWidget`, solo `Release-<courier>`, y el sufijo de `pubspec.yaml`. Conserva Debug/Profile y couriers no seleccionados. Android incrementa el código común de `android/release.properties` una sola vez, independientemente del build iOS. Un lote solo Android conserva el build iOS; uno solo iOS conserva el código Android. `--version` cambia la versión global de pubspec (todos los futuros AAB la heredan) y la versión de los targets Release iOS seleccionados. Sin esa opción conserva cada versión visible existente.

5. Si la ejecución está autorizada, aplica exactamente las mismas opciones con `--apply`, revisa el diff de versiones y guarda el JSON del plan aplicado junto al registro de la ejecución. No invoques `--apply` otra vez al pasar al siguiente courier ni al retomar un build fallido. Si la escritura se interrumpe, compara los tres archivos de versiones con el plan antes de continuar.

## Compilar y entregar

Ejecuta los couriers **secuencialmente**: Flutter/Xcode comparten `Generated.xcconfig`, salidas y metadatos de flavor. Una compilación en paralelo o un `flutter run` concurrente puede mezclar los targets. Conserva los artefactos verificados de cada courier antes del siguiente.

- **Android:** usa únicamente `bash tools/build_android_bundle.sh <courier>`; este script asigna la firma, compila y verifica el AAB. La entrega válida es el AAB y JSON anunciados al finalizar con éxito en `build/releases/<courier>/<code>/`. No uses `tool/build_matrix.sh` para releases. Conserva `lastPublishedVersionCode=null` hasta confirmar publicación; una subida aceptada no es publicación.
- **iOS:** sigue [el procedimiento iOS](references/ios.md), exporta localmente y verifica la identidad del app y widget antes de una subida autorizada. La existencia de un archive o IPA antiguo no prueba éxito de esta ejecución.

Ante un fallo, conserva las entregas exitosas, registra courier/fase/error y corrige la causa antes de reintentar. No aumentes builds automáticamente por errores de firma, red o compilación. Ante una subida de resultado incierto, consulta App Store Connect antes de repetir o cambiar números. Un rechazo de credenciales/permisos detiene esa subida hasta resolver el acceso.

Entrega por courier: plataforma, versión/build real del artefacto, ruta, SHA-256 y estado comprobado (`generado`, `subido`, `procesando`, `disponible en TestFlight`). Distingue pendiente de confirmado. No hagas commits ni publiques en tiendas salvo que la petición lo incluya.

## Validar cambios del skill

El helper se prueba sin compilar y aplica versiones solo en copias temporales:

```bash
python3 .agents/skills/create-icourier-release/scripts/test_prepare_release.py
```
