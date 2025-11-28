

# CI/CD con GitHub Actions

Esta sección documenta la configuración de **Continuous Integration** (CI) y **Continuous Deployment** (CD) usando GitHub Actions para el proyecto **Jelambrar96X**.

---

## 1. ¿Qué es CI/CD?

**CI (Continuous Integration)**: Integración continua de cambios en el código.
- Ejecuta tests automáticamente en cada push
- Valida código y detecta errores temprano
- Mantiene la calidad del proyecto

**CD (Continuous Deployment)**: Despliegue automático de cambios.
- Despliega Lambda, Docker, Terraform automáticamente
- Reduce errores manuales
- Acelera el time-to-market

**Ventajas en este proyecto**:
- ✅ Tests automáticos en cada push
- ✅ Validación de código (linting, seguridad)
- ✅ Despliegue automático de Lambda
- ✅ Construcción y push de imágenes Docker
- ✅ Despliegue de infraestructura Terraform
- ✅ Documentación generada automáticamente

---

## 2. Flujos de GitHub Actions

El proyecto contiene **6 workflows** principales en `.github/workflows/`:

| Workflow | Trigger | Función |
|----------|---------|---------|
| `unit_tests.yml` | Push/PR en `main`, `develop` | Ejecuta tests de Lambda |
| `code_quality.yml` | Push/PR en `main`, `develop` | Linting, seguridad, análisis |
| `build_docker_image.yml` | Push en `main` (compute/streamlit) | Construye y pushea imagen Docker |
| `deploy_lambda.yml` | Push en `main` (compute/lambda) | Despliega función Lambda |
| `deploy_terraform.yml` | Push/PR en `main` (terraform) | Valida y aplica cambios Terraform |
| `build_docs.yml` | Push en `main` (docs) | Construye y publica documentación |

---

## 3. Workflow 1: Unit Tests (`unit_tests.yml`)

### 3.1. Propósito

Ejecuta tests automáticamente en cada push o pull request para garantizar que el código no rompe funcionalidades existentes.

### 3.2. Triggers

```yaml
on:
  push:
    branches: [ main, develop ]
    paths:
      - 'compute/lambda/**'      # Solo si hay cambios en Lambda
      - '.github/workflows/tests.yml'
  pull_request:
    branches: [ main, develop ]
```

**Cuándo se ejecuta**:
- ✅ Push a `main` o `develop` con cambios en `compute/lambda/`
- ✅ Pull Request a `main` o `develop` con cambios en Lambda
- ❌ Otros pushes en ramas o cambios en otras carpetas

### 3.3. Pasos del Workflow

```
1. Checkout del código
2. Setup Python (3.9, 3.10, 3.11 en paralelo)
3. Instalar dependencias
4. Ejecutar pytest con coverage
5. Subir reporte de cobertura a Codecov
```

### 3.4. Salida esperada

```bash
$ pytest test_app.py -v --cov=.. --cov-report=xml

tests/test_app.py::TestLaunchDataFunction::test_launch_data_structure PASSED [ 5%]
...
tests/test_app.py::TestLambdaHandler::test_lambda_handler_success PASSED [ 60%]

================ 12 passed in 2.34s ================
Coverage: 96%
```

### 3.5. Cómo ejecutar manualmente (Local)

```bash
# Instalar dependencias
pip install -r compute/lambda/requirements.txt
pip install pytest pytest-cov

# Ejecutar tests
cd compute/lambda/tests
pytest test_app.py -v --cov=.. --cov-report=xml

# Ver cobertura
coverage html
open htmlcov/index.html
```

---

## 4. Workflow 2: Code Quality (`code_quality.yml`)

### 4.1. Propósito

Valida calidad del código (formatos, imports, seguridad) sin ejecutar tests.

**Checks incluidos**:
- 🐍 **Black**: Formatea código Python
- 📦 **isort**: Organiza imports
- 📋 **Flake8**: Detecta errores de estilo
- 🔒 **Bandit**: Detecta vulnerabilidades de seguridad
- ⚠️ **Safety**: Revisa dependencias con CVEs conocidos

### 4.2. Triggers

