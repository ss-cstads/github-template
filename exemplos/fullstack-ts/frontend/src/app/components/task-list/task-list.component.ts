import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TaskService, Task } from '../../services/task.service';
import { TaskFormComponent } from '../task-form/task-form.component';

@Component({
  selector: 'app-task-list',
  standalone: true,
  imports: [CommonModule, TaskFormComponent],
  template: `
    <div class="header">
      <h1>Minhas Tarefas</h1>
      <button class="btn btn-primary" (click)="showForm = !showForm">
        {{ showForm ? 'Cancelar' : '+ Nova Tarefa' }}
      </button>
    </div>

    <app-task-form *ngIf="showForm" (saved)="onTaskSaved()"></app-task-form>

    <div *ngIf="tasks.length === 0 && !loading" class="empty-state card">
      <p>Nenhuma tarefa ainda. Clique em <strong>+ Nova Tarefa</strong> para comecar!</p>
    </div>

    <div class="task-list">
      <div *ngFor="let task of tasks" class="card task-item" [class.completed]="task.completed">
        <div class="task-content">
          <div class="task-check">
            <input type="checkbox" [checked]="task.completed" (change)="toggleComplete(task)">
          </div>
          <div class="task-info">
            <h3 [class.task-done]="task.completed">{{ task.title }}</h3>
            <p *ngIf="task.description" class="task-desc">{{ task.description }}</p>
            <span class="task-date">{{ task.createdAt | date:'dd/MM/yyyy HH:mm' }}</span>
          </div>
          <div class="task-actions">
            <button class="btn btn-sm btn-danger" (click)="deleteTask(task)">Excluir</button>
          </div>
        </div>
      </div>
    </div>

    <div *ngIf="tasks.length > 0" class="stats">
      {{ completedCount }} de {{ tasks.length }} tarefas concluidas
    </div>
  `,
  styles: [`
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }
    h1 { font-size: 24px; }
    .task-item { transition: opacity 0.2s; }
    .task-item.completed { opacity: 0.7; }
    .task-content {
      display: flex;
      align-items: flex-start;
      gap: 12px;
    }
    .task-check { padding-top: 3px; }
    .task-check input[type="checkbox"] {
      width: 18px;
      height: 18px;
      cursor: pointer;
    }
    .task-info { flex: 1; }
    .task-info h3 {
      font-size: 16px;
      margin-bottom: 4px;
    }
    .task-done {
      text-decoration: line-through;
      color: var(--text-muted);
    }
    .task-desc {
      color: var(--text-muted);
      font-size: 14px;
      margin-bottom: 4px;
    }
    .task-date {
      font-size: 12px;
      color: var(--text-muted);
    }
    .task-actions {
      flex-shrink: 0;
    }
    .empty-state {
      text-align: center;
      padding: 40px;
      color: var(--text-muted);
    }
    .stats {
      text-align: center;
      margin-top: 16px;
      font-size: 14px;
      color: var(--text-muted);
    }
  `]
})
export class TaskListComponent implements OnInit {
  tasks: Task[] = [];
  showForm = false;
  loading = true;

  constructor(private taskService: TaskService) {}

  get completedCount(): number {
    return this.tasks.filter(t => t.completed).length;
  }

  ngOnInit(): void {
    this.loadTasks();
  }

  loadTasks(): void {
    this.loading = true;
    this.taskService.list().subscribe({
      next: tasks => {
        this.tasks = tasks;
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  onTaskSaved(): void {
    this.showForm = false;
    this.loadTasks();
  }

  toggleComplete(task: Task): void {
    this.taskService.update(task.id, {
      title: task.title,
      description: task.description,
      completed: !task.completed
    }).subscribe(() => this.loadTasks());
  }

  deleteTask(task: Task): void {
    if (confirm(`Excluir "${task.title}"?`)) {
      this.taskService.delete(task.id).subscribe(() => this.loadTasks());
    }
  }
}
