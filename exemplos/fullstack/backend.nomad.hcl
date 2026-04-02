# ==============================================================================
# NOMAD JOB — Backend Spring Boot (API REST + Spring Security)
#
# API REST com autenticacao JWT, conecta ao MySQL via Consul Connect.
# Segredos (senha do banco, chave JWT) injetados via Vault Workload Identity.
# ==============================================================================

variable "namespace" {
  type        = string
  description = "Namespace do estudante"
}

variable "image" {
  type        = string
  description = "Imagem Docker do backend"
  default     = "ghcr.io/ifsul-sapucaia/exemplo-backend:latest"
}

job "backend" {
  datacenters = ["dc1"]
  namespace   = var.namespace
  type        = "service"

  update {
    max_parallel      = 1
    min_healthy_time  = "15s"
    healthy_deadline  = "5m"
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

    # --- Service: backend acessivel como <namespace>-backend ---
    service {
      name = "${var.namespace}-backend"
      port = "http"
      tags = ["student", var.namespace, "api", "spring-boot"]

      connect {
        sidecar_service {
          proxy {
            local_service_port = 8080
            config {
              protocol = "http"
            }

            # Upstream: conexao com o MySQL via service mesh
            upstreams {
              destination_name = "${var.namespace}-mysql"
              local_bind_port  = 3306
            }
          }
        }
      }

      check {
        name     = "Spring Boot Actuator"
        type     = "http"
        path     = "/actuator/health"
        interval = "15s"
        timeout  = "5s"
      }
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "20s"
      mode     = "fail"
    }

    task "api" {
      driver = "docker"

      resources {
        cpu    = 500   # MHz
        memory = 512   # MB
      }

      # --- Workload Identity ---
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

      # Segredos e configuracao injetados via Vault
      template {
        data = <<EOH
{{ with secret "secret/data/students/${var.namespace}/app" }}
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/taskdb?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
SPRING_DATASOURCE_USERNAME=taskapi
SPRING_DATASOURCE_PASSWORD={{ .Data.data.db_password }}
JWT_SECRET={{ .Data.data.jwt_secret }}
{{ end }}
SPRING_DATASOURCE_DRIVER_CLASS_NAME=com.mysql.cj.jdbc.Driver
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT=org.hibernate.dialect.MySQLDialect
SERVER_PORT=8080
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
