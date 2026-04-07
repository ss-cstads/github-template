# ==============================================================================
# NOMAD JOB — Template para estudantes
#
# Este ficheiro define como a sua aplicacao e implantada no cluster.
# Personalize conforme necessario (portas, recursos, health checks).
#
# Variaveis injetadas automaticamente pelo GitHub Actions:
#   - namespace: seu namespace isolado
#   - image: imagem Docker construida pelo CI
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

    # --- Rede em modo bridge (isolada) ---
    network {
      mode = "bridge"
      port "http" {
        to = 8080   # Porta onde a sua aplicacao escuta DENTRO do container
      }
    }

    # --- Service Mesh (Consul Connect) ---
    service {
      # IMPORTANTE: O nome do servico DEVE comecar com seu namespace
      # Exemplo: aluno01-app
      name = "${var.namespace}-app"
      port = "http"

      tags = ["student", var.namespace]

      connect {
        sidecar_service {
          proxy {
            local_service_port = 8080
            config {
              protocol = "http"
            }
          }
        }
      }

      # --- Health Check ---
      check {
        name     = "HTTP Health"
        type     = "http"
        path     = "/"
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

      # --- Recursos ---
      resources {
        cpu    = 200   # MHz
        memory = 128   # MB
      }

      # --- Workload Identity: Acesso automatico ao Vault ---
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

      # --- Template: Injetar segredos do Vault como variaveis de ambiente ---
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
