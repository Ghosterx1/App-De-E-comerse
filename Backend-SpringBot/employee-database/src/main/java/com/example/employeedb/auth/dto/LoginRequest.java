package com.example.employeedb.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** Datos de entrada para iniciar sesión. */
public record LoginRequest(
        @Email(message = "El correo debe tener un formato válido.")
        @NotBlank(message = "El correo es obligatorio.")
        String email,

        @NotBlank(message = "La contraseña es obligatoria.")
        String password) {
}
