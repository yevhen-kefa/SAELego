<?php
require_once __DIR__ . '/../Manager/LogManager.php';
require_once __DIR__ . '/../Service/MosaicService.php';
require_once __DIR__ . '/../Service/UserSession.php';

class MosaicController {
    
    public function upload() {
        if (!UserSession::isAuthenticated()) {
            header('Location: index.php?page=login');
            exit;
        }

        if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['userImage'])) {
            $file = $_FILES['userImage'];

            if ($file['error'] === UPLOAD_ERR_OK) {

                $imageData = file_get_contents($file['tmp_name']);
                $imageType = $file['type'];
                $fileName  = $file['name'];
                $userId    = UserSession::getUserId();

                $pdo = Database::getInstance();
                $sql = "INSERT INTO uploads (user_id, filename, image_data, image_type, uploaded_at) 
                    VALUES (:uid, :fname, :data, :type, NOW())";

                $stmt = $pdo->prepare($sql);
                $stmt->execute([
                    ':uid'   => $userId,
                    ':fname' => $fileName,
                    ':data'  => $imageData,
                    ':type'  => $imageType
                ]);

                $lastId = $pdo->lastInsertId();
                $logManager = new LogManager();
                $logManager->log('INFO', 'Upload image BLOB successful');

                header("Location: index.php?page=preview&id_upload=$lastId");
                exit;
            }
        }
        require __DIR__ . '/../../templates/home.php';
    }

public function preview($id) {
        if (!UserSession::isAuthenticated()) {
            header('Location: index.php?page=login');
            exit;
        }

        $uploadId = $id;
        $pdo = Database::getInstance();
        $stmt = $pdo->prepare("SELECT * FROM uploads WHERE id_upload = ?");
        
        $stmt->execute([$uploadId]);
        $image = $stmt->fetch();

        if (!$image) {
            die("Image introuvable en base de données.");
        }
        require __DIR__ . '/../../templates/preview.php';
    }

    public function crop() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            
            $json = file_get_contents('php://input');
            $data = json_decode($json, true);

            if (isset($data['image']) && isset($data['original_id'])) {
                $imageParts = explode(";base64,", $data['image']);
                $imageType = explode("image/", $imageParts[0])[1];
                $imageBase64 = base64_decode($imageParts[1]);

                $pdo = Database::getInstance();
                $userId = UserSession::getUserId();

                $sql = "INSERT INTO uploads (user_id, filename, image_data, image_type, uploaded_at) 
                        VALUES (:uid, :fname, :data, :type, NOW())";
                
                $stmt = $pdo->prepare($sql);
                $stmt->execute([
                    ':uid'   => $userId,
                    ':fname' => 'cropped_' . uniqid() . '.' . $imageType,
                    ':data'  => $imageBase64,
                    ':type'  => 'image/' . $imageType
                ]);

                $newId = $pdo->lastInsertId();
                header('Content-Type: application/json');
                echo json_encode(['success' => true, 'new_id' => $newId]);
                exit;
            }
        }
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Invalid data']);
        exit;
    }

    public function results() {
        if (!UserSession::isAuthenticated()) {
            header('Location: index.php?page=login');
            exit;
        }

        $bricks = []; 

        if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['id_upload'])) {
            $uploadId = $_POST['id_upload'];
            $pdo = Database::getInstance();

            $stmt = $pdo->prepare("SELECT image_data FROM uploads WHERE id_upload = ?");
            $stmt->execute([$uploadId]);
            $data = $stmt->fetchColumn();

            if ($data) {
                $tmpInputImg = sys_get_temp_dir() . '/input_' . uniqid() . '.jpg';
                file_put_contents($tmpInputImg, $data);

                $service = new MosaicService();
                try {
                    $bricks = $service->generateMosaic($tmpInputImg);
                    require __DIR__ . '/../../templates/results.php';
                    
                } catch (Exception $e) {
                    $logManager = new LogManager();
                    $logManager->log('ERROR', "Erreur génération mosaïque : " . $e->getMessage());
                    die("Une erreur est survenue lors de la génération de la mosaïque. Veuillez réessayer.");
                } finally {
                    if (file_exists($tmpInputImg)) {
                        @unlink($tmpInputImg);
                    }
                }
            } else {
                header('Location: index.php?page=home');
                exit;
            }
        } else {
            header('Location: index.php?page=home');
            exit;
        }
    }

    public function download() {
    if (!UserSession::isAuthenticated()) {
        header('Location: index.php?page=login');
        exit;
    }

    $type = $_POST['type'] ?? '';
    $json = $_POST['brick_data'] ?? '[]';
    $bricks = json_decode($json, true);

    if (empty($bricks)) {
        die("Aucune donnée de mosaïque à télécharger.");
    }

    if ($type === 'csv') {
        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="liste_pieces_lego.csv"');

        $out = fopen('php://output', 'w');
        fputcsv($out, ['Dimension (LxH)', 'Couleur (Hex)', 'Quantité']);
        $stats = [];
        foreach ($bricks as $b) {
            $key = $b['w'] . 'x' . $b['h'] . '_' . $b['color'];
            
            if (!isset($stats[$key])) {
                $stats[$key] = [
                    'dim' => $b['w'] . ' x ' . $b['h'],
                    'col' => $b['color'],
                    'qty' => 0
                ];
            }
            $stats[$key]['qty']++;
        }
        foreach ($stats as $row) {
            fputcsv($out, [$row['dim'], $row['col'], $row['qty']]);
        }
        fclose($out);
        exit;

    } elseif ($type === 'svg') {
        header('Content-Type: image/svg+xml');
        header('Content-Disposition: attachment; filename="mosaique_finale.svg"');
        echo '<?xml version="1.0" encoding="UTF-8"?>';
        echo '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="1024" height="1024">';
        
        foreach ($bricks as $b) {
            $width = ($b['rot'] % 2 == 0) ? $b['w'] : $b['h'];
            $height = ($b['rot'] % 2 == 0) ? $b['h'] : $b['w'];
            
            echo sprintf(
                '<rect x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="#000" stroke-width="0.05"/>',
                $b['x'], $b['y'], $width, $height, $b['color']
            );
        }
        echo '</svg>';
        exit;
    }
}
}