# Pack api (github.com/ss-cstads/nomad-packs). O CI informa namespace e image.
# Acessivel so pelo frontend; o MySQL chega em 127.0.0.1:3306 pelo service mesh.
port           = 8080
health_path    = "/health"
cpu            = 200
memory         = 256
mysql_upstream = true

# Segredos do Vault -> DB_PASSWORD e JWT_SECRET
vault_secrets = ["db_password", "jwt_secret"]

env = {
  DB_HOST = "127.0.0.1"
  DB_PORT = "3306"
  DB_NAME = "taskdb"
  DB_USER = "taskapi"
}
