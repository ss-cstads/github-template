import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Task {
  id: number;
  title: string;
  description: string;
  completed: boolean;
  createdAt: string;
  updatedAt: string | null;
}

export interface TaskRequest {
  title: string;
  description: string;
  completed: boolean;
}

@Injectable({ providedIn: 'root' })
export class TaskService {
  private readonly API = '/api/tasks';

  constructor(private http: HttpClient) {}

  list(): Observable<Task[]> {
    return this.http.get<Task[]>(this.API);
  }

  create(task: TaskRequest): Observable<Task> {
    return this.http.post<Task>(this.API, task);
  }

  update(id: number, task: TaskRequest): Observable<Task> {
    return this.http.put<Task>(`${this.API}/${id}`, task);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.API}/${id}`);
  }
}