```yaml
on:
  push:
    branches: [ main, develop ]
    paths:
      - 'compute/**'
  pull_request:
    branches: [ main, develop ]
```

### 4.3. Componentes del Workflow

#### 4.3.1. Job 1: Linting

```bash
# Black - Verificar formato
black --check compute/lambda compute/streamlit

# isort - Verificar imports
isort --check-only compute/lambda compute/streamlit

# Flake8 - Errores críticos
flake8 compute/lambda --select=E9,F63,F7,F82 --show-source

# Flake8 - Complejidad
flake8 compute/lambda --max-complexity=10 --max-line-length=127
```

**Salida esperada**:
```
$ black --check compute/lambda
All done! ✓

$ flake8 compute/lambda --count
0
```

#### 4.3.2. Job 2: Security

```bash
# Bandit - Escaneo de seguridad
bandit -r compute/lambda -f json -o bandit-report.json

# Safety - Vulnerabilidades en dependencias
safety check --json
```

**Salida esperada**:
```
bandit-report.json: {
  "results": [],
  "metrics": {"_totals": {"SEVERITY.HIGH": 0}}
}
```

### 4.4. Cómo ejecutar manualmente (Local)

```bash
# Instalar herramientas
pip install black isort flake8 bandit safety

# Ejecutar checks
black --check compute/lambda
isort --check-only compute/lambda
flake8 compute/lambda --max-complexity=10
bandit -r compute/lambda
safety check
```

---

## 5. Workflow 3: Build Docker Image (`build_docker_image.yml`)

### 5.1. Propósito

Construye imagen Docker del dashboard Streamlit y la pushea a GitHub Container Registry (GHCR).

### 5.2. Triggers

```yaml
on:
  push:
    branches: [ main ]
    paths:
      - 'compute/streamlit/**'
      - '.github/workflows/build_docker_image.yml'
  workflow_dispatch:  # Ejecutable manualmente
```

### 5.3. Pasos del Workflow

```
1. Checkout del código
2. Setup Docker Buildx (para multi-plataforma)
3. Login a GitHub Container Registry
4. Extraer metadata (tags, versiones)
5. Construir y pushear imagen Docker
```

### 5.4. Tags Generados Automáticamente

La imagen se etiqueta con:
- `latest` (rama principal)
- `main` (nombre de rama)
- `sha-<commit-hash>` (SHA del commit)
- `semver` (versiones semánticas si existen tags Git)

**Ejemplo**:
```
ghcr.io/jelambrar96/prueba-backend-efrouting-streamlit:latest
ghcr.io/jelambrar96/prueba-backend-efrouting-streamlit:main
ghcr.io/jelambrar96/prueba-backend-efrouting-streamlit:sha-a1b2c3d
```

### 5.5. Cómo ejecutar manualmente (Local)

```bash
# Construir imagen localmente
docker build -t prueba-streamlit:latest compute/streamlit/

# Verificar imagen
docker images | grep prueba-streamlit

# Ejecutar imagen localmente
docker run -p 8501:8501 prueba-streamlit:latest

# Acceder a: http://localhost:8501
```

### 5.6. Cómo ejecutar en GitHub

**Opción 1: Automáticamente** (Push a main con cambios en `compute/streamlit/`)
```bash
git add compute/streamlit/
git commit -m "Update Streamlit dashboard"
git push origin main
# ✅ Workflow se ejecuta automáticamente
```

**Opción 2: Manualmente** (workflow_dispatch)
```bash
# En GitHub: Actions → Build and Push Docker Images → Run workflow
# O usar GitHub CLI:
gh workflow run build_docker_image.yml
```

### 5.7. Verificar Construcción

```bash
# Ver logs en GitHub
gh run list --workflow=build_docker_image.yml -L 5

# Ver detalles de un run
gh run view <run-id> --log
```

---

## 6. Workflow 4: Deploy Lambda (`deploy_lambda.yml`)

### 6.1. Propósito

Despliega automáticamente cambios de Lambda a AWS.

**Pasos**:
1. Construir paquete de deployment (Lambda + dependencias)
2. Ejecutar tests
3. Desplegar a AWS Lambda
4. Publicar versión

### 6.2. Triggers

