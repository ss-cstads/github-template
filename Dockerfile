# ==============================================================================
# DOCKERFILE — Exemplo para estudantes
#
# Personalize este ficheiro para a sua aplicacao.
# A porta DEVE corresponder a definida em job.nomad.hcl (default: 8080)
# ==============================================================================

FROM node:20-alpine

WORKDIR /app

# Copiar dependencias
COPY package*.json ./
RUN npm ci --production 2>/dev/null || true

# Copiar codigo da aplicacao
COPY . .

# Porta onde a aplicacao escuta (deve bater com job.nomad.hcl)
EXPOSE 8080

# Comando de inicio
CMD ["node", "server.js"]
