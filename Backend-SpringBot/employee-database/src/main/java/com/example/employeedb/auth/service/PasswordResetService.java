package com.example.employeedb.auth.service;

import com.example.employeedb.auth.dto.ResetPasswordRequest;
import com.example.employeedb.auth.entity.PasswordResetToken;
import com.example.employeedb.auth.entity.User;
import com.example.employeedb.auth.repository.PasswordResetTokenRepository;
import com.example.employeedb.auth.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Servicio de restablecimiento de contraseña.
 *
 * Flujo seguro:
 * 1. El usuario solicita restablecimiento con su email.
 * 2. Se genera un token UUID de un solo uso, válido por 1 hora.
 * 3. Se envía el token por correo (en desarrollo se escribe en logs si no hay SMTP).
 * 4. El usuario presenta el token y la nueva contraseña.
 * 5. Se valida el token (existencia, expiración, uso previo) y se actualiza la contraseña hasheada.
 *
 * Notas de seguridad:
 * - No se revela si el email existe o no (previene enumeración de usuarios).
 * - Los tokens son de un solo uso y se marcan como USED tras restablecer.
 * - La contraseña se almacena hasheada con BCrypt (nunca en texto plano).
 */
@Service
@Transactional(readOnly = true)
public class PasswordResetService {

    private static final int TOKEN_EXPIRATION_HOURS = 1;

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    public PasswordResetService(UserRepository userRepository,
                                PasswordResetTokenRepository tokenRepository,
                                EmailService emailService,
                                PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.tokenRepository = tokenRepository;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Solicita un token de restablecimiento para el email dado.
     * Siempre retorna un mensaje genérico, independientemente de si el email existe,
     * para evitar ataques de enumeración de usuarios.
     */
    @Transactional
    public String requestReset(String email) {
        User user = userRepository.findByEmail(email).orElse(null);

        if (user != null && user.isEnabled()) {
            // Invalidar tokens activos previos del usuario (una sesión a la vez)
            tokenRepository.findAll().stream()
                    .filter(t -> t.getUser().equals(user) && t.getStatus() == PasswordResetToken.Status.ACTIVE)
                    .forEach(t -> t.setStatus(PasswordResetToken.Status.USED));

            String tokenValue = UUID.randomUUID().toString();
            LocalDateTime expiry = LocalDateTime.now().plusHours(TOKEN_EXPIRATION_HOURS);

            PasswordResetToken token = new PasswordResetToken(tokenValue, user, expiry);
            tokenRepository.save(token);

            emailService.sendSimpleMessage(
                    user.getEmail(),
                    "Restablecimiento de contraseña",
                    "Hola " + user.getUsername() + ",\n\n"
                            + "Usa el siguiente token para restablecer tu contraseña:\n"
                            + tokenValue + "\n\n"
                            + "El token expira en " + TOKEN_EXPIRATION_HOURS + " hora(s).\n"
                            + "Si no solicitaste este cambio, ignora este mensaje."
            );
        }

        // Mensaje genérico: no se revela si el email está registrado.
        return "Si el correo existe y está activo, recibirás un token de restablecimiento.";
    }

    /**
     * Restablece la contraseña usando un token válido y no usado.
     */
    @Transactional
    public String resetPassword(ResetPasswordRequest request) {
        PasswordResetToken token = tokenRepository.findByToken(request.token())
                .orElseThrow(() -> new RuntimeException("Token inválido o inexistente."));

        if (token.isExpired()) {
            token.setStatus(PasswordResetToken.Status.EXPIRED);
            tokenRepository.save(token);
            throw new RuntimeException("El token ha expirado. Solicita uno nuevo.");
        }

        if (token.getStatus() == PasswordResetToken.Status.USED) {
            throw new RuntimeException("El token ya fue utilizado.");
        }

        User user = token.getUser();
        user.setPassword(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);

        token.setStatus(PasswordResetToken.Status.USED);
        tokenRepository.save(token);

        return "Contraseña restablecida con éxito.";
    }
}
