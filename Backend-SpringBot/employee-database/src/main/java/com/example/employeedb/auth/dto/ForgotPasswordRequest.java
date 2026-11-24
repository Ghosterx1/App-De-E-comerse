package com.example.employeedb.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** Solicitud de restablecimiento de contraseña (envía email con token). */
public record ForgotPasswordRequest(
        @Email(message = "El correo debe tener un formato válido.")
        @NotBlank(message = "El correo es obligatorio.")
        String email) {
}
