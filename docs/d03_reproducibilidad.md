# Reproducibilidad y Guía de Despliegue

Esta guía te permite desplegar el proyecto **Jelambrar96X** desde cero en tu propia cuenta de AWS. Toda la infraestructura está definida como código (Terraform), lo que garantiza reproducibilidad y consistencia.

---

## 1. Descargar el Repositorio

El código fuente está alojado en GitHub. Descárgalo en tu máquina local:

```bash
git clone https://github.com/jelambrar96/prueba-backend-efrouting
cd prueba-backend-efrouting
```

**Estructura del repositorio**:
```
prueba-backend-efrouting/
├── compute/
│   ├── lambda/              # Función Lambda para extracción de datos
│   │   ├── app.py          # Handler principal
│   │   ├── requirements.txt # Dependencias Python
│   │   ├── build.sh        # Script de empaquetamiento
│   │   └── tests/          # Tests unitarios
│   └── streamlit/          # Dashboard web
│       ├── app.py          # Aplicación Streamlit
│       ├── Dockerfile      # Imagen Docker
│       ├── requirements.txt
│       └── build_and_push.sh
├── terraform/              # Infraestructura como Código
│   ├── main.tf            # Orquestación de módulos
│   ├── variables.tf       # Variables globales
│   ├── outputs.tf         # Salidas (IPs, ARNs, etc.)
│   └── modules/           # Módulos reutilizables
│       ├── dynamodb/      # Base de datos
│       ├── lambda_iam/    # Lambda + IAM + EventBridge
│       ├── fargate/       # ECS Fargate + ECR
│       ├── networking/    # VPC + Subnets + Security Groups
│       └── docker_ecr_push/ # Automatización Docker
├── docs/                  # Documentación
└── README.md
```

---

## 2. Requisitos Previos

### 2.1. Crear Cuenta en AWS

1. Accede a https://aws.amazon.com/
2. Haz clic en **"Create an AWS Account"**
3. Completa el formulario con:
   - Email válido
   - Nombre de la cuenta
   - Tarjeta de crédito (requiere verificación)
4. Selecciona el plan **"Free Tier"** (incluye $1 de crédito gratis)
5. Confirma tu identidad por teléfono

✅ **Nota**: El proyecto usa servicios gratuitos (Lambda, DynamoDB on-demand, Fargate). Costo estimado: **$5-15 USD/mes** en producción.

### 2.2. Instalar Herramientas Necesarias

#### Terraform

**En macOS (Homebrew)**:
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version  # Verifica: v1.5.0+
```

**En Linux**:
```bash
# Descargar
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version
```

**En Windows**:
- Descargar desde https://www.terraform.io/downloads
- Agregar al PATH de sistema
- Verificar en PowerShell: `terraform version`

#### Docker

**En macOS**:
```bash
brew install docker
# O descargar Docker Desktop desde https://www.docker.com/products/docker-desktop
docker version
```

**En Linux**:
```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
docker version
```

**En Windows**:
- Descargar Docker Desktop desde https://www.docker.com/products/docker-desktop
- Instalar y reiniciar

#### AWS CLI v2

**En macOS**:
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version
```

**En Linux**:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

**En Windows**:
- Descargar desde https://awscli.amazonaws.com/AWSCLIV2.msi
- Ejecutar el instalador
- Verificar: `aws --version`

---

## 3. Configurar Credenciales AWS

### 3.1. Crear Usuario IAM (en AWS Console)

1. Accede a AWS Console: https://console.aws.amazon.com/
2. Navega a **IAM → Users → Create User**
3. Nombre: `efrouting-user`
4. Marca: **"Provide user access to the AWS Management Console"**
5. Asigna permisos: Adjunta la política **AdministratorAccess** (para desarrollo)
6. **Descarga las credenciales** (las necesitarás después)

**Credenciales obtenidas**:
```
AWS_ACCESS_KEY_ID = tu_id_secreto
AWS_SECRET_ACCESS_KEY = tu_llave_secreta
```

⚠️ **Advertencia**: Guarda estas credenciales de forma segura. No las compartas ni las comitees a Git.

### 3.2. Configurar Perfil en AWS CLI

Ejecuta el comando de configuración con el profile `nombre`:

```bash
aws configure --profile nombre
```

