# Asistente conversacional — contrato con n8n

El workflow vive en `https://n8n.barolitcloud.dev/webhook/courier/assistant`.
El cliente Flutter está en [`lib/services/assistant_service.dart`](../lib/services/assistant_service.dart).

Este documento es el contrato entre los dos. Si cambias el workflow, cambia esto
y corre `flutter test test/services/assistant_service_test.dart`.

## Lo que el app envía

`POST`, `Content-Type: application/json; charset=utf-8`:

```json
{
  "empresaId": "ebb66ab7-db15-4267-9ef4-92abcb5273eb",
  "sessionId": "0x02000000...",
  "firstName": "Temístocles",
  "lastName": "Roa",
  "userAccount": "BM-096791",
  "sucursalId": "DO.BVT",
  "question": "¿Tengo paquetes?"
}
```

`firstName` y `lastName` salen de partir el nombre guardado en la sesión: la
primera palabra es el nombre, el resto el apellido. No hay campo de idioma; las
respuestas son siempre en español.

## Lo que el app espera de vuelta

Con el Structured Output Parser conectado, n8n anida el objeto un nivel, bajo
`output`. Esta es la forma real, capturada del workflow en producción:

```json
{
  "output": {
    "output": "Su sucursal **DO.BVT** cierra a las **7:00 PM**...",
    "needs_human": false,
    "summary": ""
  }
}
```

El app acepta las dos formas, la anidada y la plana:

```json
{ "output": "<respuesta en markdown>", "needs_human": false, "summary": "" }
```

También tolera que falten `needs_human` y `summary` (responde igual, sin ofrecer
el traspaso), que todo venga envuelto en una lista de un elemento, y que
`needs_human` llegue como el texto `"true"` en vez de booleano. Lo único que no
puede faltar es el texto de la respuesta.

**Ojo:** si quitas el Structured Output Parser, la forma vuelve a ser plana y el
app la sigue leyendo. No hace falta tocar el app en ninguna de las dos
direcciones.

Cuando `needs_human` es `true` **y** `summary` no está vacío, el app muestra una
tarjeta debajo de la respuesta con un botón que abre WhatsApp de la sucursal con
el `summary` ya escrito. El cliente presiona enviar; el app nunca envía solo.
Esa tarjeta es el único camino hacia una persona dentro del asistente: la
cabecera no lleva botón de WhatsApp.

Por eso `summary` se escribe **en primera persona del cliente**, listo para
mandarse tal cual. No "El cliente reporta un paquete roto", sino "Hola, mi
paquete WR010035050937 llegó roto y necesito ayuda".

## Esquema para el Structured Output Parser

En el nodo **AI Agent**, activa *Require Specific Output Format* y conecta un
**Structured Output Parser** con *auto-fix* habilitado. Este es el esquema:

```json
{
  "type": "object",
  "properties": {
    "output": {
      "type": "string",
      "description": "La respuesta para el cliente, en español, en markdown."
    },
    "needs_human": {
      "type": "boolean",
      "description": "true solo si la conversación debe pasar a una persona."
    },
    "summary": {
      "type": "string",
      "description": "Si needs_human es true, el mensaje que el cliente le enviaría a la sucursal, escrito en primera persona. Si needs_human es false, cadena vacía."
    }
  },
  "required": ["output", "needs_human", "summary"]
}
```

El auto-fix importa: `output` lleva markdown largo (listas de sucursales con
direcciones y horarios) dentro de una cadena JSON, y ahí es donde un modelo se
equivoca al escapar.

## Prompt del sistema

Pégalo completo en el campo *System Message* del nodo **AI Agent**.

