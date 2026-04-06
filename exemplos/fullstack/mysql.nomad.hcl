# ==============================================================================
# NOMAD JOB — MySQL 8 (Banco de Dados)
#
# Servico de banco de dados isolado por namespace do estudante.
# Credenciais injetadas via Vault Workload Identity.
# ==============================================================================

variable "namespace" {
  type        = string
  description = "Namespace do estudante"
}

job "mysql" {
  datacenters = ["dc1"]
  namespace   = var.namespace
  type        = "service"

  group "db" {
    count = 1

    network {
      mode = "bridge"
      port "mysql" {
        to = 3306
      }
    }

    # --- Service Mesh (Consul Connect) ---
    service {
      name = "${var.namespace}-mysql"
      port = "mysql"
      tags = ["student", var.namespace, "database"]

      connect {
        sidecar_service {
          proxy {
            local_service_port = 3306
            config {
              protocol = "tcp"
            }
          }
        }
      }

      check {
        name     = "MySQL Health"
        type     = "script"
        task     = "mysql"
        command  = "mysqladmin"
        args     = ["ping", "-h", "127.0.0.1", "--silent"]
        interval = "15s"
        timeout  = "5s"
      }
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "15s"
      mode     = "fail"
    }

    # --- Volume efemero para dados (perde dados se realocado) ---
    ephemeral_disk {
      size    = 500   # MB
      migrate = true
      sticky  = true
    }

    task "mysql" {
      driver = "docker"

      resources {
        cpu    = 500   # MHz
        memory = 512   # MB
      }

      # --- Workload Identity: Vault injeta segredos ---
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

      # Segredos do Vault injetados como variaveis de ambiente
      template {
        data = <<EOH
{{ with secret "secret/data/students/${var.namespace}/app" }}
MYSQL_ROOT_PASSWORD={{ .Data.data.db_root_password }}
MYSQL_DATABASE=taskdb
MYSQL_USER=taskapi
MYSQL_PASSWORD={{ .Data.data.db_password }}
{{ end }}
EOH
        destination = "secrets/db.env"
        env         = true
        change_mode = "restart"
      }

      config {
        image = "mysql:8.0"
        ports = ["mysql"]

        args = [
          "--default-authentication-plugin=mysql_native_password",
          "--character-set-server=utf8mb4",
          "--collation-server=utf8mb4_unicode_ci",
        ]

        # Dados persistidos no ephemeral_disk
        mount {
          type     = "bind"
          source   = "alloc"
          target   = "/var/lib/mysql"
          readonly = false
        }
      }
    }
  }
}
