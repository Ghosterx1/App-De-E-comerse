package com.example.employeedb.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Solicitud de restablecimiento de contraseña con token y nueva contraseña. */
public record ResetPasswordRequest(
        @NotBlank(message = "El token es obligatorio.")
        String token,

        @NotBlank(message = "La nueva contraseña es obligatoria.")
        @Size(min = 6, message = "La contraseña debe tener al menos 6 caracteres.")
        String newPassword) {
}
