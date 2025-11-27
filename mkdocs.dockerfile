FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install pip and build essentials if needed
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install mkdocs + material theme
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir mkdocs mkdocs-material

# Copy documentation source into the container
COPY mkdocs.yml ./
COPY docs/ ./docs/

# Default mkdocs serve port
EXPOSE 8000

# Entrypoint: start the development server accessible on all interfaces
ENTRYPOINT ["mkdocs", "serve", "-a", "0.0.0.0:8000"]
