import { Component, EventEmitter, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TaskService } from '../../services/task.service';

@Component({
  selector: 'app-task-form',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="card form-card">
      <h3>Nova Tarefa</h3>
      <form (ngSubmit)="submit()">
        <div class="form-group">
          <input type="text" [(ngModel)]="title" name="title"
                 placeholder="Titulo da tarefa" required autofocus>
        </div>
        <div class="form-group">
          <textarea [(ngModel)]="description" name="description"
                    placeholder="Descricao (opcional)" rows="3"></textarea>
        </div>
        <div class="form-actions">
          <button type="submit" class="btn btn-primary" [disabled]="!title.trim() || saving">
            {{ saving ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>
      </form>
    </div>
  `,
  styles: [`
    .form-card {
      border-left: 4px solid var(--primary);
      margin-bottom: 24px;
    }
    h3 { margin-bottom: 16px; color: var(--primary); }
    .form-group { margin-bottom: 12px; }
    .form-actions { text-align: right; }
  `]
})
export class TaskFormComponent {
  @Output() saved = new EventEmitter<void>();

  title = '';
  description = '';
  saving = false;

  constructor(private taskService: TaskService) {}

  submit(): void {
    if (!this.title.trim()) return;
    this.saving = true;

    this.taskService.create({
      title: this.title,
      description: this.description,
      completed: false
    }).subscribe({
      next: () => {
        this.title = '';
        this.description = '';
        this.saving = false;
        this.saved.emit();
      },
      error: () => { this.saving = false; }
    });
  }
}
