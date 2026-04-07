# ==============================================================================
# Dockerfile — Frontend Angular + Nginx
#
# Hardening aplicado:
#   - Multi-stage build: imagem final contem apenas Nginx + arquivos estaticos
#   - Sem codigo-fonte no runtime: apenas HTML, CSS e JS compilados
#   - .dockerignore: node_modules e dist nao entram no build context
#   - Imagem Alpine: superficie de ataque minima (~40MB)
#   - HEALTHCHECK: Docker monitora saude do container
# ==============================================================================

# --- Build ---
FROM node:22-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm install --no-fund --no-audit

COPY . .
RUN npx ng build --configuration=production

# --- Runtime ---
FROM nginx:alpine

COPY --from=build /app/dist/task-frontend /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
