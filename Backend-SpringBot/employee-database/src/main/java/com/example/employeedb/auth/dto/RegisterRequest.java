package com.example.employeedb.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Datos de entrada para registrar un nuevo usuario. */
public record RegisterRequest(
        @NotBlank(message = "El nombre de usuario es obligatorio.")
        @Size(max = 60, message = "El nombre no puede superar 60 caracteres.")
        String username,

        @Email(message = "El correo debe tener un formato válido.")
        @NotBlank(message = "El correo es obligatorio.")
        @Size(max = 120, message = "El correo no puede superar 120 caracteres.")
        String email,

        @NotBlank(message = "La contraseña es obligatoria.")
        @Size(min = 6, message = "La contraseña debe tener al menos 6 caracteres.")
        String password) {
}
