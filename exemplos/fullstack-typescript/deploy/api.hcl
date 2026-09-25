# Pack api (github.com/ss-cstads/nomad-packs). O CI informa namespace e image.
# Acessivel so pelo frontend; o MySQL chega em 127.0.0.1:3306 pelo service mesh.
port           = 8080
health_path    = "/health"
cpu            = 200
memory         = 256
mysql_upstream = true

# Segredos do Vault: jwt_secret -> JWT_SECRET; o Prisma quer a senha dentro da URL
# (use em db_password so letras, numeros, - e _: outros caracteres exigem URL-encoding)
vault_secrets = ["jwt_secret"]
secret_env = {
  DATABASE_URL = "mysql://taskapi:{{db_password}}@127.0.0.1:3306/taskdb"
}

env = {
  PORT = "8080"
}