```yaml
on:
  push:
    branches: [ main ]
    paths:
      - 'compute/lambda/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Entorno de despliegue'
        default: 'prod'
        options: [ dev, prod ]
```

### 6.3. Pasos del Workflow

```
1. Build
   ├─ Checkout código
   ├─ Setup Python 3.11
   ├─ Instalar dependencias en /package
   ├─ Copiar app.py y model.py
   ├─ Crear lambda-deployment.zip
   └─ Subir artefacto

2. Test
   ├─ Descargar artefacto
   ├─ Ejecutar pytest
   └─ Verificar cobertura

3. Deploy
   ├─ Descargar artefacto
   ├─ Configurar credenciales AWS
   ├─ Actualizar función Lambda (o crear si no existe)
   ├─ Esperar a que se complete
   ├─ Publicar versión
   └─ Comentar en PR con resultado
```

### 6.4. Variables de Entorno

```yaml
LAMBDA_FUNCTION_NAME: efrouting-fetcher
AWS_REGION: us-east-1
```

### 6.5. Secretos Requeridos

En GitHub → Settings → Secrets and variables → Actions:

```
AWS_ROLE_TO_ASSUME          # ARN del rol IAM para asumir
LAMBDA_EXECUTION_ROLE_ARN   # ARN del rol de ejecución de Lambda
```

**Ejemplo**:
```
AWS_ROLE_TO_ASSUME=arn:aws:iam::891377338512:role/github-actions-role
LAMBDA_EXECUTION_ROLE_ARN=arn:aws:iam::891377338512:role/lambda-execution-role
```

### 6.6. Cómo ejecutar manualmente (Local)

```bash
# Preparar paquete
cd compute/lambda
mkdir -p package
pip install -r requirements.txt -t package/
cp app.py model.py package/

# Crear ZIP
cd package
zip -r ../lambda-deployment.zip .
cd ..

# Desplegar a AWS
aws lambda update-function-code \
  --function-name efrouting-fetcher \
  --zip-file fileb://lambda-deployment.zip \
  --region us-east-1

# Publicar versión
aws lambda publish-version \
  --function-name efrouting-fetcher \
  --region us-east-1
```

### 6.7. Ejecutar en GitHub

```bash
# Automáticamente al push a main
git add compute/lambda/
git commit -m "Update Lambda function"
git push origin main
# ✅ Workflow se dispara

# Manualmente (workflow_dispatch)
gh workflow run deploy_lambda.yml -f environment=prod
```

---

## 7. Workflow 5: Deploy Terraform (`deploy_terraform.yml`)

### 7.1. Propósito

Valida y aplica cambios de infraestructura usando Terraform.

**Pasos**:
1. **Validate**: Validar sintaxis Terraform
2. **Plan** (en PRs): Mostrar cambios planeados
3. **Apply** (en main): Aplicar cambios a AWS

### 7.2. Triggers

```yaml
on:
  push:
    branches: [main]
    paths:
      - "terraform/**"
  pull_request:
    branches: [main]
    paths:
      - "terraform/**"
  workflow_dispatch:  # Manual
```

### 7.3. Job 1: Validate

Se ejecuta siempre. Valida formato y sintaxis.

```bash
terraform fmt -check      # Verificar formato
terraform init             # Inicializar
terraform validate         # Validar sintaxis
```

**Salida**:
```
Success! The configuration is valid.
```

### 7.4. Job 2: Plan (Pull Requests)

Se ejecuta en PRs. Muestra los cambios planeados.

```bash
terraform plan -out=tfplan
# Comenta en el PR los cambios
```

**Comentario en PR**:
```
Terraform will perform the following actions:

  # aws_lambda_function.fetcher will be updated
  ~ resource "aws_lambda_function" "fetcher" {
        timeout           = 60
      ~ environment       = {...}
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

### 7.5. Job 3: Apply (Main Push)

Se ejecuta en push a main. Aplica cambios reales.

```bash
terraform apply -auto-approve
```

**Comentario en PR/Issue**:
```
✅ Terraform Apply Completed

