# ==============================================================================
# NOMAD JOB — Template para deploy de aplicacao single-container
#
# Este ficheiro define como a sua aplicacao e implantada no cluster.
# Copie para a raiz do seu repositorio e ajuste conforme necessario.
#
# Variaveis injetadas automaticamente pelo GitHub Actions:
#   - namespace: seu namespace isolado (ex: aluno01)
#   - image: imagem Docker construida pelo CI (ex: ghcr.io/user/repo:sha)
#
# O que voce pode personalizar:
#   - Nome do job (linha "job"): troque "my-app" pelo nome da sua aplicacao
#   - Porta (to = 8080): deve bater com o EXPOSE do Dockerfile
#   - Recursos (cpu/memory): aumente se necessario
#   - Health check (path): ajuste para a rota de saude da sua app
#   - Segredos do Vault: adicione/remova conforme sua aplicacao
# ==============================================================================

variable "namespace" {
  type        = string
  description = "Namespace do estudante (injetado pelo CI)"
}

variable "image" {
  type        = string
  description = "Imagem Docker (injetada pelo CI)"
  default     = "nginx:alpine"
}

# PERSONALIZE: troque "my-app" pelo nome da sua aplicacao (sem espacos)
job "my-app" {
  datacenters = ["dc1"]
  namespace   = var.namespace
  type        = "service"

  # --- Estrategia de update (zero-downtime) ---
  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    auto_revert       = true
    auto_promote      = true
    canary            = 1
  }

  group "app" {
    count = 1

    # --- Rede em modo bridge (isolada via Consul Connect) ---
    network {
      mode = "bridge"
      port "http" {
        to = 8080   # PERSONALIZE: porta onde sua aplicacao escuta
      }
    }

    # --- Service Mesh (Consul Connect) ---
    service {
      # IMPORTANTE: o nome DEVE comecar com seu namespace
      # Exemplo: aluno01-app
      name = "${var.namespace}-app"
      port = "http"
      tags = ["student", var.namespace]

      connect {
        sidecar_service {
          proxy {
            local_service_port = 8080  # Mesma porta do "to" acima
            config {
              protocol = "http"
            }
          }
        }
      }

      # --- Health Check ---
      # O Nomad verifica periodicamente se a aplicacao esta saudavel.
      # Se falhar, o container e reiniciado automaticamente.
      check {
        name     = "HTTP Health"
        type     = "http"
        path     = "/"               # PERSONALIZE: rota de saude (ex: "/health")
        interval = "10s"
        timeout  = "3s"
      }
    }

    # --- Restart e Reschedule ---
    restart {
      attempts = 3
      interval = "5m"
      delay    = "15s"
      mode     = "fail"
    }

    reschedule {
      attempts       = 3
      interval       = "30m"
      delay          = "15s"
      delay_function = "exponential"
      max_delay      = "2m"
      unlimited      = false
    }

    task "app" {
      driver = "docker"

      # --- Recursos alocados para o container ---
      # PERSONALIZE: aumente se sua aplicacao precisar de mais recursos
      #   Node.js simples: cpu=200, memory=128
      #   Spring Boot:     cpu=500, memory=512
      #   Python/Flask:    cpu=200, memory=256
      resources {
        cpu    = 200   # MHz
        memory = 256   # MB
      }

      # --- Workload Identity: Acesso automatico ao Vault ---
      # Permite que o Nomad injete segredos do Vault no container
      identity {
        name        = "vault_default"
        aud         = ["vault.io"]
        ttl         = "1h"
        env         = true
        file        = true
        change_mode = "restart"
      }

      vault {
        role = "student-${var.namespace}-role"
      }

      # --- Segredos do Vault injetados como variaveis de ambiente ---
      # PERSONALIZE: ajuste os nomes dos segredos conforme sua aplicacao.
      # Os segredos sao definidos nos GitHub Secrets e escritos no Vault
      # automaticamente pelo workflow de deploy.
      #
      # Para adicionar um novo segredo:
      #   1. Crie o GitHub Secret (ex: APP_MY_SECRET)
      #   2. Adicione no deploy.yml na secao vault-secrets
      #   3. Adicione aqui: MY_SECRET={{ .Data.data.my_secret }}
      template {
        data = <<EOH
{{ with secret "secret/data/students/${var.namespace}/app" }}
DB_PASSWORD={{ .Data.data.db_password }}
API_KEY={{ .Data.data.api_key }}
{{ end }}
EOH
        destination = "secrets/app.env"
        env         = true
        change_mode = "restart"
      }

      # --- Imagem Docker ---
      config {
        image = var.image
        ports = ["http"]
      }
    }
  }
}
