<?php
session_start();

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../src/Service/UserSession.php';
require_once __DIR__ . '/../src/Service/EmailService.php';
require_once __DIR__ . '/../src/Controller/AuthController.php';
require_once __DIR__ . '/../src/Controller/MosaicController.php';

$page = $_GET['page'] ?? 'home';

switch ($page) {

    case 'home':
        $controller = new MosaicController();
        $controller->upload();
        break;

    case 'login':
        $controller = new AuthController();
        $controller->login();
        break;

    case '2fa':
        $controller = new AuthController();
        $controller->verify2FA();
        break;

    case 'logout':
        $controller = new AuthController();
        $controller->logout();
        break;

    case 'profile':
        $controller = new AuthController();
        $controller->profile();
        break;

    case 'preview':
        if (isset($_GET['id_upload'])) {
            $controller = new MosaicController();
            $controller->preview($_GET['id_upload']);
        } else {
            header('Location: index.php?page=home');
            exit;
        }
        break;

    case 'results':
        $controller = new MosaicController();
        $controller->results();
        break;

    case 'register':
        $controller = new AuthController();
        $controller->register();
        break;

    case 'order':
        require_once __DIR__ . '/../src/Controller/OrderController.php';
        (new OrderController())->form();
        break;

    case 'order_process':
        require_once __DIR__ . '/../src/Controller/OrderController.php';
        (new OrderController())->process();
        break;

    case 'confirmation':
        require_once __DIR__ . '/../src/Controller/OrderController.php';
        (new OrderController())->confirmation();
        break;

    case 'history':
        require_once __DIR__ . '/../src/Controller/OrderController.php';
        (new OrderController())->history();
        break;

    case 'forgot_password':
        require_once __DIR__ . '/../src/Controller/AuthController.php';
        (new AuthController())->forgotPassword();
        break;

    case 'reset_password':
        require_once __DIR__ . '/../src/Controller/AuthController.php';
        (new AuthController())->resetPassword();
        break;

    case 'crop':
        $mosaicController = new MosaicController();
        $mosaicController->crop();
        break;

    case 'download':
        $controller = new MosaicController();
        $controller->download();
        break;

    default:
        http_response_code(404);
        echo "<div style='text-align:center; margin-top:50px; font-family:sans-serif;'>";
        echo "<h1>Erreur 404</h1>";
        echo "<p>La page demandée n'existe pas.</p>";
        echo "<a href='index.php?page=home'>Retour à l'accueil</a>";
        echo "</div>";
        break;
}