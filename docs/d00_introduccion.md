# Introducción

## Resumen

**Jelambrar96X** consiste en un sistema que obtiene información de lanzamientos espaciales desde la API pública de SpaceX y los muestra a través de una aplicación Web. Este sistema implementa servicios de AWS para la extracción, almacenamiento y visualización de los datos, todo automatizado y orquestado mediante **Terraform** como herramienta de Infraestructura como Código (IaC).

## Flujo de Datos

El proyecto implementa una arquitectura moderna y escalable basada en eventos, donde el flujo de datos sigue este camino:

```
SpaceX API
    ↓
AWS Lambda (Extractor)
    ↓
Amazon DynamoDB (Almacenamiento)
    ↓
Streamlit Dashboard (Visualización)
```

### Detalles del Flujo

1. **Fuente de Datos - SpaceX API**
   - Se conecta a la API pública de SpaceX para obtener información en tiempo real de lanzamientos espaciales.
   - Incluye datos como: ID del lanzamiento, fecha, sitio de lanzamiento, cargas útiles, tripulación, estado de cohete y más.

2. **Extracción y Procesamiento - AWS Lambda**
   - Función serverless en Python que se ejecuta automáticamente 4 veces al día (01:00, 07:00, 13:00, 19:00 UTC).
   - Llamadas programadas mediante **EventBridge** (antiguo CloudWatch Events).
   - También permite invocación manual desde **API Gateway**.
   - Valida, normaliza y transforma los datos en formato JSON.
   - Utiliza **boto3** para interactuar con AWS Services.

3. **Almacenamiento - Amazon DynamoDB**
   - Base de datos NoSQL serverless que almacena los registros de lanzamientos.
   - Tabla `spacex-dashboard-launches` con particionamiento por ID de lanzamiento.
   - Incluye un Índice Secundario Global (GSI) para consultas por fecha de lanzamiento.
   - Configurada en modo de facturación **PAY_PER_REQUEST** (paga solo por lo que usas).
   - Recuperación de punto en tiempo (PITR) habilitada para backup y recuperación.

4. **Visualización - Streamlit Dashboard**
   - Aplicación web interactiva desarrollada en Python con **Streamlit**.
   - Corre en un contenedor Docker desplegado en **Amazon ECS Fargate**.
   - Realiza consultas en tiempo real a DynamoDB.
   - Muestra gráficos interactivos con **Plotly**: lanzamientos por mes, por sitio, línea de tiempo, estado de misiones.
   - Expuesta en el puerto **8501** a través de un balanceador de carga.

### Servicios AWS Utilizados

- **AWS Lambda**: Computación serverless para la extracción de datos.
- **Amazon DynamoDB**: Base de datos NoSQL altamente escalable.
- **Amazon EventBridge**: Programación automática de tareas (cron scheduling).
- **API Gateway v2**: Endpoint REST para invocación manual de Lambda.
- **Amazon ECS Fargate**: Orquestación de contenedores sin servidor.
- **Amazon ECR (Elastic Container Registry)**: Registro privado de imágenes Docker.
- **Amazon VPC**: Red virtual privada con subnets públicas y privadas.
- **AWS IAM**: Control de acceso y permisos entre servicios.
- **Amazon CloudWatch**: Logs y monitoreo de funciones Lambda y tareas ECS.
- **Amazon QuickSight**: (Opcional) Inteligencia de negocios y análisis visual de datos.

## Infraestructura como Código con Terraform

El proyecto completo está definido como **código** utilizando **Terraform**, una herramienta de código abierto que permite provisionar y gestionar infraestructura en AWS de forma versionable, reproducible y colaborativa.

## Ventajas de Terraform frente a Otras Herramientas de IaC

### Terraform vs. CloudFormation (AWS)

| Aspecto | Terraform | CloudFormation |
|--------|-----------|----------------|
| **Multi-cloud** | ✅ Soporta AWS, Azure, GCP, Kubernetes, etc. | ❌ Solo AWS |
| **Lenguaje** | HCL (legible y declarativo) | JSON/YAML (más verbose) |
| **Curva de aprendizaje** | 📊 Media (HCL es intuitivo) | 📈 Más pronunciada (sintaxis compleja) |
| **Reutilización** | ✅ Módulos nativos y bien documentados | ⚠️ Nested stacks más complejos |
| **Estado** | 📋 Archivo de estado explícito (mejor control) | 🔄 Implícito (menos visible) |
| **Comunidad** | 🌍 Grande, activa, muchas herramientas | 📚 Principalmente proveedores AWS |


## Razones Clave para Usar Terraform en Este Proyecto

1. **Multi-cloud listo**: Si en el futuro queremos expandir a Azure o GCP, Terraform lo permite nativamente.
2. **Versionado y auditable**: Todo está en Git, vemos exactamente qué cambió en cada commit.
3. **Reproducibilidad**: Otros desarrolladores o equipos pueden desplegar la infraestructura idéntica ejecutando `terraform apply`.
4. **Modularidad**: Cada componente (networking, database, compute) está aislado y puede reutilizarse.
5. **Estado controlado**: El archivo `terraform.tfstate` actúa como fuente de verdad de lo que existe en AWS.
6. **Integración DevOps**: Se integra perfectamente con pipelines CI/CD (GitHub Actions, GitLab CI, Jenkins).
7. **Comunidad activa**: Millones de ejemplos, módulos públicos y soporte comunitario.
8. **Costo de infraestructura**: Pay-as-you-go con DynamoDB serverless, Lambda, Fargate (sin servidores dedicados).

____

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/jelambrar1)

Made with Love ❤️ by [@jelambrar96](https://github.com/jelambrar96)
