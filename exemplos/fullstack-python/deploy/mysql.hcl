# Pack mysql (github.com/ss-cstads/nomad-packs). O CI informa o namespace.
# Senhas no Vault: db_root_password e db_password (job vault-secrets do workflow).
# Banco e usuario so sao criados no primeiro start, com o volume vazio.
database = "taskdb"
user     = "taskapi"
