FROM python:3.12-slim

WORKDIR /app

# Instala dependencias del sistema necesarias para algunas librerías de Python
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copia requirements.txt e instala dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia la aplicación Streamlit
COPY app.py .

# Expone el puerto por defecto de Streamlit
EXPOSE 8501

# Configuración de Streamlit para ejecutarse en container
ENV STREAMLIT_SERVER_HEADLESS=true
ENV STREAMLIT_SERVER_PORT=8501
ENV STREAMLIT_SERVER_ADDRESS=0.0.0.0

# Comando para ejecutar la aplicación
CMD ["streamlit", "run", "app.py"]
