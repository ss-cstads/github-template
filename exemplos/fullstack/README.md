# Exemplo Fullstack — Backend + Frontend + MySQL

Aplicacao de exemplo com 3 camadas, usando service mesh automatico via Consul Connect:

```
Ingress Gateway (HTTPS)
    └── <namespace>-app (Nginx + Angular)
            └── <namespace>-backend (Spring Boot API)
                    └── <namespace>-mysql (MySQL 8)
```

**Credenciais de teste da aplicacao:**
- Usuario: `admin` / Senha: `admin123`
- Ou crie uma conta pela tela de cadastro

---

## Deploy via GitHub Actions

### 1. Copie os arquivos para a raiz do seu repositorio

```bash
# Arquivos de deploy (obrigatorios)
cp exemplos/fullstack/backend.nomad.hcl  .
cp exemplos/fullstack/frontend.nomad.hcl .
cp exemplos/fullstack/mysql.nomad.hcl    .

# Workflow do GitHub Actions
cp exemplos/fullstack/.github/workflows/deploy.yml .github/workflows/deploy.yml
```

Copie tambem as pastas com o codigo-fonte:

```bash
cp -r exemplos/fullstack/backend/  .
cp -r exemplos/fullstack/frontend/ .
```

A estrutura final do seu repositorio deve ficar assim:

```
├── .github/workflows/deploy.yml   # Pipeline CI/CD (3 servicos)
├── backend.nomad.hcl              # Job Nomad: API Spring Boot
├── frontend.nomad.hcl             # Job Nomad: Nginx + Angular
├── mysql.nomad.hcl                # Job Nomad: MySQL 8
├── backend/                       # Codigo-fonte da API
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── pom.xml
│   └── src/
└── frontend/                      # Codigo-fonte do frontend
    ├── Dockerfile
    ├── .dockerignore
    ├── package.json
    ├── angular.json
    └── src/
```

### 2. Configure os GitHub Secrets

Va em **Settings → Secrets and variables → Actions → "New repository secret"**
e adicione os seguintes secrets (todos fornecidos pelo professor):

| Secret | Descricao |
|--------|-----------|
| `NOMAD_ADDR` | Endereco do cluster Nomad |
| `NOMAD_TOKEN` | Seu token de acesso ao Nomad |
| `NOMAD_CACERT_B64` | Certificado TLS do cluster (base64) |
| `STUDENT_NAMESPACE` | Seu namespace isolado (ex: `aluno01`) |
| `VAULT_ADDR` | Endereco do Vault |
| `VAULT_TOKEN` | Token do Vault |

Adicione tambem os **secrets da aplicacao** (valores definidos por voce):

| Secret | Descricao |
|--------|-----------|
| `APP_DB_PASSWORD` | Senha do usuario da aplicacao no MySQL |
| `APP_DB_ROOT_PASSWORD` | Senha root do MySQL |
| `APP_JWT_SECRET` | Chave secreta para tokens JWT (veja abaixo) |

> **Como gerar o `APP_JWT_SECRET`:**
> ```bash
> openssl rand -hex 32
> ```
> O resultado e uma string aleatoria de 64 caracteres. Guarde-a.

### 3. Configure a Variable

Va em **Settings → Secrets and variables → Actions**, aba **"Variables" → "New repository variable"**:

| Variable | Valor |
|----------|-------|
| `SYNC_VAULT_SECRETS` | `true` |

> Apos o primeiro deploy bem-sucedido, voce pode mudar para `false` para nao
> reescrever os segredos a cada push.

### 4. Faca push para disparar o deploy

```bash
git add .
git commit -m "deploy fullstack"
git push
```

O GitHub Actions vai automaticamente:
1. Escrever os segredos no Vault (se `SYNC_VAULT_SECRETS=true`)
2. Construir as imagens Docker do backend e frontend
3. Publicar as imagens no GitHub Container Registry
4. Fazer deploy dos 3 servicos no cluster (MySQL → Backend → Frontend)

### 5. Torne as imagens publicas

Apos o primeiro push, acesse `github.com/<seu-usuario>?tab=packages` e torne
os pacotes `backend` e `frontend` **publicos**:

- Clique no pacote → **Package settings** → **Change visibility** → **Public**

> **Importante:** se as imagens nao forem publicas, o cluster nao conseguira
> fazer download delas e o deploy falhara.

### 6. Acesse a aplicacao

```
https://<seu-namespace>.projetos.sapucaia.ifsul.edu.br
```

---

## Como funciona

### Arquitetura

| Servico | Tecnologia | Porta | Funcao |
|---------|------------|-------|--------|
| **Frontend** | Angular + Nginx | 80 | Interface web (SPA) |
| **Backend** | Spring Boot | 8080 | API REST com autenticacao JWT |
| **MySQL** | MySQL 8.0 | 3306 | Banco de dados relacional |

Os servicos se comunicam via **Consul Connect** (service mesh):
- O frontend faz proxy de `/api/*` para o backend
- O backend conecta ao MySQL via sidecar proxy
- Todo o trafego entre servicos e criptografado (mTLS automatico)

### Segredos via Vault

Os segredos sao injetados automaticamente nos containers via Vault Workload Identity.
Voce **nao precisa acessar o Vault diretamente** — o GitHub Actions faz isso por voce.

| Segredo | Usado por |
|---------|-----------|
| `db_password` | Backend (conexao) e MySQL (senha do usuario `taskapi`) |
| `db_root_password` | MySQL (senha root) |
| `jwt_secret` | Backend (assinatura de tokens JWT) |

### Boas praticas nos Dockerfiles

Os Dockerfiles deste exemplo aplicam praticas recomendadas de seguranca:

- **Multi-stage build** — a imagem final contem apenas o runtime (JRE ou Nginx) e
  os artefatos compilados, sem codigo-fonte, ferramentas de build ou dependencias
  de desenvolvimento
- **Usuario nao-root** — o backend roda como usuario `spring` sem privilegios
- **`.dockerignore`** — impede que arquivos desnecessarios (node_modules, .git)
  entrem no build context
- **Imagens Alpine** — base minima (~40MB), reduz superficie de ataque
- **Cache de camadas** — dependencias sao instaladas antes de copiar o codigo,
  acelerando rebuilds

---

## Troubleshooting

| Problema | Solucao |
|----------|---------|
| "token denied" no deploy | Verifique se `NOMAD_TOKEN` esta correto nos secrets |
| Imagem nao encontrada | Torne os pacotes **publicos** em `github.com/<usuario>?tab=packages` |
| Backend nao conecta ao MySQL | O MySQL pode estar ainda inicializando; o backend faz retry automatico |
| Health check falhando | Verifique os logs: va em Actions → job → "Status final" |
| Segredos nao injetados | Confirme que `SYNC_VAULT_SECRETS=true` e os secrets do Vault estao configurados |
| Pagina em branco | Abra o console do navegador (F12) para ver erros de JavaScript |
