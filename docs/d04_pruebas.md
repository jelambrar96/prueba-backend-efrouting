

# Testing y Pruebas

Esta sección documenta cómo ejecutar y escribir pruebas para la función Lambda del proyecto **Jelambrar96X**.

---

## 1. Estructura de Tests

Los tests para Lambda se encuentran en:

```
compute/lambda/tests/
├── conftest.py          # Configuración de pytest
├── test_app.py          # Tests unitarios
└── run-tests.sh         # Script para ejecutar tests
```

**Archivos de prueba**:
- `test_app.py`: Contiene todos los tests (clases TestLaunchDataFunction y TestLambdaHandler)
- `conftest.py`: Configuración de pytest y fixtures
- `run-tests.sh`: Script bash para ejecutar tests de forma fácil

---

## 2. Requisitos para Ejecutar Tests

Asegúrate de que tienes instaladas las dependencias de testing:

```bash
cd compute/lambda/

# Instalar pytest y mock
pip install -r requirements.txt
pip install pytest pytest-mock
```

**Dependencias necesarias**:
- `pytest`: Framework de testing
- `pytest-mock`: Para mocking de funciones
- `boto3`: AWS SDK (para mocking)
- `requests`: HTTP client (para mocking)

---

## 3. Ejecutar Tests

### 3.1. Opción 1: Usando pytest (Recomendado)

```bash
cd compute/lambda/

# Ejecutar todos los tests
pytest tests/test_app.py -v

# Ejecutar tests específicos
pytest tests/test_app.py::TestLaunchDataFunction -v

# Ejecutar un test individual
pytest tests/test_app.py::TestLaunchDataFunction::test_launch_data_structure -v

# Ejecutar con coverage (qué porcentaje del código está cubierto)
pytest tests/test_app.py --cov=app --cov-report=html
```

### 3.2. Opción 2: Usando unittest (Python nativo)

```bash
cd compute/lambda/

# Ejecutar todos los tests
python -m unittest discover -s tests -p "test_*.py" -v

# Ejecutar tests de una clase específica
python -m unittest tests.test_app.TestLaunchDataFunction -v

# Ejecutar un test individual
python -m unittest tests.test_app.TestLaunchDataFunction.test_launch_data_structure
```

### 3.3. Opción 3: Usando el script bash

```bash
cd compute/lambda/

# Dar permisos de ejecución
chmod +x tests/run-tests.sh

# Ejecutar todos los tests
./tests/run-tests.sh

# Ejecutar un test específico
./tests/run-tests.sh test_app.py
```

---

## 4. Descripción de Tests

### 4.1. Tests de `TestLaunchDataFunction`

Validan la función `launch_data()` que transforma datos de la API de SpaceX:

| Test | Descripción |
|------|-------------|
| `test_launch_data_structure` | Verifica que la salida tiene todos los campos requeridos |
| `test_launch_data_values` | Valida que los valores se extraen correctamente |
| `test_launch_data_status_upcoming` | Verifica el cálculo de estado "upcoming" |
| `test_launch_data_status_failed` | Verifica el cálculo de estado "failed" |

**Ejemplo de ejecución**:
```bash
pytest tests/test_app.py::TestLaunchDataFunction -v

# Output:
# test_launch_data_structure PASSED [ 25%]
# test_launch_data_values PASSED [ 50%]
# test_launch_data_status_upcoming PASSED [ 75%]
# test_launch_data_status_failed PASSED [100%]
```

### 4.2. Tests de `TestLambdaHandler`

Validan el handler principal `lambda_handler()` con mocking de AWS services:

| Test | Descripción |
|------|-------------|
| `test_lambda_handler_success` | Lambda exitosa con respuesta de API mockada |
| `test_lambda_handler_with_custom_date` | Lambda con parámetro `utc_date` personalizado |
| `test_lambda_handler_api_error` | Manejo de error cuando la API falla |
| `test_lambda_handler_invalid_date` | Validación de formato de fecha inválido |
| `test_lambda_handler_multiple_launches` | Lambda procesando múltiples lanzamientos |
| `test_lambda_handler_prod_mode` | Lambda en modo producción (sin datos extra) |

**Ejemplo de ejecución**:
```bash
pytest tests/test_app.py::TestLambdaHandler::test_lambda_handler_success -v

# Output:
# test_lambda_handler_success PASSED
```

### 4.3. Tests de `TestLambdaHandlerWithoutRequestsMock`

Ejecutan Lambda contra la **API real** de SpaceX (sin mocking):

| Test | Descripción |
|------|-------------|
| `test_lambda_handler_real_api_call` | Lambda con API real de SpaceX |
| `test_lambda_handler_real_api_call_endtime` | Lambda con fecha custom contra API real |

⚠️ **Nota**: Estos tests requieren conexión a internet y son más lentos.

---

## 5. Ejemplo de Salida Completa

```bash
$ pytest tests/test_app.py -v

tests/test_app.py::TestLaunchDataFunction::test_launch_data_structure PASSED [ 5%]
tests/test_app.py::TestLaunchDataFunction::test_launch_data_values PASSED [ 10%]
tests/test_app.py::TestLaunchDataFunction::test_launch_data_status_upcoming PASSED [ 15%]
tests/test_app.py::TestLaunchDataFunction::test_launch_data_status_failed PASSED [ 20%]

tests/test_app.py::TestLambdaHandler::test_lambda_handler_success PASSED [ 25%]
tests/test_app.py::TestLambdaHandler::test_lambda_handler_with_custom_date PASSED [ 30%]
tests/test_app.py::TestLambdaHandler::test_lambda_handler_api_error PASSED [ 35%]
tests/test_app.py::TestLambdaHandler::test_lambda_handler_invalid_date PASSED [ 40%]
tests/test_app.py::TestLambdaHandler::test_lambda_handler_multiple_launches PASSED [ 45%]
tests/test_app.py::TestLambdaHandler::test_lambda_handler_prod_mode PASSED [ 50%]

tests/test_app.py::TestLambdaHandlerWithoutRequestsMock::test_lambda_handler_real_api_call PASSED [ 55%]
tests/test_app.py::TestLambdaHandlerWithoutRequestsMock::test_lambda_handler_real_api_call_endtime PASSED [ 60%]

================ 12 passed in 2.34s ================
```

