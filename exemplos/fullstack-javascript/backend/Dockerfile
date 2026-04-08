# ==============================================================================
# Dockerfile — Backend Express.js
#
# Hardening aplicado:
#   - Multi-stage build: separa instalacao de dependencias do runtime
#   - Usuario nao-root: roda como "node" (UID 1000)
#   - Signal handling: tini como init process (PID 1)
#   - Apenas dependencias de producao na imagem final
#   - HEALTHCHECK: Docker monitora saude do container
# ==============================================================================

FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev --no-fund --no-audit

# --- Runtime ---
FROM node:22-alpine
RUN apk add --no-cache tini
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY --chown=node:node . .

USER node
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["tini", "--"]
CMD ["node", "server.js"]
