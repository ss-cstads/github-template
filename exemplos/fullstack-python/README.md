# Deploy Fullstack — Python (FastAPI) + Angular + MySQL

Aplicacao web completa com 3 servicos:

```
Internet  →  Frontend (Angular)  →  Backend (FastAPI + SQLAlchemy)  →  MySQL
```

---

## Passo 1 — Crie seu repositorio

1. Acesse o repositorio template fornecido pelo professor
2. Clique em **"Use this template"** → **"Create a new repository"**
3. Escolha um nome e crie o repositorio

## Passo 2 — Copie os arquivos do exemplo

Clone seu repositorio e copie os arquivos deste exemplo para a raiz:

```bash
git clone https://github.com/<seu-usuario>/<seu-repositorio>.git
cd <seu-repositorio>

cp exemplos/fullstack-python/backend.nomad.hcl  .
cp exemplos/fullstack-python/frontend.nomad.hcl .
cp exemplos/fullstack-python/mysql.nomad.hcl    .
cp -r exemplos/fullstack-python/backend/  .
cp -r exemplos/fullstack-python/frontend/ .
cp exemplos/fullstack-python/.github/workflows/deploy.yml .github/workflows/deploy.yml
```

## Passo 3 — Configure os Secrets no GitHub

Va em **Settings → Secrets and variables → Actions → "New repository secret"**
e adicione cada secret abaixo:

| Secret | Descricao |
|--------|-----------|
| `NOMAD_ADDR` | Endereco do cluster Nomad |
| `NOMAD_TOKEN` | Seu token de acesso ao Nomad |
| `NOMAD_CACERT_B64` | Certificado TLS do cluster (base64) |
| `STUDENT_NAMESPACE` | Seu namespace (ex: `aluno01`) |
| `VAULT_ADDR` | Endereco do Vault |
| `VAULT_TOKEN` | Token do Vault |
| `APP_DB_PASSWORD` | Senha do banco de dados (voce escolhe) |
| `APP_DB_ROOT_PASSWORD` | Senha root do MySQL (voce escolhe) |
| `APP_JWT_SECRET` | Chave para tokens de autenticacao |

> Os 6 primeiros secrets sao fornecidos pelo professor.
> Os 3 ultimos voce escolhe. Para gerar o `APP_JWT_SECRET`:
> ```bash
> openssl rand -hex 32
> ```

## Passo 4 — Crie a Variable

Na mesma pagina, va na aba **Variables** e crie:

| Variable | Valor |
|----------|-------|
| `SYNC_VAULT_SECRETS` | `true` |

## Passo 5 — Faca push para deploy

```bash
git add .
git commit -m "deploy fullstack python"
git push
```

O GitHub Actions vai automaticamente:
1. Construir as imagens Docker (backend e frontend)
2. Publicar no GitHub Container Registry
3. Fazer deploy no cluster

## Passo 6 — Torne as imagens publicas

Apos o primeiro push, va em `github.com/<seu-usuario>?tab=packages`:

1. Clique no pacote `backend` → **Package settings** → **Change visibility** → **Public**
2. Repita para o pacote `frontend`

> Se as imagens nao forem publicas, o cluster nao consegue baixar e o deploy falha.

## Passo 7 — Acesse sua aplicacao

```
https://<seu-namespace>.projetos.sapucaia.ifsul.edu.br
```

**Login padrao:** usuario `admin`, senha `admin123`

---

## Estrutura dos arquivos

```
├── .github/workflows/deploy.yml   # Pipeline de deploy automatico
├── backend.nomad.hcl              # Deploy do backend no cluster
├── frontend.nomad.hcl             # Deploy do frontend no cluster
├── mysql.nomad.hcl                # Deploy do banco de dados no cluster
├── backend/
│   ├── Dockerfile                 # Imagem Docker do backend
│   ├── requirements.txt           # Dependencias Python
│   └── main.py                    # Codigo-fonte FastAPI
└── frontend/
    ├── Dockerfile                 # Imagem Docker do frontend
    ├── angular.json               # Configuracao Angular
    ├── package.json               # Dependencias Node.js
    └── src/                       # Codigo-fonte Angular
```

---

## Problemas comuns

| Problema | O que fazer |
|----------|-------------|
| "token denied" | Verifique se `NOMAD_TOKEN` esta correto |
| Imagem nao encontrada | Torne os pacotes **publicos** (passo 6) |
| Backend nao conecta ao MySQL | Aguarde ~30s — o MySQL demora para inicializar |
| Pagina em branco | Abra o console do navegador (F12) e veja o erro |
| Segredos nao injetados | Confirme que `SYNC_VAULT_SECRETS` esta como `true` |
