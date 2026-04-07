package br.edu.ifsul.taskapi.repository;

import br.edu.ifsul.taskapi.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TaskRepository extends JpaRepository<Task, Long> {
    List<Task> findByUserIdOrderByCreatedAtDesc(Long userId);
    Optional<Task> findByIdAndUserId(Long id, Long userId);
}
