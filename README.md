# Deploy no Cluster IFSUL — Template

Este repositório é o ponto de partida para fazer deploy da sua aplicação
no servidor do Curso via GitHub Actions.

---

## Início rápido

### 1. Crie seu repositório a partir deste template

Clique em **"Use this template"** → **"Create a new repository"**.

> Não faça Fork — use o botão de template para ter um repositório próprio e limpo.

### 2. Configure os Secrets do GitHub

Vá em **Settings → Secrets and variables → Actions, Repository secrets** clique em **"New repository secret"** e adicione (sem as crases):

|       Secret        |              Descrição              | Fornecido por |
|---------------------|-------------------------------------|---------------|
| `NOMAD_ADDR`        | Endereço do cluster Nomad           | Professor     |
| `NOMAD_TOKEN`       | Seu token de acesso ao Nomad        | Professor     |
| `NOMAD_CACERT_B64`  | Certificado TLS do cluster (base64) | Professor     |
| `STUDENT_NAMESPACE` | Seu namespace isolado               | Professor     |


## Usando segredos na aplicação

Se sua aplicação precisar de senhas ou chaves secretas, elas são gerenciadas pelo GitHub Actions, e salvas no ambiente Vault do servidor do Curso.

Vá em **Settings → Secrets and variables → Actions, Repository secrets** clique em **"New repository secret"** e adicione (sem as crases):

|       Secret      |                   Exemplo                    |
|-------------------|----------------------------------------------|
| `VAULT_ADDR`      | Endereço do Vault (fornecido pelo professor) |
| `VAULT_TOKEN`     | Token do Vault (fornecido pelo professor)    |
|ADICIONE OS SECRETS DA SUA APLICAÇÃO E OS RESPECTIVOS VALORES, ex:|
| `APP_DB_PASSWORD` | Sua senha do banco de dados                  |
| `APP_API_KEY`     | Sua chave de API                             |

**Crie uma Variable** (**Settings → Secrets and variables → Actions**, aba **"Variables" → "New repository variable"**):

|       Variable       |  Valor |
|----------------------|--------|
| `SYNC_VAULT_SECRETS` | `true` |


No próximo push, o GitHub Actions escreverá os secrets no Vault automaticamente antes de fazer o deploy. 
Depois que os secrets estiverem criados, você pode definir `SYNC_VAULT_SECRETS=false` para não reescrevê-los a cada deploy.

### 3. Desenvolva sua aplicação

- Edite `server.js` (ou substitua pelo seu código)
- Edite `Dockerfile` conforme necessário
- A porta padrão é **8080** (altere em `job.nomad.hcl` se necessário)

### 4. Push para fazer deploy

```bash
git add .
git commit -m "minha aplicação"
git push
```

O GitHub Actions vai automaticamente:
1. Construir a imagem Docker e publicar no GitHub Container Registry
2. Fazer deploy no seu namespace do cluster

> **Importante:** Caso esteja usando um repositório privado, após o primeiro push, torne sua imagem Docker pública:
> `github.com/<seu-usuario>?tab=packages` → pacote → **Package settings** → **Public**

### 5. Acesse sua aplicação

```
http://<seu-namespace>.projetos.sapucaia.ifsul.edu.br
```

## Estrutura do template

```
├── .github/workflows/deploy.yml   # Pipeline CI/CD
├── job.nomad.hcl                  # Definição do deploy no Nomad
├── Dockerfile                     # Como construir sua imagem
├── server.js                      # App de exemplo (substitua pelo seu)
├── package.json                   # Dependências (substitua se necessário)
└── exemplos/
    └── fullstack/                 # Exemplo: aplicação 3 camadas (opcional)
```

---

## Exemplo fullstack (Backend + Frontend + Banco de dados)

Se quiser implantar uma aplicação com múltiplos serviços (ex: API + frontend + MySQL),
veja a pasta `exemplos/fullstack/`. Ela contém:

- `backend.nomad.hcl` — API (Spring Boot)
- `frontend.nomad.hcl` — Frontend (Angular/Nginx)
- `mysql.nomad.hcl` — Banco de dados (MySQL 8)
- `.github/workflows/deploy.yml` — Workflow adaptado para 3 serviços
- `README.md` — Instruções específicas do fullstack

Para usar, copie o conteúdo de `exemplos/fullstack/` para a raiz do seu repositório
e substitua o `.github/workflows/deploy.yml` pelo da pasta de exemplos.

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| "token denied" | Verifique se `NOMAD_TOKEN` está correto |
| Aplicação não carrega | Confirme que a porta no `Dockerfile` bate com `job.nomad.hcl` |
| Imagem não encontrada | Torne o pacote público em `github.com/<usuario>?tab=packages` |
| Health check falhando | Verifique se sua aplicação responde na rota `/` com HTTP 200 |
| Segredos não injetados | Confirme que `SYNC_VAULT_SECRETS=true` e os secrets do Vault estão configurados |
