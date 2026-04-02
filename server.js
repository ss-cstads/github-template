// ==============================================================================
// APLICACAO EXEMPLO — Substitua pelo seu codigo
// ==============================================================================

const http = require('http');

const PORT = process.env.PORT || 8080;
const NAMESPACE = process.env.NOMAD_NAMESPACE || 'unknown';
const ALLOC_ID = process.env.NOMAD_SHORT_ALLOC_ID || 'local';
const NODE = process.env.NOMAD_NODE_NAME || 'local';

// Segredos do Vault (injetados via template no job.nomad.hcl)
const DB_PASSWORD = process.env.DB_PASSWORD || '(nao configurado)';

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy' }));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`
    <!DOCTYPE html>
    <html lang="pt">
    <head>
      <meta charset="UTF-8">
      <title>Minha Aplicacao — ${NAMESPACE}</title>
      <style>
        body { font-family: system-ui; text-align: center; margin-top: 50px; background: #f0f4f8; }
        .card { background: white; border-radius: 12px; padding: 30px; display: inline-block;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 500px; }
        .info { color: #666; font-size: 0.9em; margin-top: 15px; }
        code { background: #e8f0fe; padding: 2px 8px; border-radius: 4px; }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>Minha Aplicacao</h1>
        <p>Namespace: <code>${NAMESPACE}</code></p>
        <p>Alloc: <code>${ALLOC_ID}</code> | Node: <code>${NODE}</code></p>
        <p class="info">Modifique este ficheiro e faca push para atualizar automaticamente.</p>
      </div>
    </body>
    </html>
  `);
});

server.listen(PORT, () => {
  console.log(`Servidor iniciado na porta ${PORT}`);
});
