# Exemplo Fullstack — Backend + Frontend + MySQL

Arquitetura de 3 camadas com service mesh automático via Consul Connect:

```
Ingress Gateway
    └── <namespace>-app (Nginx + Angular)
            └── <namespace>-backend (Spring Boot API)
                    └── <namespace>-mysql (MySQL 8)
```

---

## Como usar

### 1. Copie os arquivos para a raiz do seu repositório

```bash
cp exemplos/fullstack/backend.nomad.hcl  .
cp exemplos/fullstack/frontend.nomad.hcl .
cp exemplos/fullstack/mysql.nomad.hcl    .
cp exemplos/fullstack/.github/workflows/deploy.yml .github/workflows/deploy.yml
```

Adicione também as pastas com o código fonte:
```
backend/    ← sua API (com Dockerfile)
frontend/   ← seu frontend (com Dockerfile)
```

### 2. Configure os GitHub Secrets

Vá em **Settings → Secrets and variables → Actions → "New repository secret"**.

Além dos secrets base (`NOMAD_ADDR`, `NOMAD_TOKEN`, `NOMAD_CACERT_B64`, `STUDENT_NAMESPACE`),
adicione os secrets da aplicação:

| Secret | Descrição |
|--------|-----------|
| `VAULT_ADDR` | Endereço do Vault (fornecido pelo professor) |
| `VAULT_TOKEN` | Token do Vault (fornecido pelo professor) |
| `APP_DB_PASSWORD` | Senha do usuário da aplicação no MySQL |
| `APP_DB_ROOT_PASSWORD` | Senha root do MySQL |
| `APP_JWT_SECRET` | Chave secreta para geração de tokens JWT |

### 3. Configure a Variable

Vá em **Settings → Secrets and variables → Actions**, aba **"Variables" → "New repository variable"**:

| Variable | Valor |
|----------|-------|
| `SYNC_VAULT_SECRETS` | `true` |

### 4. Torne as imagens públicas

Após o primeiro push, acesse `github.com/<usuario>?tab=packages` e torne
os pacotes `backend` e `frontend` públicos.

### 5. Acesse a aplicação

```
http://<seu-namespace>.projetos.sapucaia.ifsul.edu.br
```

---

## Segredos injetados nos jobs via Vault

O MySQL e o backend recebem automaticamente (via Workload Identity):

| Secret | Usado por |
|--------|-----------|
| `db_password` | Backend (conexão com MySQL) e MySQL (senha do usuário `taskapi`) |
| `db_root_password` | MySQL (senha root) |
| `jwt_secret` | Backend (assinatura de tokens JWT) |

Esses segredos são escritos no Vault pelo GitHub Actions quando
`SYNC_VAULT_SECRETS=true`. Você não precisa acessar o Vault diretamente.
