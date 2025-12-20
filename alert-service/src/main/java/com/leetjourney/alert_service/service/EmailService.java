package com.leetjourney.alert_service.service;

import com.leetjourney.alert_service.entity.Alert;
import com.leetjourney.alert_service.repository.AlertRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class EmailService {

    private final JavaMailSender mailSender;
    private final AlertRepository alertRepository;

    public EmailService(JavaMailSender mailSender,
                        AlertRepository alertRepository) {
        this.mailSender = mailSender;
        this.alertRepository = alertRepository;
    }

    public void sendEmail(String to,
                          String subject,
                          String body,
                          Long userId) {
        log.info("Sending email to: {}, subject: {}", to, subject);

        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(to);
        message.setFrom("noreply@leetjourney.com");
        message.setSubject(subject);
        message.setText(body);

        try {
            mailSender.send(message);

            final Alert alertSent = Alert.builder()
                    .sent(true)
                    .createdAt(java.time.LocalDateTime.now())
                    .userId(userId)
                    .build();

            alertRepository.saveAndFlush(alertSent);

        } catch (MailException e) {
            log.error("Failed to send email to: {}", to, e);

            final Alert alertSent = Alert.builder()
                    .sent(false)
                    .createdAt(java.time.LocalDateTime.now())
                    .userId(userId)
                    .build();
            alertRepository.saveAndFlush(alertSent);
            return;
        }

        log.info("Email sent to: {}", to);
    }
}