Te pedirá:
```
AWS Access Key ID [None]: tu_id_secreto
AWS Secret Access Key [None]: tu_llave_secreta
Default region name [None]: us-east-1
Default output format [None]: json
```

✅ Las credenciales se guardan en `~/.aws/credentials`:
```
[nombre]
aws_access_key_id = tu_llave_secreta
aws_secret_access_key = tu_llave_secreta
```

Verifica la configuración:
```bash
aws sts get-caller-identity --profile nombre
```

Debe mostrar algo como:
```json
{
    "UserId": "AIDAI...",
    "Account": "numero_cuenta",
    "Arn": "arn:aws:iam::numero_cuenta:user/nombre-user"
}
```

---

## 4. Desplegar Infraestructura con Terraform

### 4.1. Navegar al Directorio Terraform

```bash
cd prueba-backend-efrouting/terraform
```

### 4.2. Inicializar Terraform

Este comando descargar los providers necesarios (AWS, null, archive):

```bash
terraform init
```

Salida esperada:
```
Initializing the backend...
Initializing modules...
Downloading ... 
- dynamodb in modules/dynamodb
- fargate in modules/fargate
- lambda_iam in modules/lambda_iam
- networking in modules/networking
- docker_ecr_push in modules/docker_ecr_push

Terraform has been successfully initialized!
```

### 4.3. Revisar el Plan de Despliegue

Antes de crear recursos, revisa qué se va a crear:

```bash
terraform plan -out=tfplan
```

Este comando mostrará:
- 🔴 Recursos a crear (líneas con `+`)
- 🟡 Recursos a modificar (líneas con `~`)
- 🟢 Recursos a destruir (líneas con `-`)

Ejemplo de salida:
```
Plan: 45 to add, 0 to change, 0 to destroy.

Saved the plan to: tfplan
```

**Revisa el plan cuidadosamente** antes de proceder.

### 4.4. Aplicar la Configuración

Ejecuta el apply para crear toda la infraestructura:

```bash
terraform apply tfplan
```

**Duración estimada**: 5-10 minutos

**Proceso**:
1. Crea VPC, Subnets, Internet Gateway, NAT Gateway
2. Crea tabla DynamoDB
3. Crea rol IAM y permisos para Lambda
4. Empaqueta Lambda con dependencias (`build.sh`)
5. Crea función Lambda y EventBridge scheduling
6. Crea repositorio ECR
7. Construye imagen Docker de Streamlit (local)
8. Envía imagen a ECR (`docker push`)
9. Crea cluster ECS, task definition y service
10. Asigna IP pública a la tarea Fargate

**Salida esperada al final**:
```
Apply complete! Resources have been created.

Outputs:

dynamodb_table_arn = "arn:aws:dynamodb:us-east-1:numero-asignado:table/spacex-dashboard-launches"
dynamodb_table_name = "spacex-dashboard-launches"
ecr_repository_url = "numero-asignado.dkr.ecr.us-east-1.amazonaws.com/spacex-dashboard-streamlit"
ecs_cluster_arn = "arn:aws:ecs:us-east-1:numero-asignado:cluster/spacex-dashboard"
ecs_service_name = "spacex-dashboard-service"
lambda_function_arn = "arn:aws:lambda:us-east-1:numero-asignado:function:spacex-dashboard-fetcher"
lambda_function_name = "spacex-dashboard-fetcher"
vpc_id = "vpc-0123456789abcdef0"
```

Guarda estos valores para referencias futuras.

---

## 5. Acceder al Dashboard

### 5.1. Obtener IP Pública desde AWS Console (Recomendado)

1. Accede a AWS Console: https://console.aws.amazon.com/
2. Navega a **ECS → Clusters → spacex-dashboard**
3. Haz clic en la pestaña **Services**
4. Selecciona **spacex-dashboard-service**
5. Haz clic en la pestaña **Tasks**
6. Abre la tarea (unique ID)
7. Desplázate hasta **Network** → busca **Public IP** (ejemplo: `52.123.45.67`)
8. Abre en navegador: `http://52.123.45.67:8501`

### 5.2. Obtener IP Pública desde CLI

