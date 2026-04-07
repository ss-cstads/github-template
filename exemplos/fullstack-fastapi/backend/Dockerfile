# ==============================================================================
# Dockerfile — Backend FastAPI (Python)
#
# Hardening aplicado:
#   - Multi-stage build: dependencias compiladas no builder, runtime limpo
#   - Usuario nao-root: roda como "appuser" (sem privilegios, sem shell)
#   - Sem cache do pip e sem bytecode: imagem menor e mais segura
#   - Output sem buffer: logs aparecem imediatamente no Nomad
#   - HEALTHCHECK: Docker monitora saude do container
# ==============================================================================

FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Runtime ---
FROM python:3.12-slim
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY --from=builder /install /usr/local
RUN useradd --no-create-home --shell /usr/sbin/nologin appuser

COPY --chown=appuser:appuser . .

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
