<?php
class Database {
    private static $instance = null;
    private $pdo;

    private function __construct() {
        // --- CONFIGURATION À REMPLIR ---
        $host = 'localhost';        // Souvent 'localhost' ou '127.0.0.1'
        $db   = 'lego_app';      // Le nom de votre base de données
        $user = 'root';             // Votre utilisateur MySQL
        $pass = '';                 // Votre mot de passe (laissez vide pour XAMPP par défaut)
        $charset = 'utf8mb4';
        // -------------------------------

        $dsn = "mysql:host=$host;dbname=$db;charset=$charset";
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ];

        try {
            $this->pdo = new PDO($dsn, $user, $pass, $options);
        } catch (\PDOException $e) {
            die("Erreur de connexion à la base de données : " . $e->getMessage());
        }
    }

    public static function getInstance() {
        if (self::$instance == null) {
            self::$instance = new Database();
        }
        return self::$instance->pdo;
    }
}