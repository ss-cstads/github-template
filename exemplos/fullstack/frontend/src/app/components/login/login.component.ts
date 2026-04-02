import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="login-container">
      <div class="card login-card">
        <h2>{{ isRegister ? 'Criar Conta' : 'Login' }}</h2>
        <p class="subtitle">Task Manager — IFSUL</p>

        <div *ngIf="error" class="alert alert-error">{{ error }}</div>

        <form (ngSubmit)="submit()">
          <div *ngIf="isRegister" class="form-group">
            <label>Nome Completo</label>
            <input type="text" [(ngModel)]="name" name="name"
                   placeholder="Seu nome" required>
          </div>

          <div class="form-group">
            <label>Usuario</label>
            <input type="text" [(ngModel)]="username" name="username"
                   placeholder="Seu usuario" required>
          </div>

          <div class="form-group">
            <label>Senha</label>
            <input type="password" [(ngModel)]="password" name="password"
                   placeholder="Sua senha" required>
          </div>

          <button type="submit" class="btn btn-primary btn-block" [disabled]="loading">
            {{ loading ? 'Aguarde...' : (isRegister ? 'Criar Conta' : 'Entrar') }}
          </button>
        </form>

        <p class="toggle-link">
          {{ isRegister ? 'Ja tem conta?' : 'Nao tem conta?' }}
          <a href="#" (click)="toggleMode($event)">
            {{ isRegister ? 'Faca login' : 'Cadastre-se' }}
          </a>
        </p>
      </div>
    </div>
  `,
  styles: [`
    .login-container {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 60vh;
    }
    .login-card {
      width: 100%;
      max-width: 400px;
    }
    h2 {
      margin-bottom: 4px;
      color: var(--primary);
    }
    .subtitle {
      color: var(--text-muted);
      margin-bottom: 24px;
      font-size: 14px;
    }
    .form-group {
      margin-bottom: 16px;
    }
    .form-group label {
      display: block;
      margin-bottom: 4px;
      font-size: 14px;
      font-weight: 500;
    }
    .btn-block {
      width: 100%;
      margin-top: 8px;
    }
    .toggle-link {
      text-align: center;
      margin-top: 16px;
      font-size: 14px;
    }
    .toggle-link a {
      color: var(--primary);
      text-decoration: none;
      font-weight: 500;
    }
  `]
})
export class LoginComponent {
  username = '';
  password = '';
  name = '';
  error = '';
  loading = false;
  isRegister = false;

  constructor(private auth: AuthService, private router: Router) {
    if (auth.isLoggedIn()) {
      router.navigate(['/']);
    }
  }

  toggleMode(event: Event): void {
    event.preventDefault();
    this.isRegister = !this.isRegister;
    this.error = '';
  }

  submit(): void {
    this.loading = true;
    this.error = '';

    const obs = this.isRegister
      ? this.auth.register(this.username, this.password, this.name)
      : this.auth.login(this.username, this.password);

    obs.subscribe({
      next: () => {
        this.router.navigate(['/']);
      },
      error: (err) => {
        this.loading = false;
        this.error = err.error?.error || 'Erro ao autenticar. Verifique suas credenciais.';
      }
    });
  }
}
