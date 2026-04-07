# Exemplo Fullstack — Backend + Frontend + MySQL

Uma aplicacao completa com 3 servicos que se comunicam automaticamente:

```
Internet → Frontend (Angular) → Backend (Spring Boot) → MySQL
```

**Login padrao:** usuario `admin`, senha `admin123` (ou crie uma conta nova).

---

## Passo a passo

### 1. Copie os arquivos para a raiz do seu repositorio

```bash
cp exemplos/fullstack/backend.nomad.hcl  .
cp exemplos/fullstack/frontend.nomad.hcl .
cp exemplos/fullstack/mysql.nomad.hcl    .
cp -r exemplos/fullstack/backend/  .
cp -r exemplos/fullstack/frontend/ .
cp exemplos/fullstack/.github/workflows/deploy.yml .github/workflows/deploy.yml
```

### 2. Configure os GitHub Secrets

Va em **Settings → Secrets and variables → Actions → "New repository secret"**:

|         Secret         |              Descricao                      |
|------------------------|---------------------------------------------|
| `NOMAD_ADDR`           | Endereco do cluster Nomad                   |
| `NOMAD_TOKEN`          | Seu token de acesso ao Nomad                |
| `NOMAD_CACERT_B64`     | Certificado TLS do cluster (base64)         |
| `STUDENT_NAMESPACE`    | Seu namespace isolado (ex: `aluno01`)       |
| `VAULT_ADDR`           | Endereco do Vault                           |
| `VAULT_TOKEN`          | Token do Vault                              |
| `APP_DB_PASSWORD`      | Senha do usuario da aplicacao no MySQL      |
| `APP_DB_ROOT_PASSWORD` | Senha root do MySQL                         |
| `APP_JWT_SECRET`       | Chave para tokens JWT (veja abaixo)         |

> Os 6 primeiros sao fornecidos pelo professor. Os 3 ultimos voce escolhe.
>
> Para gerar o `APP_JWT_SECRET`, execute no terminal:
> ```bash
> openssl rand -hex 32
> ```

### 3. Crie a Variable

Va em **Settings → Secrets and variables → Actions**, aba **Variables**:

| Variable             | Valor  |
|----------------------|--------|
| `SYNC_VAULT_SECRETS` | `true` |

### 4. Torne as imagens publicas

Apos o primeiro push, va em `github.com/<seu-usuario>?tab=packages` e torne
os pacotes `backend` e `frontend` **publicos**:

- Clique no pacote → **Package settings** → **Change visibility** → **Public**

### 5. Faca push

```bash
git add .
git commit -m "deploy fullstack"
git push
```

### 6. Acesse

```
https://<seu-namespace>.projetos.sapucaia.ifsul.edu.br
```

---

## Problemas comuns

| Problema                     | O que fazer                                        |
|------------------------------|----------------------------------------------------|
| "token denied"               | Verifique se `NOMAD_TOKEN` esta correto            |
| Imagem nao encontrada        | Torne os pacotes **publicos** (passo 4)            |
| Backend nao conecta ao MySQL | Aguarde — o MySQL demora ~30s para inicializar     |
| Pagina em branco             | Abra o console do navegador (F12)                  |
| Segredos nao injetados       | Confirme que `SYNC_VAULT_SECRETS` esta como `true` |
