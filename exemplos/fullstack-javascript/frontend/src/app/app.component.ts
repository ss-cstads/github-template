import { Component } from '@angular/core';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from './services/auth.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule],
  template: `
    <header class="navbar">
      <div class="container navbar-content">
        <a routerLink="/" class="logo">Task Manager</a>
        <nav *ngIf="auth.isLoggedIn()">
          <span class="user-info">{{ auth.getUser()?.name }}</span>
          <button class="btn btn-sm btn-danger" (click)="logout()">Sair</button>
        </nav>
      </div>
    </header>
    <main class="container main-content">
      <router-outlet></router-outlet>
    </main>
    <footer class="footer">
      <div class="container">
        IFSUL — Campus Sapucaia do Sul | Cluster HashiCorp
      </div>
    </footer>
  `,
  styles: [`
    .navbar {
      background: var(--primary);
      color: white;
      padding: 12px 0;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .navbar-content {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .logo {
      color: white;
      text-decoration: none;
      font-size: 20px;
      font-weight: 700;
    }
    .user-info {
      margin-right: 12px;
      font-size: 14px;
      opacity: 0.9;
    }
    .main-content {
      padding: 32px 20px;
      min-height: calc(100vh - 130px);
    }
    .footer {
      text-align: center;
      padding: 16px 0;
      color: var(--text-muted);
      font-size: 13px;
      border-top: 1px solid var(--border);
    }
    nav {
      display: flex;
      align-items: center;
    }
  `]
})
export class AppComponent {
  constructor(public auth: AuthService, private router: Router) {}

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/login']);
  }
}
