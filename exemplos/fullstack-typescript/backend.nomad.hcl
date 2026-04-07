# ==============================================================================
# NOMAD JOB — Backend Express + TypeScript + Prisma (API REST + JWT)
# ==============================================================================

variable "namespace" {
  type        = string
  description = "Namespace do estudante"
}

variable "image" {
  type        = string
  description = "Imagem Docker do backend"
  default     = "ghcr.io/ifsul-sapucaia/exemplo-backend-ts:latest"
}

job "backend" {
  datacenters = ["dc1"]
  namespace   = var.namespace
  type        = "service"

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    auto_revert       = true
    auto_promote      = true
    canary            = 1
  }

  group "api" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
    }

    service {
      name = "${var.namespace}-backend"
      port = "http"
      tags = ["student", var.namespace, "api", "typescript"]

      connect {
        sidecar_service {
          proxy {
            local_service_port = 8080
            config {
              protocol = "http"
            }
            upstreams {
              destination_name = "${var.namespace}-mysql"
              local_bind_port  = 3306
            }
          }
        }
      }

      check {
        name     = "Express Health"
        type     = "http"
        path     = "/health"
        interval = "15s"
        timeout  = "3s"
      }
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "15s"
      mode     = "fail"
    }

    task "api" {
      driver = "docker"

      resources {
        cpu    = 200
        memory = 256
      }

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

      template {
        data = <<EOH
{{ with secret "secret/data/students/${var.namespace}/app" }}
DATABASE_URL=mysql://taskapi:{{ .Data.data.db_password }}@127.0.0.1:3306/taskdb
JWT_SECRET={{ .Data.data.jwt_secret }}
{{ end }}
PORT=8080
EOH
        destination = "secrets/app.env"
        env         = true
        change_mode = "restart"
      }

      config {
        image = var.image
        ports = ["http"]
      }
    }
  }
}
