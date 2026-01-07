<?php
require_once __DIR__ . '/../Manager/UserManager.php';
require_once __DIR__ . '/../Service/UserSession.php';
require_once __DIR__ . '/../Service/EmailService.php';
require_once __DIR__ . '/../Service/Captcha.php';

class AuthController {

    public function login() {
        $error = null;

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {

            $captchaConfig = require __DIR__ . '/../../config/captchaConfig.php';
            $captchaService = new Captcha($captchaConfig['turnstile_secret']);
            $token = $_POST['cf-turnstile-response'] ?? '';

            if (!$captchaService->isValid($token, $_SERVER['REMOTE_ADDR'])) {
                $error = "Veuillez valider la sécurité (Captcha).";
            }
            else {
                $manager = new UserManager();
                $user = $manager->verifyPassword($_POST['username'], $_POST['password']);

                if ($user) {
                    $code = $manager->generate2FACode($user);

                    EmailService::send2FACode($user->getEmail(), $code);

                    if (session_status() === PHP_SESSION_NONE) session_start();
                    $_SESSION['2fa_user_id'] = $user->getIdUser();

                    header('Location: index.php?page=2fa');
                    exit;
                } else {
                    $error = "Identifiants incorrects.";
                }
            }
        }
        require __DIR__ . '/../../templates/login.php';
    }

    public function register() {
        $error = null;

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {

            $captchaConfig = require __DIR__ . '/../../config/captchaConfig.php';
            $captchaService = new Captcha($captchaConfig['turnstile_secret']);
            $token = $_POST['cf-turnstile-response'] ?? '';
            if (!$captchaService->isValid($token, $_SERVER['REMOTE_ADDR'])) {
                $error = "Veuillez valider la sécurité (Captcha).";
            }
            else {
                $pwd = $_POST['password'];
                if (strlen($pwd) < 12 ||
                    !preg_match('/[A-Z]/', $pwd) ||
                    !preg_match('/[a-z]/', $pwd) ||
                    !preg_match('/[0-9]/', $pwd) ||
                    !preg_match('/[\W]/', $pwd)) {

                    $error = "Le mot de passe doit respecter la norme CNIL : 12 caractères minimum, avec majuscule, minuscule, chiffre et caractère spécial.";
                }
                else {
                    $user = new User([
                        'username'     => $_POST['username'],
                        'email'        => $_POST['email'],
                        'password'     => $_POST['password'],
                        'firstname'    => $_POST['firstname'] ?? '',
                        'lastname'     => $_POST['lastname'] ?? '',
                        'phone_number' => $_POST['phone_number'] ?? '',
                        'birth_year'   => $_POST['birth_year'] ?? 0,
                        'address'      => $_POST['address'] ?? '',
                        'role'         => 'user'
                    ]);

                    $manager = new UserManager();
                    try {
                        if ($manager->register($user)) {
                            header('Location: index.php?page=login');
                            exit;
                        } else {
                            $error = "Erreur lors de l'inscription.";
                        }
                    } catch (Exception $e) {
                        $error = "Ce nom d'utilisateur ou email est déjà pris.";
                    }
                }
            }
        }
        require __DIR__ . '/../../templates/register.php';
    }

    public function verify2FA() {
        if (session_status() === PHP_SESSION_NONE) session_start();

        if (!isset($_SESSION['2fa_user_id'])) {
            header('Location: index.php?page=login');
            exit;
        }

        $error = null;
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $code = $_POST['code'];
            $manager = new UserManager();
            $user = $manager->verify2FACode($_SESSION['2fa_user_id'], $code);

            if ($user) {
                UserSession::login($user->getIdUser(), $user->getUsername(), $user->getRole());

                unset($_SESSION['2fa_user_id']);
                header('Location: index.php?page=home');
                exit;
            } else {
                $error = "Code invalide ou expiré.";
            }
        }
        require __DIR__ . '/../../templates/2fa.php';
    }

    public function logout() {
        UserSession::logout();
        header('Location: index.php?page=login');
        exit;
    }

    public function profile() {
        if (!UserSession::isAuthenticated()) {
            header('Location: index.php?page=login');
            exit;
        }

        $manager = new UserManager();
        $user = $manager->getUserById(UserSession::getUserId());
        $message = null;

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $user->setFirstname($_POST['firstname']);
            $user->setLastname($_POST['lastname']);
            $user->setAddress($_POST['address']);
            $user->setPhoneNumber($_POST['phone']);
            $user->setEmail($_POST['email']);

            if ($manager->updateProfile($user)) {
                $message = "Profil mis à jour avec succès.";
            }
        }

        require __DIR__ . '/../../templates/profile.php';
    }

    public function forgotPassword() {
        $message = null;
        $error = null;

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $email = $_POST['email'];
            $pdo = Database::getInstance();

            $stmt = $pdo->prepare("SELECT user_id, nickname FROM users WHERE email = ?");
            $stmt->execute([$email]);
            $user = $stmt->fetch();

            if ($user) {
                $token = bin2hex(random_bytes(32));
                $expires = date('Y-m-d H:i:s', strtotime('+1 hour'));

                $stmt = $pdo->prepare("UPDATE users SET reset_token = ?, reset_expires_at = ? WHERE user_id = ?");
                $stmt->execute([$token, $expires, $user['user_id']]);

                $resetLink = "https://etudiant.univ-eiffel.fr/~issam.ben-hamouda/index.php?page=reset_password&token=" . $token;

                $body = "Hi " . htmlspecialchars($user['nickname']) . ",<br>To reset your password, click here: <a href='$resetLink'>Reset Password</a><br>This link expires in 1 hour.";

                if (EmailService::sendEmail($email, "Password Reset", $body)) {
                    $message = "A reset link has been sent to your email.";
                } else {
                    $error = "Error sending email.";
                }
            } else {
                $message = "If this email exists, a link has been sent.";
            }
        }
        require __DIR__ . '/../../templates/forgot_password.php';
    }

    public function resetPassword() {
        $token = $_GET['token'] ?? '';
        $pdo = Database::getInstance();
        $stmt = $pdo->prepare("SELECT user_id FROM users WHERE reset_token = ? AND reset_expires_at > NOW()");
        $stmt->execute([$token]);
        $user = $stmt->fetch();

        if (!$user) {
            die("Invalid or expired token.");
        }

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $newPassword = $_POST['password'];
            if (strlen($newPassword) >= 12) {
                $hash = password_hash($newPassword, PASSWORD_DEFAULT);
                $stmt = $pdo->prepare("UPDATE users SET password = ?, reset_token = NULL, reset_expires_at = NULL WHERE user_id = ?");
                $stmt->execute([$hash, $user['user_id']]);
                header('Location: index.php?page=login&reset=success');
                exit;
            } else {
                $error = "Password must be at least 12 characters.";
            }
        }
        require __DIR__ . '/../../templates/reset_password.php';
    }
}