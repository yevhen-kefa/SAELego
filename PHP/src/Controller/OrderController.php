<?php
require_once __DIR__ . '/../Service/UserSession.php';
require_once __DIR__ . '/../../config/Database.php';

class OrderController {

    public function form() {
        if (!UserSession::isAuthenticated()) {
            header('Location: index.php?page=login');
            exit;
        }

        if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['id_upload'])) {
            $uploadId = $_POST['id_upload'];
            
            $brickData = $_POST['brick_data'] ?? '[]';
            $price = $_POST['price'] ?? 0;
            $size = $_POST['size'] ?? 64;
            $filter = 'generated_c'; 

            $pdo = Database::getInstance();
            $stmt = $pdo->prepare("SELECT * FROM users WHERE user_id = ?");
            $stmt->execute([UserSession::getUserId()]);
            $user = $stmt->fetch();

            require __DIR__ . '/../../templates/order.php';
        } else {
            header('Location: index.php?page=home');
        }
    }

    public function process() {
        if (!UserSession::isAuthenticated()) header('Location: index.php?page=login');

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $pdo = Database::getInstance();
            $userId = UserSession::getUserId();
            
            $stmtUser = $pdo->prepare("SELECT * FROM users WHERE user_id = ?");
            $stmtUser->execute([$userId]);
            $user = $stmtUser->fetch();

            $sqlAddr = "INSERT INTO address (user_id, line1, city, postal_code, country, is_default) 
                        VALUES (:uid, :line1, :city, :cp, :country, 1)";
            $stmt = $pdo->prepare($sqlAddr);
            $stmt->execute([
                ':uid' => $userId,
                ':line1' => $_POST['address'],
                ':city' => $_POST['city'],
                ':cp' => $_POST['zip'],
                ':country' => 'France'
            ]);
            $addressId = $pdo->lastInsertId();

            $sqlMosaic = "INSERT INTO mosaic (uploads_id, filter_used, size_option, estimated_price, brick_data, created_at) 
                          VALUES (:uid, :filter, :size, :price, :data, NOW())";
            $stmt = $pdo->prepare($sqlMosaic);
            $stmt->execute([
                ':uid'    => $_POST['upload_id'],
                ':filter' => $_POST['filter_css'] ?? 'c_algo',
                ':size'   => $_POST['size_option'],
                ':price'  => $_POST['total_price'],
                ':data'   => $_POST['brick_data'] ?? null
            ]);
            $mosaicId = $pdo->lastInsertId();

            $orderRef = 'CMD-' . date('Ymd') . '-' . strtoupper(substr(uniqid(), -4));
            $sqlOrder = "INSERT INTO orders (user_id, mosaic_id, shipping_address_id, order_number, status, total_amount, payment_method, created_at) 
                         VALUES (:uid, :mid, :aid, :ref, 'paid', :total, 'card', NOW())";
            $stmt = $pdo->prepare($sqlOrder);
            $stmt->execute([
                ':uid' => $userId,
                ':mid' => $mosaicId,
                ':aid' => $addressId,
                ':ref' => $orderRef,
                ':total' => $_POST['total_price']
            ]);
            $orderId = $pdo->lastInsertId();

            $invoiceData = [
                'client' => ['firstname' => $user['firstname'], 'lastname' => $user['lastname'], 'email' => $user['email']],
                'shipping_address' => ['line1' => $_POST['address'], 'city' => $_POST['city'], 'zip' => $_POST['zip'], 'country' => 'France'],
                'items' => [[
                    'description' => "Mosaïque LEGO® (" . $_POST['size_option'] . "x" . $_POST['size_option'] . ")",
                    'quantity' => 1,
                    'unit_price' => $_POST['total_price'],
                    'total' => $_POST['total_price']
                ]],
                'payment' => ['method' => 'Carte Bancaire', 'date' => date('Y-m-d H:i:s'), 'total' => $_POST['total_price'] . ' €']
            ];
            $invoiceRef = 'FACT-' . date('Ymd') . '-' . strtoupper(substr(uniqid(), -4));
            
            $sqlInvoice = "INSERT INTO invoices (order_id, invoice_number, content_json, created_at) 
                           VALUES (:oid, :ref, :json, NOW())";
            $stmt = $pdo->prepare($sqlInvoice);
            $stmt->execute([
                ':oid' => $orderId,
                ':ref' => $invoiceRef,
                ':json' => json_encode($invoiceData)
            ]);

            header("Location: index.php?page=confirmation&ref=" . $orderRef);
            exit;
        }
    }

    public function confirmation() {
        if (!isset($_GET['ref'])) header('Location: index.php');
        $ref = $_GET['ref'];
        $pdo = Database::getInstance();
        $sql = "SELECT * FROM orders WHERE order_number = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$ref]);
        $order = $stmt->fetch();
        require __DIR__ . '/../../templates/confirmation.php';
    }

    public function history() {
        if (!UserSession::isAuthenticated()) { header('Location: index.php?page=login'); exit; }
        $userId = UserSession::getUserId();
        $pdo = Database::getInstance();
        $sql = "SELECT o.*, m.size_option, m.filter_used, u.id_upload 
                FROM orders o
                JOIN mosaic m ON o.mosaic_id = m.id
                JOIN uploads u ON m.uploads_id = u.id_upload
                WHERE o.user_id = ? ORDER BY o.created_at DESC";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$userId]);
        $orders = $stmt->fetchAll();
        require __DIR__ . '/../../templates/history.php';
    }
}