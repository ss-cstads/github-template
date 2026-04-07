# Deploy no Cluster IFSUL

Este repositorio e o ponto de partida para fazer deploy da sua aplicacao no
servidor do Curso via GitHub Actions. Funciona com qualquer linguagem ou
framework que rode em um container Docker.

---

## Inicio rapido

### 1. Crie seu repositorio a partir deste template

Clique em **"Use this template"** → **"Create a new repository"**.

> Nao faca Fork — use o botao de template para ter um repositorio proprio e limpo.

### 2. Configure os GitHub Secrets

Va em **Settings → Secrets and variables → Actions → "New repository secret"**
e adicione os secrets fornecidos pelo professor:

| Secret | Descricao |
|--------|-----------|
| `NOMAD_ADDR` | Endereco do cluster Nomad |
| `NOMAD_TOKEN` | Seu token de acesso ao Nomad |
| `NOMAD_CACERT_B64` | Certificado TLS do cluster (base64) |
| `STUDENT_NAMESPACE` | Seu namespace isolado (ex: `aluno01`) |

### 3. Copie os templates para a raiz do repositorio

Escolha o template correspondente a sua linguagem e copie para a raiz:

**Node.js:**
```bash
cp templates/Dockerfile.nodejs Dockerfile
cp templates/dockerignore.nodejs .dockerignore
cp templates/job.nomad.hcl job.nomad.hcl
```

**Java (Spring Boot):**
```bash
cp templates/Dockerfile.java Dockerfile
cp templates/dockerignore.java .dockerignore
cp templates/job.nomad.hcl job.nomad.hcl
```

**Python (Flask/FastAPI):**
```bash
cp templates/Dockerfile.python Dockerfile
cp templates/dockerignore.python .dockerignore
cp templates/job.nomad.hcl job.nomad.hcl
```

> Depois de copiar, **personalize** os arquivos conforme explicado abaixo.

### 4. Personalize os arquivos

#### Dockerfile

- Ajuste o comando de inicio (`CMD`) para sua aplicacao
- Confirme que a porta `EXPOSE` bate com a porta do `job.nomad.hcl`

#### job.nomad.hcl

- Troque `"my-app"` pelo nome da sua aplicacao
- Ajuste a porta se necessario (padrao: `8080`)
- Ajuste os recursos (`cpu`/`memory`) conforme sua aplicacao:

| Tipo de aplicacao | cpu | memory |
|-------------------|-----|--------|
| Node.js simples | 200 | 128 |
| Python/Flask | 200 | 256 |
| Spring Boot | 500 | 512 |

#### Health check

O cluster verifica periodicamente se sua aplicacao esta saudavel. Por padrao,
ele faz `GET /` e espera HTTP 200. Se sua app usa outra rota de saude (ex:
`/health`, `/actuator/health`), ajuste no `job.nomad.hcl`:

```hcl
check {
  path = "/health"    # Ajuste para a rota da sua aplicacao
}
```

### 5. Push para fazer deploy

```bash
git add .
git commit -m "minha aplicacao"
git push
```

O GitHub Actions vai automaticamente:
1. Construir a imagem Docker
2. Publicar no GitHub Container Registry
3. Fazer deploy no seu namespace do cluster

### 6. Torne a imagem publica

Apos o primeiro push, va em `github.com/<seu-usuario>?tab=packages`:
- Clique no pacote → **Package settings** → **Change visibility** → **Public**

> Se a imagem nao for publica, o cluster nao consegue fazer download e o deploy falha.

### 7. Acesse sua aplicacao

```
https://<seu-namespace>.projetos.sapucaia.ifsul.edu.br
```

---

## Usando segredos na aplicacao

Se sua aplicacao precisa de senhas, chaves ou tokens, use o Vault integrado ao
cluster. Os segredos sao escritos automaticamente pelo GitHub Actions.

### Configurar segredos

1. Adicione **GitHub Secrets** adicionais:

| Secret | Descricao |
|--------|-----------|
| `VAULT_ADDR` | Endereco do Vault (fornecido pelo professor) |
| `VAULT_TOKEN` | Token do Vault (fornecido pelo professor) |
| `APP_DB_PASSWORD` | Exemplo: senha do banco de dados |
| `APP_API_KEY` | Exemplo: chave de API |

2. Crie a **Variable** `SYNC_VAULT_SECRETS` com valor `true`:
   - **Settings → Secrets and variables → Actions**, aba **Variables**

3. No `deploy.yml`, ajuste a secao `vault-secrets` com os nomes dos seus secrets.

4. No `job.nomad.hcl`, ajuste o bloco `template` para mapear os segredos
   como variaveis de ambiente.

> Apos o primeiro deploy bem-sucedido, voce pode mudar `SYNC_VAULT_SECRETS`
> para `false` para nao reescrever os segredos a cada push.

### Como os segredos chegam na aplicacao

```
GitHub Secrets  →  GitHub Actions  →  Vault  →  Nomad (template)  →  Variavel de ambiente
```

Sua aplicacao le os segredos como variaveis de ambiente normais:

**Node.js:** `process.env.DB_PASSWORD`

**Java:** `System.getenv("DB_PASSWORD")` ou `@Value("${DB_PASSWORD}")` (Spring)

**Python:** `os.environ.get("DB_PASSWORD")`

---

## Guia por linguagem

