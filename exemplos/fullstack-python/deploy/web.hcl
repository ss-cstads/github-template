# Pack web_app (github.com/ss-cstads/nomad-packs). O CI informa namespace e image.
# Publicado em https://<namespace>.projetos.sapucaia.ifsul.edu.br
port             = 80
health_path      = "/health"
memory           = 128
backend_upstream = true   # backend em 127.0.0.1:8080 (proxy /api/ no nginx.conf)