```bash
# 1. Listar tasks en el service
aws ecs list-tasks \
  --cluster spacex-dashboard \
  --service-name spacex-dashboard-service \
  --region us-east-1 \
  --profile nombre

# Resultado: arn:aws:ecs:us-east-1:numero-asignado:task/spacex-dashboard/abc123def456

# 2. Describir la task para obtener ENI
aws ecs describe-tasks \
  --cluster spacex-dashboard \
  --tasks arn:aws:ecs:us-east-1:numero-asignado:task/spacex-dashboard/abc123def456 \
  --region us-east-1 \
  --profile nombre

# 3. Buscar la IP pública en la salida (networkInterfaceId)
# Copiar el ENI ID: eni-0123456789abcdef0

# 4. Obtener IP pública del ENI
aws ec2 describe-network-interfaces \
  --network-interface-ids eni-0123456789abcdef0 \
  --region us-east-1 \
  --profile nombre \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text

# Resultado: 52.123.45.67
```

Abre en navegador: `http://52.123.45.67:8501`

✅ Deberías ver el **Dashboard de Streamlit** con gráficos interactivos.

---

## 6. Usar la API Gateway para Descargar Datos Personalizados

Además de la descarga automática cada 6 horas, puedes descargar datos de un rango de fechas específico usando la API Gateway.

### 6.1. Obtener URL de la API

```bash
# En la carpeta terraform/
terraform output api_endpoint

# O desde AWS Console:
# 1. Navega a API Gateway → spacex-dashboard-api
# 2. Copia el "Invoke URL"
```

**Formato de URL**:
```
https://<api-id>.execute-api.us-east-1.amazonaws.com/fetch
```

### 6.2. Enviar Solicitud POST

Usa `curl` para enviar una solicitud con rango de fechas:

```bash
curl -X POST https://<api-id>.execute-api.us-east-1.amazonaws.com/fetch \
  -H "Content-Type: application/json" \
  -d '{
    "utc_date": "2025-11-27T12:00:00Z",
    "offset_seconds": 86400
  }' | jq
```

**Parámetros**:
- `utc_date` (ISO8601): Fecha final del rango (predeterminado: ahora)
- `offset_seconds` (número): Segundos hacia atrás desde `utc_date` (predeterminado: 21600 = 6 horas)

**Ejemplos**:

1. **Últimas 24 horas**:
   ```bash
   curl -X POST https://<api-id>.execute-api.us-east-1.amazonaws.com/fetch \
     -H "Content-Type: application/json" \
     -d '{"offset_seconds": 86400}'
   ```

2. **Rango específico** (2025-11-20 al 2025-11-27):
   ```bash
   curl -X POST https://<api-id>.execute-api.us-east-1.amazonaws.com/fetch \
     -H "Content-Type: application/json" \
     -d '{
       "utc_date": "2025-11-27T23:59:59Z",
       "offset_seconds": 604800
     }'
   ```
   (604800 segundos = 7 días)

3. **Usando Python**:
   ```python
   import requests
   import json

   url = "https://<api-id>.execute-api.us-east-1.amazonaws.com/fetch"
   payload = {
       "utc_date": "2025-11-27T12:00:00Z",
       "offset_seconds": 86400
   }

   response = requests.post(url, json=payload)
   result = response.json()
   print(f"Lanzamientos insertados: {result['inserted_items']}")
   ```

### 6.3. Respuesta de la API

**Exitosa** (HTTP 200):
```json
{
  "statusCode": 200,
  "body": "{\"inserted_items\": 7, \"start_time\": \"2025-11-26T12:00:00+00:00\", \"end_time\": \"2025-11-27T12:00:00+00:00\"}"
}
```

**Error** (HTTP 400):
```json
{
  "statusCode": 400,
  "body": "{\"error\": \"Formato de fecha no válido: ...\"}"
}
```

### 6.4. Verificar Datos en DynamoDB

Desde AWS Console:
1. Navega a **DynamoDB → Tables → spacex-dashboard-launches**
2. Haz clic en **Explore Table Items**
3. Verifica que los nuevos ítems están presentes (ordenados por `launch_date`)

---

## 7. Destruir la Infraestructura

Cuando termines o quieras limpiar los recursos (para evitar cargos), destruye toda la infraestructura:

```bash
cd prueba-backend-efrouting/terraform

terraform destroy
```

⚠️ **Confirmación**: Terraform te pide confirmación:
```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: 
```

