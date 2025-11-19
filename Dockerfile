# Production Dockerfile for Poker Analysis Backend

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install TexasSolver (Temporarily disabled for debugging)
# RUN wget https://github.com/bupticybee/TexasSolver/releases/download/v0.2.0/TexasSolver-v0.2.0-Linux.zip && \
#     unzip TexasSolver-v0.2.0-Linux.zip && \
#     rm TexasSolver-v0.2.0-Linux.zip && \
#     mv TexasSolver-v0.2.0-Linux/TexasSolverCli /usr/local/bin/TexasSolverCli && \
#     chmod +x /usr/local/bin/TexasSolverCli && \
#     rm -rf TexasSolver-v0.2.0-Linux

# Copy requirements first for better caching
COPY backend/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code (preserve backend directory structure)
COPY backend/ backend/

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/api/health')"

# Run the application
CMD uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8000}
