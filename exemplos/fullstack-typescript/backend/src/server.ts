import express, { Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

const app = express();
app.use(express.json());

const prisma = new PrismaClient();

const PORT = Number(process.env.PORT) || 8080;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

// --- Tipos ---
interface JwtPayload { id: number; username: string; }
interface AuthRequest extends Request { userId?: number; }

// --- Middleware de autenticacao ---
function auth(req: AuthRequest, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Token nao fornecido' });
    return;
  }
  try {
    const payload = jwt.verify(header.slice(7), JWT_SECRET) as JwtPayload;
    req.userId = payload.id;
    next();
  } catch {
    res.status(401).json({ error: 'Token invalido' });
  }
}

// --- Autenticacao ---
app.post('/api/auth/register', async (req: Request, res: Response) => {
  try {
    const { username, password, name } = req.body;
    if (!username || !password || !name) {
      res.status(400).json({ error: 'Campos obrigatorios: username, password, name' });
      return;
    }
    const exists = await prisma.user.findUnique({ where: { username } });
    if (exists) { res.status(409).json({ error: 'Usuario ja existe' }); return; }

    const hash = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({ data: { username, password: hash, name } });
    const token = jwt.sign({ id: user.id, username }, JWT_SECRET, { expiresIn: '24h' });
    res.status(201).json({ token, username, name: user.name, role: user.role });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/login', async (req: Request, res: Response) => {
  try {
    const { username, password } = req.body;
    const user = await prisma.user.findUnique({ where: { username } });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      res.status(401).json({ error: 'Credenciais invalidas' });
      return;
    }
    const token = jwt.sign({ id: user.id, username }, JWT_SECRET, { expiresIn: '24h' });
    res.json({ token, username, name: user.name, role: user.role });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// --- Tarefas ---
app.get('/api/tasks', auth, async (req: AuthRequest, res: Response) => {
  const tasks = await prisma.task.findMany({
    where: { userId: req.userId },
    orderBy: { createdAt: 'desc' },
  });
  res.json(tasks);
});

app.post('/api/tasks', auth, async (req: AuthRequest, res: Response) => {
  const { title, description, completed } = req.body;
  const task = await prisma.task.create({
    data: { title, description, completed, userId: req.userId! },
  });
  res.status(201).json(task);
});

app.put('/api/tasks/:id', auth, async (req: AuthRequest, res: Response) => {
  const id = Number(req.params.id);
  const task = await prisma.task.findFirst({ where: { id, userId: req.userId } });
  if (!task) { res.status(404).json({ error: 'Tarefa nao encontrada' }); return; }
  const { title, description, completed } = req.body;
  const updated = await prisma.task.update({ where: { id }, data: { title, description, completed } });
  res.json(updated);
});

app.delete('/api/tasks/:id', auth, async (req: AuthRequest, res: Response) => {
  const id = Number(req.params.id);
  const task = await prisma.task.findFirst({ where: { id, userId: req.userId } });
  if (!task) { res.status(404).json({ error: 'Tarefa nao encontrada' }); return; }
  await prisma.task.delete({ where: { id } });
  res.status(204).end();
});

// --- Health check ---
app.get('/health', (_req: Request, res: Response) => res.json({ status: 'UP' }));

// --- Inicializacao ---
async function start() {
  // Criar usuario admin padrao
  const admin = await prisma.user.findUnique({ where: { username: 'admin' } });
  if (!admin) {
    const hash = await bcrypt.hash('admin123', 10);
    await prisma.user.create({
      data: { username: 'admin', password: hash, name: 'Administrador', role: 'ADMIN' },
    });
    console.log('Usuario admin criado (admin / admin123)');
  }

  app.listen(PORT, () => console.log(`API rodando na porta ${PORT}`));
}

start().catch(err => {
  console.error('Erro ao iniciar:', err.message);
  process.exit(1);
});
