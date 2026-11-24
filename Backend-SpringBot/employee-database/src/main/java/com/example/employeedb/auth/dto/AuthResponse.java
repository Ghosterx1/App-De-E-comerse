package com.example.employeedb.auth.dto;

/** Respuesta de autenticación: token JWT y datos del usuario. */
public record AuthResponse(
        String token,
        String email,
        String username,
        String role) {
}