{
  "lambda_function_arn": "arn:aws:lambda:us-east-1:891377338512:function:efrouting-fetcher",
  "dynamodb_table_name": "spacex-dashboard-launches",
  ...
}
```

### 7.6. Variables de Entorno

```yaml
TF_VERSION: 1.3.0
AWS_REGION: us-east-1
```

### 7.7. Secretos Requeridos

```
AWS_ROLE_TO_ASSUME  # ARN del rol IAM
```

### 7.8. Cómo ejecutar manualmente (Local)

```bash
cd terraform

# Validar
terraform fmt -check
terraform init
terraform validate

# Planear cambios
terraform plan -out=tfplan

# Aplicar cambios
terraform apply tfplan
```

### 7.9. Ejecutar en GitHub

```bash
# Automáticamente al push a main
git add terraform/
git commit -m "Update Terraform configuration"
git push origin main
# ✅ Se valida, planea y aplica

# Manualmente
gh workflow run deploy_terraform.yml
```

---

## 8. Workflow 6: Build Docs (`build_docs.yml`)

### 8.1. Propósito

Construye documentación Markdown y la publica en GitHub Pages.

### 8.2. Triggers

```yaml
on:
  push:
    branches: [ main ]
    paths:
      - 'docs/**'
      - 'mkdocs.yml'
  workflow_dispatch:
```

### 8.3. Pasos del Workflow

```
1. Setup Python
2. Instalar MkDocs + Material theme
3. Ejecutar: mkdocs build
4. Subir artefacto a GitHub Pages
5. Desplegar a GitHub Pages
```

### 8.4. Salida

La documentación se publica automáticamente en:
```
https://jelambrar96.github.io/prueba-backend-efrouting/
```

### 8.5. Cómo ejecutar manualmente (Local)

```bash
# Instalar MkDocs
pip install mkdocs mkdocs-material

# Construir documentación
mkdocs build

# Servir localmente
mkdocs serve
# Acceder a: http://127.0.0.1:8000

# Desplegar a GitHub Pages
mkdocs gh-deploy
```

---

## 9. Matriz de Triggers

| Rama | Evento | Workflow | Acción |
|------|--------|----------|--------|
| main | push | unit_tests | ✅ Ejecuta tests |
| main | push | code_quality | ✅ Linting + seguridad |
| main | push (compute/streamlit) | build_docker_image | ✅ Build + push Docker |
| main | push (compute/lambda) | deploy_lambda | ✅ Deploy Lambda |
| main | push (terraform) | deploy_terraform | ✅ Validate → Plan → Apply |
| main | push (docs) | build_docs | ✅ Build → Deploy GitHub Pages |
| main | PR | unit_tests | ✅ Ejecuta tests |
| main | PR | code_quality | ✅ Linting + seguridad |
| main | PR (terraform) | deploy_terraform | ✅ Plan solamente (no Apply) |

---

## 10. Monitorear Workflows

### 10.1. En GitHub Web

```
GitHub → Actions → Seleccionar workflow

Verde ✅ = Éxito
Rojo ❌ = Error
Amarillo ⏳ = En progreso
```

### 10.2. Con GitHub CLI

```bash
# Listar últimas ejecuciones
gh run list --repo jelambrar96/prueba-backend-efrouting

# Ver detalles de un run
gh run view <run-id>

# Ver logs de un job
gh run view <run-id> --log

# Cancelar un run
gh run cancel <run-id>

# Rerun un workflow fallido
gh run rerun <run-id>
```

### 10.3. Con Comandos Git

```bash
# Ver commits que dispararon workflows
git log --oneline -n 10

# Ver qué cambiaste en commit
git show <commit-hash>:terraform/main.tf
```

---

## 11. Manejo de Errores

### 11.1. Tests Fallidos

```
❌ Workflow: unit_tests
Error: 1 test FAILED

Solución:
1. gh run view <run-id> --log
2. Revisar el test que falló
3. Arreglar el código localmente
4. Ejecutar tests localmente: pytest
5. Hacer push: git push
```

### 11.2. Lambda Deploy Fallido

```
❌ Workflow: deploy_lambda
Error: InvalidParameterValueException: Role is invalid

