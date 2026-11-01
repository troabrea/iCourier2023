# Etapas compartidas de paquetes

El recorrido visible en todos los whitelabels es Origen → En tránsito →
En distribución → Disponible. Entregado es terminal; Sin Factura es una
condición adicional, no una quinta etapa del recorrido.

## Reglas

- Recibido para procesar y Listo para embarcación: Origen.
- Embarcado y Aduana: En tránsito, incluso si el backend envía progreso 3.
- En tránsito a sucursal y Recibido en sucursal: En distribución.
- Disponible requiere `disponible=true`; el texto o progreso 4 sin esa bandera
  se presenta como En distribución. Entregado al cliente conserva prioridad.
- Sin Factura requiere `retenido && !disponible`. Sus paquetes se incluyen en
  su etapa, por lo que su contador es un subconjunto y no debe sumarse al total.
- Los alias heredados Transferido, Empacado, Recibido AILA, Almacén, Warehouse,
  Distribution Center, Packed, Outgoing Transfer y Destino conservan su etapa
  de distribución. Los eventos desconocidos conservan el respaldo de progreso
  (0/1 origen, 2 tránsito, 3/4 distribución, mayor que 4 entregado).
- Los identificadores `origen`, `ruta`, `destino`, `disponible`, `entregado`
  permanecen estables para enlaces y snapshots. Las etiquetas se resuelven
  mediante `PackageStage.labelKey`.

## Widgets y compatibilidad

Los snapshots V1 agregan `counts.enTransito` y `counts.enDistribucion`.
`counts.enRuta` permanece como suma heredada y `enProceso` representa Origen.
Los lectores aceptan snapshots anteriores sin los nuevos campos: muestran
guiones en los dos conteos desconocidos, marcan los datos para actualizar y
solicitan una actualización sin asumir un reparto del antiguo agregado.

La fuente de reglas es `lib/domain/package_stage.dart`. Después de editar sus
equivalencias ejecutar `python3 tools/sync_package_status_native.py` para
actualizar las tablas Swift/Kotlin. `--check` detecta divergencias.

Los tres clasificadores ejecutan los mismos casos de
`test/fixtures/package_stages.json`. Swift también comprueba lectura de
snapshots previos mediante `python3 tools/test_package_status_swift.py`.
Android ejecuta esos casos y los conteos en `WidgetFreshnessTest`.
