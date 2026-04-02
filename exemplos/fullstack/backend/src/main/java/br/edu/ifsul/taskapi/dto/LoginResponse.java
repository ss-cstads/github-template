package br.edu.ifsul.taskapi.dto;

public record LoginResponse(
    String token,
    String username,
    String name,
    String role
) {}
