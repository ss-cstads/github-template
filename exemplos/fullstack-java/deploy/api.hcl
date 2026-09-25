# Pack api (github.com/ss-cstads/nomad-packs). O CI informa namespace e image.
# Acessivel so pelo frontend; o MySQL chega em 127.0.0.1:3306 pelo service mesh.
port             = 8080
health_path      = "/actuator/health"
cpu              = 500
memory           = 512
healthy_deadline = "5m"   # a JVM demora para subir
mysql_upstream   = true

# Segredos do Vault: jwt_secret -> JWT_SECRET; a senha vai no nome que o Spring espera
vault_secrets = ["jwt_secret"]
secret_env = {
  SPRING_DATASOURCE_PASSWORD = "{{db_password}}"
}

env = {
  SPRING_DATASOURCE_URL                   = "jdbc:mysql://127.0.0.1:3306/taskdb?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
  SPRING_DATASOURCE_USERNAME              = "taskapi"
  SPRING_DATASOURCE_DRIVER_CLASS_NAME     = "com.mysql.cj.jdbc.Driver"
  SPRING_JPA_HIBERNATE_DDL_AUTO           = "update"
  SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT = "org.hibernate.dialect.MySQLDialect"
  SERVER_PORT                             = "8080"
}
