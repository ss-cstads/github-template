const express = require('express');
const { Sequelize, DataTypes } = require('sequelize');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const app = express();
app.use(express.json());

// --- Configuracao via variaveis de ambiente (injetadas pelo Vault) ---
const PORT = process.env.PORT || 8080;
const DB_HOST = process.env.DB_HOST || '127.0.0.1';
const DB_PORT = process.env.DB_PORT || 3306;
const DB_NAME = process.env.DB_NAME || 'taskdb';
const DB_USER = process.env.DB_USER || 'taskapi';
const DB_PASS = process.env.DB_PASSWORD || 'password';
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

// --- Banco de dados (Sequelize + MySQL) ---
const sequelize = new Sequelize(DB_NAME, DB_USER, DB_PASS, {
  host: DB_HOST,
  port: DB_PORT,
  dialect: 'mysql',
  logging: false,
});

const User = sequelize.define('User', {
  username: { type: DataTypes.STRING(50), unique: true, allowNull: false },
  password: { type: DataTypes.STRING(255), allowNull: false },
  name:     { type: DataTypes.STRING(100), allowNull: false },
  role:     { type: DataTypes.STRING(20), defaultValue: 'USER' },
});

const Task = sequelize.define('Task', {
  title:       { type: DataTypes.STRING(200), allowNull: false },
  description: { type: DataTypes.TEXT, defaultValue: '' },
  completed:   { type: DataTypes.BOOLEAN, defaultValue: false },
});

User.hasMany(Task);
Task.belongsTo(User);

// --- Middleware de autenticacao ---
function auth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token nao fornecido' });
  }
  try {
    const payload = jwt.verify(header.slice(7), JWT_SECRET);
    req.userId = payload.id;
    next();
  } catch {
    res.status(401).json({ error: 'Token invalido' });
  }
}

// --- Rotas de autenticacao ---
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, name } = req.body;
    if (!username || !password || !name) {
      return res.status(400).json({ error: 'Campos obrigatorios: username, password, name' });
    }
    const exists = await User.findOne({ where: { username } });
    if (exists) return res.status(409).json({ error: 'Usuario ja existe' });

    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({ username, password: hash, name });
    const token = jwt.sign({ id: user.id, username }, JWT_SECRET, { expiresIn: '24h' });
    res.status(201).json({ token, username, name: user.name, role: user.role });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const user = await User.findOne({ where: { username } });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ error: 'Credenciais invalidas' });
    }
    const token = jwt.sign({ id: user.id, username }, JWT_SECRET, { expiresIn: '24h' });
    res.json({ token, username, name: user.name, role: user.role });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- Rotas de tarefas (protegidas) ---
app.get('/api/tasks', auth, async (req, res) => {
  const tasks = await Task.findAll({ where: { UserId: req.userId }, order: [['createdAt', 'DESC']] });
  res.json(tasks);
});

app.post('/api/tasks', auth, async (req, res) => {
  const { title, description, completed } = req.body;
  const task = await Task.create({ title, description, completed, UserId: req.userId });
  res.status(201).json(task);
});

app.put('/api/tasks/:id', auth, async (req, res) => {
  const task = await Task.findOne({ where: { id: req.params.id, UserId: req.userId } });
  if (!task) return res.status(404).json({ error: 'Tarefa nao encontrada' });
  const { title, description, completed } = req.body;
  await task.update({ title, description, completed });
  res.json(task);
});

app.delete('/api/tasks/:id', auth, async (req, res) => {
  const task = await Task.findOne({ where: { id: req.params.id, UserId: req.userId } });
  if (!task) return res.status(404).json({ error: 'Tarefa nao encontrada' });
  await task.destroy();
  res.status(204).end();
});

// --- Health check ---
app.get('/health', (_req, res) => res.json({ status: 'UP' }));

// --- Inicializacao ---
async function start() {
  await sequelize.sync();

  // Criar usuario admin padrao
  const admin = await User.findOne({ where: { username: 'admin' } });
  if (!admin) {
    const hash = await bcrypt.hash('admin123', 10);
    await User.create({ username: 'admin', password: hash, name: 'Administrador', role: 'ADMIN' });
    console.log('Usuario admin criado (admin / admin123)');
  }

  app.listen(PORT, () => console.log(`API rodando na porta ${PORT}`));
}

start().catch(err => {
  console.error('Erro ao iniciar:', err.message);
  process.exit(1);
});
