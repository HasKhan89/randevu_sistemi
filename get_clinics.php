<?php
/* =====================================================================
   get_clinics.php - Cascade Adım 1
   Seçilen department_id'ye ait klinikleri JSON olarak döner.
   randevu formu: department select -> change -> bu dosya çağrılır.
   ===================================================================== */

ini_set('display_errors', '0');
error_reporting(E_ALL);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/Database.php';

function respond($success, $data = [], $message = '') {
    echo json_encode([
        'success' => $success,
        'clinics' => $data,
        'message' => $message,
    ]);
    exit;
}

$department_id = isset($_GET['department_id']) ? (int)$_GET['department_id'] : 0;

if ($department_id <= 0) {
    respond(false, [], 'Bölüm bilgisi eksik.');
}

try {
    $database = new Database();
    $pdo = $database->connect();

    $stmt = $pdo->prepare("
        SELECT clinic_id AS id, name
        FROM clinics
        WHERE department_id = :department_id
        ORDER BY name
    ");
    $stmt->execute(['department_id' => $department_id]);
    $clinics = $stmt->fetchAll();

    if (empty($clinics)) {
        respond(true, [], 'Bu bölüme ait tanımlı klinik bulunamadı.');
    }

    respond(true, $clinics, '');

} catch (PDOException $e) {
    respond(false, [], 'Veritabanı hatası: ' . $e->getMessage());
}