### Node.js (Express, Fastify, Hapi)

**Estrutura minima do repositorio:**
```
├── .github/workflows/deploy.yml
├── Dockerfile          (copiado de templates/Dockerfile.nodejs)
├── .dockerignore       (copiado de templates/dockerignore.nodejs)
├── job.nomad.hcl       (copiado de templates/job.nomad.hcl)
├── package.json
├── package-lock.json   (gerado pelo npm install)
└── server.js           (ou index.js, app.js, etc.)
```

**Exemplo minimo (`server.js`):**
```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.json({ status: 'ok', namespace: process.env.NOMAD_NAMESPACE });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(PORT, () => console.log(`Servidor na porta ${PORT}`));
```

**Importante:** gere o `package-lock.json` antes de fazer push:
```bash
npm install
git add package-lock.json
```

---

### Java (Spring Boot)

**Estrutura minima do repositorio:**
```
├── .github/workflows/deploy.yml
├── Dockerfile          (copiado de templates/Dockerfile.java)
├── .dockerignore       (copiado de templates/dockerignore.java)
├── job.nomad.hcl       (copiado de templates/job.nomad.hcl)
├── pom.xml
└── src/
    └── main/java/...
```

**Ajustes no `job.nomad.hcl`:**
```hcl
resources {
  cpu    = 500   # Spring Boot precisa de mais CPU
  memory = 512   # e mais memoria
}

check {
  path = "/actuator/health"   # Spring Boot Actuator
}
```

**`application.yml` — ler segredos como variaveis de ambiente:**
```yaml
spring:
  datasource:
    password: ${DB_PASSWORD:defaultpass}
app:
  api-key: ${API_KEY:}
```

**Importante:** adicione `spring-boot-starter-actuator` no `pom.xml` para
o health check funcionar em `/actuator/health`.

---

### Python (Flask)

**Estrutura minima do repositorio:**
```
├── .github/workflows/deploy.yml
├── Dockerfile          (copiado de templates/Dockerfile.python)
├── .dockerignore       (copiado de templates/dockerignore.python)
├── job.nomad.hcl       (copiado de templates/job.nomad.hcl)
├── requirements.txt
└── app.py
```

**Exemplo minimo (`app.py`):**
```python
import os
from flask import Flask, jsonify

app = Flask(__name__)
PORT = int(os.environ.get("PORT", 8080))

@app.route("/")
def index():
    return jsonify(status="ok", namespace=os.environ.get("NOMAD_NAMESPACE"))

@app.route("/health")
def health():
    return jsonify(status="healthy")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
```

**`requirements.txt`:**
```
flask>=3.0
gunicorn>=22.0
```

**Para producao**, troque o `CMD` no Dockerfile:
```dockerfile
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:8080"]
```

---

### Python (FastAPI)

**Exemplo minimo (`main.py`):**
```python
import os
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def index():
    return {"status": "ok", "namespace": os.environ.get("NOMAD_NAMESPACE")}

@app.get("/health")
def health():
    return {"status": "healthy"}
```

**`requirements.txt`:**
```
fastapi>=0.115
uvicorn[standard]>=0.32
```

**Ajuste o `CMD` no Dockerfile:**
```dockerfile
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

---

## Estrutura do template

```
├── .github/workflows/deploy.yml   # Pipeline CI/CD (funciona com qualquer linguagem)
├── templates/                     # Templates prontos para uso
│   ├── Dockerfile.nodejs          # Template Docker para Node.js
│   ├── Dockerfile.java            # Template Docker para Java (Spring Boot)
│   ├── Dockerfile.python          # Template Docker para Python (Flask/FastAPI)
│   ├── dockerignore.nodejs        # .dockerignore para Node.js
│   ├── dockerignore.java          # .dockerignore para Java
│   ├── dockerignore.python        # .dockerignore para Python
│   └── job.nomad.hcl              # Template de deploy no Nomad (generico)
└── exemplos/
    └── fullstack/                 # Exemplo completo: API + Frontend + MySQL
```

---

## Exemplo fullstack (Backend + Frontend + Banco de dados)

Se quiser implantar uma aplicacao com multiplos servicos (ex: API + frontend + MySQL),
veja a pasta `exemplos/fullstack/`. Ela contem:

- Codigo-fonte do backend (Spring Boot) e frontend (Angular)
- Jobs Nomad para 3 servicos com Consul Connect (service mesh)
- Workflow adaptado para multi-servico
- README com instrucoes detalhadas

Para usar, siga as instrucoes em `exemplos/fullstack/README.md`.

---

## Troubleshooting

| Problema | Solucao |
|----------|---------|
| "token denied" no deploy | Verifique se `NOMAD_TOKEN` esta correto nos secrets |
| Imagem nao encontrada | Torne o pacote **publico** em `github.com/<usuario>?tab=packages` |
| Health check falhando | Confirme que sua app responde HTTP 200 na rota configurada |
| Aplicacao nao carrega | Verifique se a porta do `Dockerfile` bate com `job.nomad.hcl` |
| Segredos nao injetados | Confirme `SYNC_VAULT_SECRETS=true` e que os secrets do Vault estao configurados |
| Build falha | Verifique se o `Dockerfile` e `.dockerignore` estao na raiz do repositorio |
| "no space left on device" | Imagem muito grande — use multi-stage build e Alpine |
