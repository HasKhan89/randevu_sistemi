<?php
/* =====================================================================
   get_doctors.php - Cascade Adım 2
   Seçilen clinic_id'de aktif olarak çalışan doktorları JSON olarak döner.

   ÖNEMLİ MİMARİ NOT: Döndürülen "id" alanı doctor_id DEĞİL,
   doctor_clinic_id'dir. Çünkü business_hours, appointments ile ilişkili
   tüm slot/randevu mantığımız (get_available_slots.php, create_appointment.php)
   doctor_clinic_id üzerinden çalışıyor — aynı doktor birden fazla
   klinikte farklı çalışma saatleriyle bulunabiliyor. Bu sayede
   get_available_slots.php ve create_appointment.php'ye HİÇ dokunmadan
   cascade akışına bağlanabiliyoruz.
   ===================================================================== */

ini_set('display_errors', '0');
error_reporting(E_ALL);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/Database.php';

function respond($success, $data = [], $message = '') {
    echo json_encode([
        'success' => $success,
        'doctors' => $data,
        'message' => $message,
    ]);
    exit;
}

$clinic_id = isset($_GET['clinic_id']) ? (int)$_GET['clinic_id'] : 0;

if ($clinic_id <= 0) {
    respond(false, [], 'Klinik bilgisi eksik.');
}

try {
    $database = new Database();
    $pdo = $database->connect();

    $stmt = $pdo->prepare("
        SELECT dc.doctor_clinic_id AS id, d.first_name, d.last_name, d.specialty
        FROM doctor_clinics dc
        INNER JOIN doctors d ON d.doctor_id = dc.doctor_id
        WHERE dc.clinic_id = :clinic_id AND dc.is_active = 1
        ORDER BY d.last_name, d.first_name
    ");
    $stmt->execute(['clinic_id' => $clinic_id]);
    $doctors = $stmt->fetchAll();

    if (empty($doctors)) {
        respond(true, [], 'Bu klinikte aktif doktor bulunamadı.');
    }

    respond(true, $doctors, '');

} catch (PDOException $e) {
    respond(false, [], 'Veritabanı hatası: ' . $e->getMessage());
}
