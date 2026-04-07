# ==============================================================================
# Dockerfile — Backend Express + TypeScript + Prisma
#
# Hardening aplicado:
#   - Multi-stage build: TypeScript compila no builder, runtime so tem JS
#   - Usuario nao-root: roda como "node" (UID 1000)
#   - Signal handling: tini como init process (PID 1)
#   - Prisma: migrations aplicadas no entrypoint
#   - HEALTHCHECK: Docker monitora saude do container
# ==============================================================================

FROM node:22-alpine AS builder
WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --no-fund --no-audit
RUN npx prisma generate

COPY tsconfig.json ./
COPY src ./src/
RUN npx tsc

# --- Runtime ---
FROM node:22-alpine
RUN apk add --no-cache tini
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev --no-fund --no-audit

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY prisma ./prisma/

USER node
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["tini", "--"]
CMD ["sh", "-c", "npx prisma db push --skip-generate && node dist/server.js"]
