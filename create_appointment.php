<?php
/* =====================================================================
   create_appointment.php - Story 2.2
   rezervasyon.php'deki form fetch() ile POST yapar; bu dosya randevuyu
   kaydeder ve JSON {success, message} döner. HTML asla basılmaz.
   ===================================================================== */

ini_set('display_errors', '0');
error_reporting(E_ALL);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/Database.php';

function respond($success, $message) {
    echo json_encode(['success' => $success, 'message' => $message]);
    exit;
}

// -----------------------------------------------------------------
// TC Kimlik No doğrulama (format + resmi checksum algoritması).
// Sadece 11 haneli ve 0 ile başlamıyor kontrolü yeterli DEĞİLDİR;
// gerçek algoritma uygulanmazsa "12345678901" gibi anlamsız ama
// formata uyan değerler de kabul edilir ve unique constraint'i
// anlamsız veriyle doldurur.
// -----------------------------------------------------------------
function isValidTcKimlikNo($tc) {
    if (!preg_match('/^[1-9][0-9]{10}$/', $tc)) {
        return false;
    }
    $digits = array_map('intval', str_split($tc));

    $oddSum  = $digits[0] + $digits[2] + $digits[4] + $digits[6] + $digits[8];
    $evenSum = $digits[1] + $digits[3] + $digits[5] + $digits[7];

    $digit10 = (($oddSum * 7) - $evenSum) % 10;
    if ($digit10 < 0) {
        $digit10 += 10;
    }
    if ($digit10 !== $digits[9]) {
        return false;
    }

    $sumFirst10 = array_sum(array_slice($digits, 0, 10));
    $digit11 = $sumFirst10 % 10;
    if ($digit11 !== $digits[10]) {
        return false;
    }

    return true;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(false, 'Geçersiz istek yöntemi.');
}

// -----------------------------------------------------------------
// 1) GİRDİLERİ OKU VE DOĞRULA
// -----------------------------------------------------------------
$doctor_clinic_id = isset($_POST['doctor_clinic_id']) ? (int)$_POST['doctor_clinic_id'] : 0;
$date              = isset($_POST['date']) ? trim($_POST['date']) : '';
$start_time        = isset($_POST['start_time']) ? trim($_POST['start_time']) : '';
$end_time          = isset($_POST['end_time']) ? trim($_POST['end_time']) : '';
$full_name         = isset($_POST['full_name']) ? trim($_POST['full_name']) : '';
$phone             = isset($_POST['phone']) ? trim($_POST['phone']) : '';
$national_id       = isset($_POST['national_id']) ? trim($_POST['national_id']) : '';

if ($doctor_clinic_id <= 0 || $date === '' || $start_time === '' || $end_time === '' ||
    $full_name === '' || $phone === '' || $national_id === '') {
    respond(false, 'Lütfen tüm alanları doldurun.');
}

if (!preg_match('/^0[0-9]{10}$/', $phone)) {
    respond(false, 'Telefon numarası 0 ile başlayan 11 haneli olmalıdır (örn: 05XXXXXXXXX).');
}

if (!isValidTcKimlikNo($national_id)) {
    respond(false, 'Geçersiz TC Kimlik No. Lütfen 11 haneli, doğru kimlik numaranızı girin.');
}

$dt = DateTime::createFromFormat('Y-m-d', $date);
if (!$dt || $dt->format('Y-m-d') !== $date) {
    respond(false, 'Geçersiz tarih formatı.');
}

// Ad Soyad'ı basitçe ayır (son kelime soyad, geri kalanı ad kabul edilir)
$nameParts = preg_split('/\s+/', $full_name, -1, PREG_SPLIT_NO_EMPTY);
if (count($nameParts) < 2) {
    respond(false, 'Lütfen ad ve soyadınızı birlikte girin.');
}
$last_name  = array_pop($nameParts);
$first_name = implode(' ', $nameParts);