---

## 6. Mocking de AWS Services

Los tests usan `unittest.mock` para simular comportamientos de AWS sin hacer llamadas reales:

### 6.1. Mocking de `requests.post`

```python
@patch('app.requests.post')
def test_lambda_handler_success(self, mock_requests):
    # Simulamos la respuesta de la API de SpaceX
    mock_response = MagicMock()
    mock_response.json.return_value = {
        "docs": [
            {
                "id": "5eb87d04ffd86e000604b353",
                "flight_number": 42,
                "mission_name": "BulgariaSat-1",
                ...
            }
        ]
    }
    mock_requests.return_value = mock_response
    
    # Ahora cuando Lambda llame a requests.post(), 
    # recibirá nuestra respuesta simulada
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200
```

### 6.2. Mocking de `boto3.resource` (DynamoDB)

```python
@patch('app.boto3.resource')
def test_lambda_handler_success(self, mock_dynamodb):
    # Simulamos DynamoDB
    mock_table = MagicMock()
    mock_dynamodb.return_value.Table.return_value = mock_table
    
    # Cuando Lambda llame a boto3.resource("dynamodb").Table(...),
    # recibirá nuestro mock en lugar del DynamoDB real
    response = lambda_handler(event, None)
    
    # Podemos verificar que se llamó al put_item
    mock_table.batch_writer.return_value.__enter__.return_value.put_item.assert_called()
```

---

## 7. Cobertura de Código

Para ver qué porcentaje del código está cubierto por tests:

```bash
# Instalar coverage
pip install coverage

# Ejecutar tests con coverage
pytest tests/test_app.py --cov=app --cov-report=term-missing --cov-report=html

# Ver reporte HTML
open htmlcov/index.html
```

**Salida esperada**:
```
Name        Stmts   Miss  Cover   Missing
-----------------------------------------
app.py        120     5    96%    85, 92, 105-110, 120
```

---

## 8. Tests en CI/CD (GitHub Actions)

Para ejecutar tests automáticamente en cada push:

```yaml
# .github/workflows/test-lambda.yml

name: Test Lambda Function

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.12'
      - run: pip install -r compute/lambda/requirements.txt
      - run: pip install pytest
      - run: pytest compute/lambda/tests/ -v
```

---

## 9. Troubleshooting

### Error: "No module named 'app'"

**Solución**:
```bash
cd compute/lambda/
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
pytest tests/test_app.py -v
```

### Error: "ModuleNotFoundError: No module named 'boto3'"

**Solución**:
```bash
pip install boto3 requests
pytest tests/test_app.py -v
```

### Tests pasan localmente pero fallan en AWS Lambda

**Verificaciones**:
1. Confirma que `DYNAMODB_TABLE` está set en la variable de entorno de Lambda
2. Verifica que el rol IAM de Lambda tiene permisos en DynamoDB
3. Revisa los logs en CloudWatch: `/aws/lambda/spacex-dashboard-fetcher`

---

## 10. Mejores Prácticas

✅ **Hacer**:
- Usar `@patch` para mockear dependencias externas
- Separar tests en clases lógicas
- Usar descriptores claros en los nombres de tests
- Incluir docstrings explicativos
- Probar casos de error, no solo happy path

❌ **Evitar**:
- Hacer llamadas reales a APIs en cada test
- Tests que dependen entre sí
- Tests demasiado lentos (usar mocks)
- Hardcodear valores; usar fixtures

---

## 11. Ejemplo: Escribir un Test Nuevo

Si quieres añadir un nuevo test:

```python
# En compute/lambda/tests/test_app.py

class TestLambdaHandler(unittest.TestCase):
    
    @patch('app.requests.post')
    @patch('app.boto3.resource')
    def test_lambda_handler_empty_response(self, mock_dynamodb, mock_requests):
        """Test Lambda when SpaceX API returns no launches"""
        # Arrange: Configura los mocks
        mock_response = MagicMock()
        mock_response.json.return_value = {"docs": []}  # Sin lanzamientos
        mock_requests.return_value = mock_response
        
        mock_table = MagicMock()
        mock_dynamodb.return_value.Table.return_value = mock_table
        
        # Act: Ejecuta Lambda
        event = {"offset_seconds": 2592000}
        response = lambda_handler(event, None)
        
        # Assert: Verifica el resultado
        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(body["inserted_items"], 0)
```

Luego ejecuta:
```bash
pytest tests/test_app.py::TestLambdaHandler::test_lambda_handler_empty_response -v
```

---

## 12. Referencias

- **Pytest Documentation**: https://docs.pytest.org/
- **Python unittest**: https://docs.python.org/3/library/unittest.html
- **unittest.mock**: https://docs.python.org/3/library/unittest.mock.html
- **Coverage.py**: https://coverage.readthedocs.io/

---

____

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/jelambrar1)

Made with Love ❤️ by [@jelambrar96](https://github.com/jelambrar96)
