# Prueba Técnica: Desarrollador Fullstack — Jelambrar96X

Este repositorio contiene una solución completa para la ingestión, procesamiento y visualización
de datos de lanzamientos espaciales (SpaceX). Está pensada como una demo profesional que muestra
prácticas de arquitectura serverless, infraestructura como código y pipelines CI/CD.

Principales componentes
- Extracción: AWS Lambda (Python) que consulta la API pública de SpaceX
- Almacenamiento: Amazon DynamoDB (tabla `spacex-dashboard-launches`)
- Visualización: Streamlit en contenedor Docker desplegado en ECS Fargate
- Orquestación / IaC: Terraform (módulos para VPC, DynamoDB, Lambda/IAM, Fargate, ECR)
- CI/CD: GitHub Actions (tests, linting, build Docker, deploy Lambda, apply Terraform, publicar docs)

Resumen breve de la documentación (`docs/`)

- `d00_introduccion.md` — Visión general, flujo de datos y razones arquitectónicas.
- `d01_datos.md` — Endpoint de SpaceX, esquema de DynamoDB, campos retenidos y transformaciones.
- `d02_solucion.md` — Diseño detallado de la solución: diagramas, IAM, Trigger (EventBridge/API Gateway), seguridad y monitoreo.
- `d03_reproducibilidad.md` — Guía paso a paso para desplegar el proyecto desde cero (prerrequisitos, Terraform, credenciales, acceso al dashboard).
- `d04_pruebas.md` — Cómo ejecutar tests unitarios y de integración para la Lambda (pytest/unittest, mocking, cobertura).
- `d05_cicd.md` — Documentación de los workflows de GitHub Actions incluidos en `.github/workflows/` y cómo ejecutarlos.
- `d06_referencias.md` — Enlaces útiles y documentación externa.
- `d07_creditos.md` — Créditos y agradecimientos.

Comandos rápidos (how-to)

1. Clonar el repositorio

```bash
git clone https://github.com/jelambrar96/prueba-backend-efrouting.git
cd prueba-backend-efrouting
```

2. Ejecutar tests de la Lambda

```bash
cd compute/lambda
pip install -r requirements.txt
pytest tests/test_app.py -v
```

3. Inicializar y aplicar Terraform (infraestructuras)

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

4. Ejecutar el dashboard localmente con Docker

```bash
docker build -t prueba-streamlit:latest compute/streamlit/
docker run -p 8501:8501 prueba-streamlit:latest
# Abrir http://localhost:8501
```

CI/CD

Los pipelines de CI/CD están en `.github/workflows/`. Los principales workflows son:

- `unit_tests.yml` — ejecuta los tests en varias versiones de Python y sube cobertura.
- `code_quality.yml` — linting (black/isort/flake8) y análisis de seguridad (bandit/safety).
- `build_docker_image.yml` — construye y publica la imagen Docker del dashboard en GHCR.
- `deploy_lambda.yml` — empaqueta, prueba y despliega la Lambda a AWS.
- `deploy_terraform.yml` — valida, planifica y aplica cambios de Terraform.
- `build_docs.yml` — construye la documentación con MkDocs y la publica en GitHub Pages.

Soporte y contacto

- Autor: @jelambrar96
- Para problemas o sugerencias, abre un Issue en el repositorio o crea un PR con mejoras.

Licencia y notas

Este proyecto es una prueba técnica y ejemplo de buenas prácticas; adapta y asegura las credenciales
antes de usar en producción. Revisa `docs/` para guías detalladas de despliegue, pruebas y seguridad.

____

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/jelambrar1)

Made with Love ❤️ by [@jelambrar96](https://github.com/jelambrar96)