Solución:
1. Verificar secreto AWS_ROLE_TO_ASSUME
2. Confirmar que el rol existe en AWS
3. Verificar permisos IAM del rol
4. Hacer push nuevamente: git push origin main
```

### 11.3. Terraform Apply Fallido

```
❌ Workflow: deploy_terraform
Error: Error creating Lambda function: AccessDenied

Solución:
1. Revisar permisos del rol IAM
2. Ejecutar localmente: terraform plan
3. Arreglar configuración
4. Hacer push: git push
```

---

## 12. Mejores Prácticas

✅ **Hacer**:
- Crear PRs antes de mergear a main
- Revisar logs de workflows en errores
- Mantener secretos seguros en GitHub
- Usar `workflow_dispatch` para desplegues manuales
- Monitorear cobertura de tests
- Documentar cambios en commits

❌ **Evitar**:
- Pushear directamente a main sin PR
- Ignorar errores en workflows
- Hardcodear credenciales en archivos
- Mergear con tests fallidos
- Cambiar muchas cosas en un commit

---

## 13. Configuración Inicial (One-Time Setup)

### 13.1. Crear Secretos en GitHub

```bash
# En GitHub → Settings → Secrets and variables → Actions

# Crear secretos:
AWS_ROLE_TO_ASSUME=arn:aws:iam::891377338512:role/github-actions-role
LAMBDA_EXECUTION_ROLE_ARN=arn:aws:iam::891377338512:role/lambda-execution-role
```

### 13.2. Habilitar GitHub Pages

```
GitHub → Settings → Pages
Source: Deploy from a branch
Branch: gh-pages
Directory: /root
Save
```

### 13.3. Verificar Permisos de Workflow

```
GitHub → Settings → Actions → General
Workflow permissions: Read and write permissions ✅
Allow GitHub Actions to create and approve pull requests ✅
```

---

## 14. Ejemplo Completo: Ciclo de Desarrollo

### 14.1. Scenario: Actualizar función Lambda

```bash
# 1. Crear rama
git checkout -b feature/update-lambda

# 2. Hacer cambios
vi compute/lambda/app.py

# 3. Ejecutar tests localmente
cd compute/lambda/tests
pytest test_app.py -v

# 4. Hacer commit
git add compute/lambda/
git commit -m "feat: add new launch validation"

# 5. Hacer push
git push origin feature/update-lambda

# 6. Crear Pull Request en GitHub
gh pr create --title "Update Lambda function" --body "New validation"

# 7. Esperar a que se ejecuten workflows:
#    ✅ unit_tests (tests)
#    ✅ code_quality (linting)

# 8. Si todo está bien, mergear PR
gh pr merge --squash

# 9. Se ejecutan workflows en main:
#    ✅ unit_tests
#    ✅ code_quality
#    ✅ deploy_lambda (¡Despliegue automático!)

# 10. Verificar despliegue
aws lambda get-function-code-location \
  --function-name efrouting-fetcher \
  --region us-east-1
```

### 14.2. Scenario: Actualizar Terraform

```bash
# 1. Rama
git checkout -b feature/update-infra

# 2. Cambios
vi terraform/main.tf

# 3. Validar localmente
cd terraform
terraform init
terraform validate
terraform plan

# 4. Commit
git add terraform/
git commit -m "chore: update Lambda timeout"

# 5. Push
git push origin feature/update-infra

# 6. PR
gh pr create --title "Update Terraform"

# 7. Ver plan en el PR
# GitHub → PR → Revisa comentario con terraform plan

# 8. Mergear
gh pr merge --squash

# 9. Se ejecuta deploy_terraform en main:
#    ✅ Valida
#    ✅ Planea
#    ✅ Aplica cambios en AWS
```

---

## 15. Referencias

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **GitHub CLI**: https://cli.github.com/
- **Terraform GitHub Actions**: https://github.com/hashicorp/setup-terraform
- **Docker Build Action**: https://github.com/docker/build-push-action
- **AWS Credentials Action**: https://github.com/aws-actions/configure-aws-credentials
- **MkDocs**: https://www.mkdocs.org/

---

____

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/jelambrar1)

Made with Love ❤️ by [@jelambrar96](https://github.com/jelambrar96)