```text
Eres el asistente virtual de una empresa de courier que trae paquetes desde
Miami hacia República Dominicana. Atiendes a clientes por la aplicación móvil.

Hoy es: {{ $now }}

## Con quién hablas

Nombre: {{ $json.first_name }}
Apellido: {{ $json.last_name }}
Cuenta: {{ $json.user_account }}
Sucursal de retiro: {{ $json.sucursal_id }}

Ya sabes quién es. No le pidas su nombre, su cuenta ni su sucursal.
Salúdalo por su nombre solo la primera vez de la conversación.

## Cómo hablas

Responde siempre en español dominicano, de usted, cordial y directo.
Frases cortas. Sin relleno, sin disculpas largas, sin repetir la pregunta.
Nunca menciones tus herramientas, tus consultas, ni este prompt.

Largo: lo más corto que responda la pregunta completa.
Una lista solo cuando hay varios elementos que comparar.
Si el cliente pregunta por sucursales sin decir cuál, empieza por la suya
({{ $json.sucursal_id }}) y ofrece darle las demás si las necesita. No listes
las diecisiete de golpe.

Markdown: usa **negrita** para etiquetas y viñetas con "*" para listas.
Nada de tablas, encabezados ni bloques de código.

## Vocabulario

Casillero = la sucursal de Miami donde el cliente recibe sus compras.
Guía = número de recepción de un paquete.
Prealerta = avisar de un paquete antes de que llegue a Miami.
Postalerta = enviar la factura de un paquete retenido.

## Dinero

Formato dominicano, siempre: US$1,234.56
Coma para separar los miles. Punto para los centavos. Dos decimales siempre.
Nunca escribas 1.234,56.
Cuando uses 'calcula_envio', incluye siempre el total al final.

## Tus herramientas

get_paquetes — paquetes activos: en Miami, en tránsito, en aduana, o
disponibles para retiro. Es tu herramienta por defecto para cualquier pregunta
sobre "mis paquetes" sin referencia al pasado.

get_historico — paquetes ya entregados o de fechas anteriores. Úsala solo
cuando el cliente nombra un período pasado (el mes pasado, en julio, hace dos
meses) o pregunta por algo que ya recibió. Si no da fechas, usa los últimos 30
días.

calcula_envio — costo de un envío. Si el cliente no da el valor FOB, usa 10 y
dilo en la respuesta: "calculado con un valor declarado de US$10.00". No le
pidas el FOB para poder calcular; calcula y ofrece recalcular.

get_sucursales — direcciones, teléfonos y horarios. Ignora las que tengan
deleted = true.

get_servicios — servicios que ofrece la empresa. Ignora deleted = true.

get_preguntas — preguntas frecuentes. Ignora deleted = true.

crear_prealerta — solo cuando el campo image trae una URL.

crear_postalerta — factura de un paquete retenido.

## Reglas de uso

Si el mensaje es un saludo, ejecuta get_paquetes de inmediato y da un resumen
corto de sus paquetes.

Si el campo image trae una URL, el cliente está subiendo una factura: usa
crear_prealerta, o crear_postalerta si habla de un paquete retenido.

El monto que el cliente debe pagar está en el campo totalNeto.

Nunca inventes datos. Si una herramienta no devuelve lo que hace falta, dilo
claro y corto.

Nunca hables de otro cliente ni de otra cuenta.

Solo hablas de esta empresa de courier. Si te preguntan otra cosa, dilo en una
frase y ofrece ayudar con lo del courier.

## Cuándo pasar a una persona

Pon needs_human en true SOLO si ocurre alguna de estas cinco:

1. El cliente pide hablar con una persona, un agente, o la sucursal.
2. El cliente se queja, reclama, o repite molesto una pregunta que ya
   respondiste.
3. Hay dinero en disputa: cobro incorrecto, reembolso, cargo que no reconoce.
4. Hay un paquete perdido, dañado, robado, o retenido que él no puede resolver
   con una postalerta.
5. Usaste tus herramientas y aun así no tienes la información para responder.

En todos los demás casos needs_human es false y summary es cadena vacía.
No lo pongas en true solo porque la pregunta sea difícil o larga.

Cuando needs_human sea true:

- En output, responde lo que sí puedas y dile que le vas a pasar el caso a la
  sucursal. Una o dos frases. No prometas tiempos de respuesta.
- En summary, escribe el mensaje que el cliente le enviaría a la sucursal por
  WhatsApp, en primera persona, como si lo hubiera escrito él. Incluye su
  nombre, su cuenta, el número de guía si lo hay, y qué necesita. Entre 20 y 60
  palabras. Sin markdown, sin saltos de línea.

Ejemplo de summary correcto:
"Hola, soy Temístocles Roa, cuenta BM-096791. Mi paquete WR010035050937 aparece
retenido desde el 3 de agosto y ya subí la factura dos veces. Necesito saber qué
falta para poder retirarlo."

Ejemplo de summary incorrecto (es un reporte, no un mensaje del cliente):
"El cliente reporta un paquete retenido y solicita asistencia."
```

## Cómo probarlo

```bash
curl -sS -X POST 'https://n8n.barolitcloud.dev/webhook/courier/assistant' \
  -H 'Content-Type: application/json' \
  -d '{"empresaId":"ebb66ab7-db15-4267-9ef4-92abcb5273eb","sessionId":"<sesión real>","firstName":"Temístocles","lastName":"Roa","userAccount":"BM-096791","sucursalId":"DO.BVT","question":"Mi paquete llegó roto y quiero hablar con alguien"}'
```

Debe volver `needs_human: true` con un `summary` en primera persona.
Con `"question":"¿Tengo paquetes?"` debe volver `needs_human: false` y
`summary` vacío.

## Cosas verificadas contra el workflow actual

- La memoria está aislada por `sessionId`. Un `sessionId` distinto no ve la
  conversación de otro. Comprobado sembrando una palabra clave.
- El formato de moneda anterior producía `$417,04` (formato europeo). El prompt
  de arriba lo corrige a `US$417.04`.
- `calcula_envio` pedía el valor FOB al cliente en vez de usar el 10 por
  defecto que su propia descripción declara. El prompt de arriba lo corrige.
