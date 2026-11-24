package com.example.employeedb.auth.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Servicio de envío de correos electrónicos.
 *
 * En desarrollo, si no hay un servidor SMTP configurado, el correo se escribe
 * en los logs para evitar fallos de arranque y permitir pruebas locales.
 */
@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;
    private final String fromAddress;

    public EmailService(JavaMailSender mailSender,
                        @Value("${app.mail.from:noreply@ecommerce.local}") String fromAddress) {
        this.mailSender = mailSender;
        this.fromAddress = fromAddress;
    }

    public void sendSimpleMessage(String to, String subject, String text) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(to);
            message.setSubject(subject);
            message.setText(text);
            mailSender.send(message);
            log.info("Correo enviado a {}", to);
        } catch (Exception ex) {
            // En entorno de desarrollo sin SMTP, escribir el contenido en los logs
            // para que el equipo de QA pueda obtener el token de prueba.
            log.warn("No se pudo enviar correo a {}. Contenido del correo (modo desarrollo):\n"
                    + "Para: {}\nAsunto: {}\nCuerpo:\n{}", to, to, subject, text);
        }
    }
}
