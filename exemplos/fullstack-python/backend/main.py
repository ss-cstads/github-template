import os
from datetime import datetime, timedelta, timezone
from contextlib import asynccontextmanager

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Boolean, Text, DateTime, ForeignKey
from sqlalchemy.orm import sessionmaker, declarative_base, relationship, Session
from passlib.context import CryptContext
from jose import jwt, JWTError

# --- Configuracao ---
DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = os.environ.get("DB_PORT", "3306")
DB_NAME = os.environ.get("DB_NAME", "taskdb")
DB_USER = os.environ.get("DB_USER", "taskapi")
DB_PASS = os.environ.get("DB_PASSWORD", "password")
JWT_SECRET = os.environ.get("JWT_SECRET", "dev-secret-change-me")
JWT_ALGORITHM = "HS256"
JWT_EXPIRE_HOURS = 24

DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()
pwd = CryptContext(schemes=["bcrypt"])
security = HTTPBearer()

# --- Modelos ---
class UserModel(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    name = Column(String(100), nullable=False)
    role = Column(String(20), default="USER")
    tasks = relationship("TaskModel", back_populates="user")

class TaskModel(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, default="")
    completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc),
                        onupdate=lambda: datetime.now(timezone.utc))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    user = relationship("UserModel", back_populates="tasks")

# --- Schemas ---
class RegisterReq(BaseModel):
    username: str
    password: str
    name: str

class LoginReq(BaseModel):
    username: str
    password: str

class AuthRes(BaseModel):
    token: str
    username: str
    name: str
    role: str

class TaskReq(BaseModel):
    title: str
    description: str = ""
    completed: bool = False

class TaskRes(BaseModel):
    id: int
    title: str
    description: str
    completed: bool
    createdAt: str
    updatedAt: str | None

    class Config:
        from_attributes = True

# --- Helpers ---
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_token(user_id: int, username: str) -> str:
    exp = datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRE_HOURS)
    return jwt.encode({"id": user_id, "username": username, "exp": exp}, JWT_SECRET, JWT_ALGORITHM)

def get_current_user(creds: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)) -> UserModel:
    try:
        payload = jwt.decode(creds.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user = db.query(UserModel).filter(UserModel.id == payload["id"]).first()
        if not user:
            raise HTTPException(status_code=401, detail="Usuario nao encontrado")
        return user
    except JWTError:
        raise HTTPException(status_code=401, detail="Token invalido")

def task_to_res(t: TaskModel) -> TaskRes:
    return TaskRes(
        id=t.id, title=t.title, description=t.description, completed=t.completed,
        createdAt=t.created_at.isoformat() if t.created_at else "",
        updatedAt=t.updated_at.isoformat() if t.updated_at else None,
    )

# --- App ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    if not db.query(UserModel).filter(UserModel.username == "admin").first():
        admin = UserModel(username="admin", password=pwd.hash("admin123"), name="Administrador", role="ADMIN")
        db.add(admin)
        db.commit()
        print("Usuario admin criado (admin / admin123)")
    db.close()
    yield

app = FastAPI(title="Task API", lifespan=lifespan)

# --- Autenticacao ---
@app.post("/api/auth/register", response_model=AuthRes, status_code=201)
def register(req: RegisterReq, db: Session = Depends(get_db)):
    if db.query(UserModel).filter(UserModel.username == req.username).first():
        raise HTTPException(status_code=409, detail="Usuario ja existe")
    user = UserModel(username=req.username, password=pwd.hash(req.password), name=req.name)
    db.add(user)
    db.commit()
    db.refresh(user)
    return AuthRes(token=create_token(user.id, user.username), username=user.username, name=user.name, role=user.role)

@app.post("/api/auth/login", response_model=AuthRes)
def login(req: LoginReq, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.username == req.username).first()
    if not user or not pwd.verify(req.password, user.password):
        raise HTTPException(status_code=401, detail="Credenciais invalidas")
    return AuthRes(token=create_token(user.id, user.username), username=user.username, name=user.name, role=user.role)

# --- Tarefas ---
@app.get("/api/tasks", response_model=list[TaskRes])
def list_tasks(user: UserModel = Depends(get_current_user), db: Session = Depends(get_db)):
    tasks = db.query(TaskModel).filter(TaskModel.user_id == user.id).order_by(TaskModel.created_at.desc()).all()
    return [task_to_res(t) for t in tasks]

@app.post("/api/tasks", response_model=TaskRes, status_code=201)
def create_task(req: TaskReq, user: UserModel = Depends(get_current_user), db: Session = Depends(get_db)):
    task = TaskModel(title=req.title, description=req.description, completed=req.completed, user_id=user.id)
    db.add(task)
    db.commit()
    db.refresh(task)
    return task_to_res(task)

@app.put("/api/tasks/{task_id}", response_model=TaskRes)
def update_task(task_id: int, req: TaskReq, user: UserModel = Depends(get_current_user), db: Session = Depends(get_db)):
    task = db.query(TaskModel).filter(TaskModel.id == task_id, TaskModel.user_id == user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Tarefa nao encontrada")
    task.title = req.title
    task.description = req.description
    task.completed = req.completed
    db.commit()
    db.refresh(task)
    return task_to_res(task)

@app.delete("/api/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, user: UserModel = Depends(get_current_user), db: Session = Depends(get_db)):
    task = db.query(TaskModel).filter(TaskModel.id == task_id, TaskModel.user_id == user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Tarefa nao encontrada")
    db.delete(task)
    db.commit()

# --- Health check ---
@app.get("/health")
def health():
    return {"status": "UP"}