try {
    $database = new Database();
    $pdo = $database->connect();

    // İşlemi atomik yapmak için transaction kullan (çakışma kontrolü + insert)
    $pdo->beginTransaction();

    // ---------------------------------------------------------
    // 2) doctor_clinics'ten doctor_id / clinic_id bul
    // ---------------------------------------------------------
    $stmt = $pdo->prepare("
        SELECT doctor_id, clinic_id
        FROM doctor_clinics
        WHERE doctor_clinic_id = :doctor_clinic_id AND is_active = 1
    ");
    $stmt->execute(['doctor_clinic_id' => $doctor_clinic_id]);
    $dc = $stmt->fetch();

    if (!$dc) {
        $pdo->rollBack();
        respond(false, 'Seçilen doktor/klinik bulunamadı.');
    }

    // ---------------------------------------------------------
    // 3) Slot hâlâ boş mu? (iki kullanıcı aynı anda aynı saati seçmesin)
    // ---------------------------------------------------------
    $stmt = $pdo->prepare("
        SELECT COUNT(*) AS cnt
        FROM appointments
        WHERE doctor_id = :doctor_id
          AND clinic_id = :clinic_id
          AND appointment_date = :date
          AND start_time = :start_time
          AND status != 'CANCELLED'
    ");
    $stmt->execute([
        'doctor_id'  => $dc['doctor_id'],
        'clinic_id'  => $dc['clinic_id'],
        'date'       => $date,
        'start_time' => $start_time,
    ]);
    if ((int)$stmt->fetch()['cnt'] > 0) {
        $pdo->rollBack();
        respond(false, 'Bu saat az önce başka biri tarafından alındı. Lütfen başka bir saat seçin.');
    }

    // ---------------------------------------------------------
    // 4) Hastayı TC Kimlik No'ya göre bul (unique alan budur), yoksa oluştur
    // ---------------------------------------------------------
    $stmt = $pdo->prepare("SELECT patient_id, phone FROM patients WHERE national_id = :national_id LIMIT 1");
    $stmt->execute(['national_id' => $national_id]);
    $patient = $stmt->fetch();

    if ($patient) {
        $patient_id = $patient['patient_id'];

        // Telefon değişmişse güncel bilgiyi yansıt (isteğe bağlı ama faydalı)
        if ($patient['phone'] !== $phone) {
            $stmt = $pdo->prepare("UPDATE patients SET phone = :phone WHERE patient_id = :patient_id");
            $stmt->execute(['phone' => $phone, 'patient_id' => $patient_id]);
        }
    } else {
        $stmt = $pdo->prepare("
            INSERT INTO patients (first_name, last_name, phone, national_id)
            VALUES (:first_name, :last_name, :phone, :national_id)
        ");
        $stmt->execute([
            'first_name'  => $first_name,
            'last_name'   => $last_name,
            'phone'       => $phone,
            'national_id' => $national_id,
        ]);
        $patient_id = $pdo->lastInsertId();
    }

    // ---------------------------------------------------------
    // 5) Randevuyu kaydet
    // ---------------------------------------------------------
    $stmt = $pdo->prepare("
        INSERT INTO appointments
            (patient_id, doctor_id, clinic_id, service_id, appointment_date, start_time, end_time, status, payment_status)
        VALUES
            (:patient_id, :doctor_id, :clinic_id, NULL, :date, :start_time, :end_time, 'SCHEDULED', 'PENDING')
    ");
    $stmt->execute([
        'patient_id' => $patient_id,
        'doctor_id'  => $dc['doctor_id'],
        'clinic_id'  => $dc['clinic_id'],
        'date'       => $date,
        'start_time' => $start_time,
        'end_time'   => $end_time,
    ]);

    $pdo->commit();

    respond(true, 'Randevunuz başarıyla oluşturuldu. ' . $date . ' tarihinde ' . $start_time . ' saatinde bekleniyorsunuz.');

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    // Eğer appointments tablosunda çalışma saati/mola dışı randevuyu engelleyen
    // bir TRIGGER varsa (business_hours.php altındaki nota bakınız), hata mesajı
    // burada yakalanır ve JSON olarak kullanıcıya iletilir.
    respond(false, 'Randevu kaydedilemedi: ' . $e->getMessage());
}
