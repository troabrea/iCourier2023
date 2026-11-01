# Seguimiento de paquetes de iCourier

## Language

**Estatus operativo**:
Evento específico del recorrido de un paquete, como “Embarcado” o “Aduana”.

**Etapa**:
Agrupación del recorrido que ve el cliente: Origen, En tránsito, En distribución o Disponible.

**Origen**:
Preparación del paquete para su traslado internacional: recibido para procesar o listo para embarcación.
_Avoid_: Recibido como nombre de la etapa.

**En tránsito**:
Traslado internacional y proceso aduanal del paquete.
_Avoid_: En ruta como nombre de la etapa.

**En distribución**:
Traslado interno hacia la sucursal y recepción en sucursal, antes de habilitar retiro o delivery.
_Avoid_: En destino como nombre de la etapa.

**Disponible**:
Paquete habilitado para retirar o recibir por delivery. Estar recibido en una sucursal no implica estar disponible.
_Avoid_: Disponibles como nombre de la etapa individual.

**Sin Factura**:
Condición adicional de un paquete que requiere adjuntar su factura y todavía no está disponible.

**Entregado**:
Entrega final al cliente. El traspaso a la línea aérea no es una entrega final.

**Retiro notificado**:
Paquete cuyo retiro ya fue solicitado; conserva su tratamiento separado en el inicio.
