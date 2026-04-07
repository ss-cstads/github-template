package br.edu.ifsul.taskapi.controller;

import br.edu.ifsul.taskapi.dto.TaskRequest;
import br.edu.ifsul.taskapi.dto.TaskResponse;
import br.edu.ifsul.taskapi.entity.Task;
import br.edu.ifsul.taskapi.repository.TaskRepository;
import br.edu.ifsul.taskapi.repository.UserRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {

    private final TaskRepository taskRepository;
    private final UserRepository userRepository;

    public TaskController(TaskRepository taskRepository, UserRepository userRepository) {
        this.taskRepository = taskRepository;
        this.userRepository = userRepository;
    }

    @GetMapping
    public List<TaskResponse> list(Authentication auth) {
        var user = userRepository.findByUsername(auth.getName()).orElseThrow();
        return taskRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(TaskResponse::from)
                .toList();
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> get(@PathVariable Long id, Authentication auth) {
        var user = userRepository.findByUsername(auth.getName()).orElseThrow();
        return taskRepository.findByIdAndUserId(id, user.getId())
                .map(task -> ResponseEntity.ok(TaskResponse.from(task)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<TaskResponse> create(@Valid @RequestBody TaskRequest request, Authentication auth) {
        var user = userRepository.findByUsername(auth.getName()).orElseThrow();

        var task = new Task();
        task.setTitle(request.title());
        task.setDescription(request.description());
        task.setCompleted(request.completed());
        task.setUser(user);

        var saved = taskRepository.save(task);
        return ResponseEntity.status(HttpStatus.CREATED).body(TaskResponse.from(saved));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @Valid @RequestBody TaskRequest request,
                                    Authentication auth) {
        var user = userRepository.findByUsername(auth.getName()).orElseThrow();

        return taskRepository.findByIdAndUserId(id, user.getId())
                .map(task -> {
                    task.setTitle(request.title());
                    task.setDescription(request.description());
                    task.setCompleted(request.completed());
                    return ResponseEntity.ok(TaskResponse.from(taskRepository.save(task)));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id, Authentication auth) {
        var user = userRepository.findByUsername(auth.getName()).orElseThrow();

        return taskRepository.findByIdAndUserId(id, user.getId())
                .map(task -> {
                    taskRepository.delete(task);
                    return ResponseEntity.ok(Map.of("message", "Tarefa removida"));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
