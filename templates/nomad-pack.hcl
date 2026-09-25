# ==============================================================================
# DEPLOY PELO NOMAD PACK — copie para a raiz do repositorio como nomad-pack.hcl
#
# O pipeline usa o pack "web_app" (aplicacao publica em
# https://<seu-namespace>.projetos.sapucaia.ifsul.edu.br). Para outro pack
# (api, mysql), crie a Variable NOMAD_PACK no repositorio.
#
# O CI preenche sozinho: namespace e image. Ajuste abaixo so o que precisar;
# linhas comentadas usam o valor padrao.
# Todas as opcoes, com descricao: packs/<pack>/variables.hcl em
# https://github.com/ss-cstads/nomad-packs
# ==============================================================================

# Porta em que sua aplicacao escuta dentro do container (EXPOSE do Dockerfile)
port = 8080

# Rota que responde 2xx quando a aplicacao esta saudavel
health_path = "/"

# Recursos. Referencia: Node.js 200/128 | Python 200/256 | Spring Boot 500/512
# cpu    = 200   # MHz
# memory = 256   # MB

# Variaveis de ambiente NAO secretas
# env = {
#   NODE_ENV = "production"
# }

# Segredos do Vault (secret/students/<namespace>/app), viram env em MAIUSCULAS:
# db_password -> DB_PASSWORD. Escreva-os ativando SYNC_VAULT_SECRETS no workflow.
# vault_secrets = ["db_password", "api_key"]

# Acesso a sua API (pack api) em 127.0.0.1:8080 via service mesh
# backend_upstream = true
