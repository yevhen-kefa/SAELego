<?php
require_once __DIR__ . '/../config/database.php';
if (isset($_GET['id'])) {
    $pdo = Database::getInstance();
    $id = $_GET['id'];

    $stmt = $pdo->prepare("SELECT image_data, image_type FROM uploads WHERE id_upload = ?");
    $stmt->execute([$id]);
    $img = $stmt->fetch();

    if ($img && !empty($img['image_data'])) {
        header("Content-Type: " . $img['image_type']);
        echo $img['image_data'];
        exit;
    }
}

http_response_code(404);
echo "Image introuvable";