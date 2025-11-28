# Datos

## Punto de entrada (URL) donde se reciben los datos

Los datos de lanzamientos se obtienen desde la API pública de SpaceX mediante la siguiente URL (endpoint de consultas):

```
https://api.spacexdata.com/v5/launches/query
```

En este proyecto, la llamada se realiza desde una función AWS Lambda que ejecuta una consulta POST a ese endpoint (se usan filtros por rango de fecha y ordenamiento). La Lambda normaliza y transforma la respuesta antes de almacenarla en DynamoDB.

## Cómo se almacenan los lanzamientos

La tabla de DynamoDB (por ejemplo `spacex-dashboard-launches`) guarda cada lanzamiento como un ítem independiente. El esquema principal usado es:

- Partition key: `id` (String) — el identificador del lanzamiento tal como lo devuelve la API de SpaceX.
- Sort key: `launch_date` (String, ISO8601) — fecha y hora del lanzamiento en formato ISO 8601 (por ejemplo `2017-06-23T19:10:00.000Z`).

Además existe un índice secundario (GSI) para consultas por fecha que facilita búsquedas por rango de `launch_date`.

### Ejemplo de ítem almacenado

Un ejemplo simplificado del ítem que se escribe en DynamoDB (campos reales pueden variar ligeramente):

```json
{
  "id": "5eb87d04ffd86e000604b353",
  "flight_number": 42,
  "mission_name": "BulgariaSat-1",
  "rocket_name": "5e9d0d95eda69973a809d1ec",
  "launch_date": "2017-06-23T19:10:00.000Z",
  "launch_date_precision": "hour",
  "static_fire_date": "2017-06-15T22:25:00.000Z",
  "launch_window": 7200,
  "launch_status": "success",
  "launchpad_id": "5e9e4502f509094188566f88",
  "crew": false,
  "capsules": false,
  "fairings_reused": false,
  "fairings_recovery_attempt": false,
  "fairings_recovered": false,
  "details": "Second time a booster will be reused..."
}
```

## Campos que conservamos y por qué

El proceso de transformación reduce la respuesta completa de la API a un conjunto de campos útiles para análisis y visualización. Los campos principales retenidos son:

- `id` (String): Identificador único del lanzamiento. Usado como partition key.
- `flight_number` (Number): Número de vuelo de la misión.
- `mission_name` (String): Nombre de la misión.
- `rocket_name` / `rocket` (String): Identificador del cohete (puede resolverse a un nombre si se enriquece posteriormente).
- `launch_date` (String, ISO8601): Fecha y hora del lanzamiento — sort key.
- `launch_date_precision` (String): Precisión de la fecha (`hour`, `day`, etc.).
- `static_fire_date` (String): Fecha del static fire si está disponible.
- `launch_window` (Number): Duración en segundos de la ventana de lanzamiento, cuando aplica.
- `launch_status` (String): Campo calculado con valores como `upcoming`, `success`, `failed`.
- `launchpad_id` (String): Identificador del sitio de lanzamiento.
- `crew` (Boolean): `true` si la misión tiene tripulación listada; `false` en caso contrario.
- `capsules` (Boolean): `true` si existen cápsulas asociadas.
- `fairings_reused`, `fairings_recovery_attempt`, `fairings_recovered` (Boolean/nullable): Resumen del objeto `fairings`.
- `details` (String, nullable): Texto descriptivo sobre la misión.

Se evita almacenar estructuras muy anidadas o pesadas (por ejemplo listas completas de `links.flickr.original`, `payloads` completos o `cores`) para mantener los ítems compactos y rápidos de leer; estos pueden recuperarse o normalizarse en tablas/índices adicionales si se necesita más detalle.

## Transformaciones realizadas por la Lambda antes del almacenamiento

La función Lambda (implementada en `compute/lambda/app.py`) aplica las siguientes transformaciones y validaciones:

1. Validación de claves obligatorias:
   - Se descartan los documentos sin `id` o sin `date_utc`.

2. Normalización de tipos:
   - `id` y `launch_date` se convierten explícitamente a `string` para asegurar compatibilidad con el esquema de DynamoDB.

3. Mapeo y renombrado de campos:
   - `name` → `mission_name`.
   - `date_utc` → `launch_date` (ISO8601).
   - `rocket` (id) se guarda en `rocket_name` (puede enriquecer a nombre humano luego).

4. Cálculo de campos derivables:
   - `launch_status`: se calcula a partir de `upcoming` y `success` de la API:
     - Si `upcoming` == true → `upcoming`
     - Si `upcoming` == false y `success` == true → `success`
     - En otro caso → `failed`

5. Simplificación de estructuras anidadas:
   - `crew`, `capsules` → se convierten en booleanos que indican presencia (true/false) en vez de arrays completos.
   - `fairings` → se extraen las claves `reused`, `recovery_attempt`, `recovered` y se almacenan como campos planos (`fairings_reused`, ...).

6. Escritura en batch a DynamoDB:
   - La Lambda junta los ítems válidos y escribe con `table.batch_writer()` (operación por lotes) para eficiencia.

## Dónde se ejecuta la lógica

- La llamada a la API de SpaceX, la transformación de los datos y la escritura en DynamoDB las realiza la función **AWS Lambda** (archivo `compute/lambda/app.py`).
- La Lambda usa la variable de entorno `DYNAMODB_TABLE` para saber el nombre de la tabla donde escribir.
- La ejecución está programada con **EventBridge** (queros programados 01:00, 07:00, 13:00, 19:00 UTC) y además se puede invocar manualmente mediante **API Gateway**.

## Notas operativas

- DynamoDB está configurada en modo `PAY_PER_REQUEST` para ajustar el coste a la demanda.
- Si se necesitan más detalles por lanzamiento (por ejemplo, imágenes, enlaces, payloads), se puede extender el pipeline para normalizar esos objetos en tablas secundarias o almacenar referencias (IDs) y consultar en demanda.
- Se recomienda revisar los logs de Lambda en CloudWatch (`/aws/lambda/<function-name>`) para controlar errores de transformación o problemas de escritura en DynamoDB.

____

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/jelambrar1)

Made with Love ❤️ by [@jelambrar96](https://github.com/jelambrar96)
