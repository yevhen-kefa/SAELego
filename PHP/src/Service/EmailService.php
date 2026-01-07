<?php
require_once __DIR__ . '/../../vendor/phpmailer/src/Exception.php';
require_once __DIR__ . '/../../vendor/phpmailer/src/PHPMailer.php';
require_once __DIR__ . '/../../vendor/phpmailer/src/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

class EmailService {
    public static function sendEmail(string $to, string $subject, string $body): bool {
        $config = require __DIR__ . '/../../config/mail.php';

        $mail = new PHPMailer(true);
        try {
            $mail->isSMTP();
            $mail->Host       = $config['smtp_host'];
            $mail->SMTPAuth   = true;
            $mail->Username   = $config['smtp_user'];
            $mail->Password   = $config['smtp_pass'];
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port       = $config['smtp_port'];
            $mail->CharSet    = 'UTF-8';
            $fromEmail = $config['from_email'] ?? $config['smtp_user'];
            $fromName  = $config['from_name'] ?? 'IMG2BRICK';
            $mail->setFrom($fromEmail, $fromName);
            $mail->addAddress($to);
            $mail->isHTML(true);
            $mail->Subject = $subject;
            $mail->Body    = $body;
            $mail->AltBody = strip_tags($body);

            $mail->send();
            return true;
        } catch (Exception $e) {
            error_log("Erreur d'envoi email : {$mail->ErrorInfo}");
            return false;
        }
    }

    public static function send2FACode($email, $code) {
        $subject = "Votre code de connexion - SAELego";
        $body = "
        <div style='font-family: Arial, sans-serif; color: #333;'>
            <h2>Bonjour,</h2>
            <p>Voici votre code de vérification pour vous connecter à <strong>SAELego</strong> :</p>
            <h1 style='color: #0d6efd; letter-spacing: 5px;'>$code</h1>
            <p>Ce code est valable <strong>1 minute</strong>.</p>
            <hr>
            <small>Ceci est un email automatique du projet universitaire SAELego.</small>
        </div>";

        return self::sendEmail($email, $subject, $body);
    }
}