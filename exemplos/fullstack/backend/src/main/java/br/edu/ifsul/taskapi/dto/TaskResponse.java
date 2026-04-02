package br.edu.ifsul.taskapi.dto;

import br.edu.ifsul.taskapi.entity.Task;
import java.time.LocalDateTime;

public record TaskResponse(
    Long id,
    String title,
    String description,
    boolean completed,
    LocalDateTime createdAt,
    LocalDateTime updatedAt
) {
    public static TaskResponse from(Task task) {
        return new TaskResponse(
            task.getId(),
            task.getTitle(),
            task.getDescription(),
            task.isCompleted(),
            task.getCreatedAt(),
            task.getUpdatedAt()
        );
    }
}
