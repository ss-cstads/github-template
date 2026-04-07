# ==============================================================================
# NOMAD JOB — Frontend Angular (Nginx + SPA)
#
# Servico de frontend que faz proxy de /api/* para o backend via Consul Connect.
# Este e o servico principal registrado como <namespace>-app no Ingress Gateway.
# ==============================================================================

variable "namespace" {
  type        = string
  description = "Namespace do estudante"
}

variable "image" {
  type        = string
  description = "Imagem Docker do frontend"
  default     = "ghcr.io/ifsul-sapucaia/exemplo-frontend:latest"
}

job "frontend" {
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

  group "web" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 80
      }
    }

    # --- Service: registrado como <namespace>-app (ponto de entrada no Ingress) ---
    service {
      name = "${var.namespace}-app"
      port = "http"
      tags = ["student", var.namespace, "frontend", "angular"]

      connect {
        sidecar_service {
          proxy {
            local_service_port = 80
            config {
              protocol = "http"
            }

            # Upstream: proxy para o backend via service mesh
            upstreams {
              destination_name = "${var.namespace}-backend"
              local_bind_port  = 8080
            }
          }
        }
      }

      check {
        name     = "Nginx Health"
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "3s"
      }
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "15s"
      mode     = "fail"
    }

    task "nginx" {
      driver = "docker"

      resources {
        cpu    = 200   # MHz
        memory = 128   # MB
      }

      # Template do Nginx: faz proxy de /api para o backend upstream
      template {
        data = <<EOH
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Health check
    location /health {
        access_log off;
        return 200 '{"status":"ok"}';
        add_header Content-Type application/json;
    }

    # Proxy para o backend (via Consul Connect upstream)
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # SPA: todas as rotas caem no index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOH
        destination = "local/default.conf"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }

      config {
        image = var.image
        ports = ["http"]

        # Override da configuracao padrao do Nginx
        mount {
          type     = "bind"
          source   = "local/default.conf"
          target   = "/etc/nginx/conf.d/default.conf"
          readonly = true
        }
      }
    }
  }
}
