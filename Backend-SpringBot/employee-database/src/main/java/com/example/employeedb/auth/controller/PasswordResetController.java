package com.example.employeedb.auth.controller;

import com.example.employeedb.auth.dto.ForgotPasswordRequest;
import com.example.employeedb.auth.dto.ResetPasswordRequest;
import com.example.employeedb.auth.service.PasswordResetService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Controlador de restablecimiento de contraseña.
 * Los endpoints son públicos (no requieren autenticación previa).
 */
@RestController
@RequestMapping("/api/v1/auth")
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    public PasswordResetController(PasswordResetService passwordResetService) {
        this.passwordResetService = passwordResetService;
    }

    /**
     * Solicita restablecimiento de contraseña.
     * Envía un token por correo al usuario (o escribe en logs en desarrollo sin SMTP).
     */
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request) {
        String message = passwordResetService.requestReset(request.email());
        return ResponseEntity.ok(Map.of("message", message));
    }

    /**
     * Restablece la contraseña usando un token válido y una nueva contraseña.
     */
    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request) {
        String message = passwordResetService.resetPassword(request);
        return ResponseEntity.ok(Map.of("message", message));
    }
}
