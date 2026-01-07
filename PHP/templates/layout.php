<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Img2Brick</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.min.css" rel="stylesheet">
    <style>
        body {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        .main-container {
            flex: 1;
        }
    </style>
</head>
<body class="bg-light">
<nav class="navbar navbar-expand-lg navbar-dark bg-primary mb-4">
    <div class="container">
        <a class="navbar-brand" href="index.php?page=home">🧱 Img2Brick</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <div class="navbar-nav ms-auto">
                <?php if (class_exists('UserSession') && UserSession::isAuthenticated()): ?>
                    <span class="nav-link text-white">Hello, <?= htmlspecialchars($_SESSION['user']['username'] ?? 'Member') ?></span>
                    <a class="nav-link" href="index.php?page=history">My Orders</a>
                    <a class="nav-link" href="index.php?page=profile">My Profile</a>
                    <a class="nav-link" href="index.php?page=logout">Logout</a>
                <?php else: ?>
                    <a class="nav-link" href="index.php?page=login">Login</a>
                    <a class="nav-link" href="index.php?page=register">Register</a>
                <?php endif; ?>
            </div>
        </div>
    </div>
</nav>

<div class="container bg-white p-4 rounded shadow-sm main-container">
    <?= $content ?>
</div>

<footer style="text-align:center; padding:20px; margin-top:50px; border-top:1px solid #ccc;">
    <p>&copy; <?= date('Y') ?> Img2Brick. All rights reserved.</p>
    <p>
        <a href="https://github.com/Issam-BH/img2brick" target="_blank">View code on GitHub</a>
    </p>
</footer>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>