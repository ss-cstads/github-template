# ==============================================================================
# Multi-stage build: Node (compilacao Angular) + Nginx (servidor web)
#
# Boas praticas aplicadas:
#   - Multi-stage build: imagem final contem apenas o Nginx e os arquivos estaticos
#   - Usuario nao-root: Nginx roda como "nginx" (usuario padrao da imagem)
#   - .dockerignore: node_modules e dist nao entram no build context
#   - Sem codigo-fonte no runtime: apenas HTML, CSS e JS compilados
#   - Imagem Alpine: superficie de ataque minima (~40MB)
# ==============================================================================

# --- Stage 1: Build Angular ---
FROM node:22-alpine AS build
WORKDIR /app

# Copiar manifesto de dependencias primeiro (cache de camadas)
COPY package*.json ./
RUN npm install --no-fund --no-audit

# Copiar codigo-fonte e compilar
COPY . .
RUN npx ng build --configuration=production

# --- Stage 2: Servir com Nginx ---
FROM nginx:alpine

# Copiar apenas os arquivos estaticos compilados
COPY --from=build /app/dist/task-frontend /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