Escribe `yes` para confirmar.

**Proceso de destrucción** (~2-5 minutos):
1. Elimina ECS Service (detiene las tareas)
2. Elimina ECS Cluster y Task Definition
3. Elimina repositorio ECR (vacía imágenes)
4. Elimina función Lambda
5. Elimina tabla DynamoDB
6. Elimina VPC, Subnets, Internet Gateway, NAT Gateway
7. Elimina roles IAM y políticas

✅ Salida esperada:
```
Destroy complete! Resources have been destroyed.
```

Verifica en AWS Console que no quedan recursos (DynamoDB, Lambda, ECS, VPC, etc.).

---

## 8. Flujo de Datos Completo

```
1. Descarga Automática (EventBridge cron: 01:00, 07:00, 13:00, 19:00 UTC)
   └─ EventBridge trigger → Lambda
   
2. Descarga Manual (API Gateway)
   └─ POST /fetch (con parámetros de rango) → Lambda
   
3. Lambda (spacex-dashboard-fetcher)
   ├─ Consulta API de SpaceX
   ├─ Transforma datos
   └─ Escribe en DynamoDB (batch)
   
4. DynamoDB (spacex-dashboard-launches)
   └─ Almacena ítems con id + launch_date
   
5. Streamlit Dashboard (ECS Fargate)
   ├─ Lee datos de DynamoDB
   ├─ Renderiza gráficos (Plotly)
   └─ Mostrado en puerto 8501
   
6. Usuario
   └─ Accede a http://<IP>:8501 desde navegador
```

---

## 9. Troubleshooting

### Lambda no se dispara automáticamente

**Síntomas**: No hay nuevos lanzamientos en DynamoDB a las horas programadas.

**Solución**:
```bash
# 1. Verifica que la regla EventBridge está activa
aws events list-rules --region us-east-1 --profile nombre

# 2. Verifica que Lambda tiene permiso
aws lambda get-policy \
  --function-name spacex-dashboard-fetcher \
  --region us-east-1 \
  --profile nombre

# 3. Revisa logs de Lambda
aws logs tail /aws/lambda/spacex-dashboard-fetcher \
  --region us-east-1 \
  --profile nombre \
  --follow
```

### Fargate Task no se inicia

**Síntomas**: ECS Service muestra "Running 0 of 1"

**Solución**:
```bash
# 1. Revisa logs de la tarea
aws logs tail /ecs/spacex-dashboard-task \
  --region us-east-1 \
  --profile nombre \
  --follow

# 2. Verifica que el security group permite puerto 8501
aws ec2 describe-security-groups \
  --region us-east-1 \
  --profile nombre

# 3. Reinicia el servicio
aws ecs update-service \
  --cluster spacex-dashboard \
  --service spacex-dashboard-service \
  --force-new-deployment \
  --region us-east-1 \
  --profile nombre
```

### No puedo conectarme a DynamoDB desde Lambda

**Síntomas**: Error "User is not authorized to perform: dynamodb:BatchWriteItem"

**Solución**: Verifica que el rol IAM tiene permisos:
```bash
aws iam get-role-policy \
  --role-name spacex-dashboard_lambda_role \
  --policy-name spacex-dashboard-launches-lambda-policy \
  --profile nombre
```

---

## 10. Próximos Pasos

1. **Monitoreo**: Configura CloudWatch Dashboards y Alertas
2. **Seguridad**: Agregar HTTPS al ALB con certificado ACM
3. **Escalabilidad**: Ajustar Auto Scaling Groups según demanda
4. **CI/CD**: Integrar GitHub Actions para despliegues automáticos
5. **Datos históricos**: Configurar backup en S3 con Lifecycle Policies

---

## 11. Referencias

- **AWS Documentation**: https://docs.aws.amazon.com/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **SpaceX API**: https://docs.spacexdata.com/
- **Streamlit Docs**: https://docs.streamlit.io/
- **GitHub Repo**: https://github.com/jelambrar96/prueba-backend-efrouting

---

**¿Problemas? Abre un issue en GitHub**: https://github.com/jelambrar96/prueba-backend-efrouting/issues

____

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/jelambrar1)

Made with Love ❤️ by [@jelambrar96](https://github.com/jelambrar96)
