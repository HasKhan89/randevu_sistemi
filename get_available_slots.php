<?php
/* =====================================================================
   get_available_slots.php - Story 2.1
   Seçilen doktor_clinic_id ve tarih için o günün BOŞ randevu saatlerini
   JSON olarak döner. rezervasyon.php'deki loadSlots() fonksiyonu bu
   dosyayı fetch() ile çağırır.

   ÖNEMLİ: Bu dosya SADECE JSON döner. HTML/uyarı/hata mesajı asla
   ekrana basılmaz; her durumda geçerli bir JSON gövdesi döner. Aksi
   halde fetch() tarafında "Unexpected token '<' is not valid JSON"
   hatası alınır (projede yaşanan hatanın sebebi tam olarak buydu:
   bu dosya hiç yoktu).
   ===================================================================== */

// Prod ortamda display_errors kapalı olmalı; olası bir PHP notice/warning
// bile JSON çıktısını bozabileceğinden, hataları JSON'a çevirmeden önce
// ekrana bastırmıyoruz.
ini_set('display_errors', '0');
error_reporting(E_ALL);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/Database.php';

function respond($success, $slots = [], $message = '') {
    echo json_encode([
        'success' => $success,
        'slots'   => $slots,
        'message' => $message,
    ]);
    exit;
}

// -----------------------------------------------------------------
// 1) GİRDİLERİ DOĞRULA
// -----------------------------------------------------------------
$doctor_clinic_id = isset($_GET['doctor_clinic_id']) ? (int)$_GET['doctor_clinic_id'] : 0;
$date              = isset($_GET['date']) ? trim($_GET['date']) : '';

if ($doctor_clinic_id <= 0 || $date === '') {
    respond(false, [], 'Doktor/klinik ve tarih bilgisi eksik.');
}

$dt = DateTime::createFromFormat('Y-m-d', $date);
if (!$dt || $dt->format('Y-m-d') !== $date) {
    respond(false, [], 'Geçersiz tarih formatı.');
}

// Geçmiş tarih seçilmesini engelle
$today = new DateTime('today');
if ($dt < $today) {
    respond(false, [], 'Geçmiş bir tarih için randevu alınamaz.');
}

$dayMap = [
    'Monday' => 'MONDAY', 'Tuesday' => 'TUESDAY', 'Wednesday' => 'WEDNESDAY',
    'Thursday' => 'THURSDAY', 'Friday' => 'FRIDAY', 'Saturday' => 'SATURDAY', 'Sunday' => 'SUNDAY',
];
$day_of_week = $dayMap[$dt->format('l')];

try {
    $database = new Database();
    $pdo = $database->connect();

    // -------------------------------------------------------------
    // 2) doctor_clinics'ten gerçek doctor_id / clinic_id'yi bul
    // -------------------------------------------------------------
    $stmt = $pdo->prepare("
        SELECT dc.doctor_id, dc.clinic_id
        FROM doctor_clinics dc
        WHERE dc.doctor_clinic_id = :doctor_clinic_id AND dc.is_active = 1
    ");
    $stmt->execute(['doctor_clinic_id' => $doctor_clinic_id]);
    $dc = $stmt->fetch();

    if (!$dc) {
        respond(false, [], 'Seçilen doktor/klinik bulunamadı.');
    }

    // -------------------------------------------------------------
    // 3) O güne ait çalışma saatini bul
    // -------------------------------------------------------------
    $stmt = $pdo->prepare("
        SELECT start_time, end_time, break_start, break_end, slot_duration_minutes
        FROM business_hours
        WHERE doctor_clinic_id = :doctor_clinic_id AND day_of_week = :day_of_week
    ");
    $stmt->execute([
        'doctor_clinic_id' => $doctor_clinic_id,
        'day_of_week'      => $day_of_week,
    ]);
    $bh = $stmt->fetch();

    if (!$bh) {
        respond(true, [], 'Doktor bu gün çalışmıyor.');
    }

    // -------------------------------------------------------------
    // 4) O gün için zaten alınmış (iptal edilmemiş) randevuları çek
    // -------------------------------------------------------------
    $stmt = $pdo->prepare("
        SELECT start_time
        FROM appointments
        WHERE doctor_id = :doctor_id
          AND clinic_id = :clinic_id
          AND appointment_date = :date
          AND status != 'CANCELLED'
    ");
    $stmt->execute([
        'doctor_id' => $dc['doctor_id'],
        'clinic_id' => $dc['clinic_id'],
        'date'      => $date,
    ]);
    $bookedTimes = array_column($stmt->fetchAll(), 'start_time');
    // HH:MM:SS formatına normalize et (MySQL TIME formatı zaten böyle döner)
    $bookedTimes = array_map(function ($t) { return substr($t, 0, 5); }, $bookedTimes);

    // -------------------------------------------------------------
    // 5) Slotları üret: start_time -> end_time arası, molayı hariç tut
    // -------------------------------------------------------------
    $slotDuration = (int)$bh['slot_duration_minutes'];
    if ($slotDuration <= 0) {
        $slotDuration = 20;
    }

    $slots = [];
    $current = DateTime::createFromFormat('H:i:s', $bh['start_time']);
    $end     = DateTime::createFromFormat('H:i:s', $bh['end_time']);

    $breakStart = $bh['break_start'] ? DateTime::createFromFormat('H:i:s', $bh['break_start']) : null;
    $breakEnd   = $bh['break_end']   ? DateTime::createFromFormat('H:i:s', $bh['break_end'])   : null;

    // Bugün seçildiyse, şu ana kadar geçmiş saatleri de ele
    $isToday = ($date === (new DateTime('today'))->format('Y-m-d'));
    $now = new DateTime();

    while (true) {
        $slotEnd = (clone $current)->modify("+{$slotDuration} minutes");
        if ($slotEnd > $end) {
            break;
        }

        $inBreak = false;
        if ($breakStart && $breakEnd) {
            if ($current < $breakEnd && $slotEnd > $breakStart) {
                $inBreak = true;
            }
        }

        $startStr = $current->format('H:i');
        $isBooked = in_array($startStr, $bookedTimes, true);

        $isPast = false;
        if ($isToday) {
            $slotDateTime = DateTime::createFromFormat('Y-m-d H:i', $date . ' ' . $startStr);
            if ($slotDateTime < $now) {
                $isPast = true;
            }
        }

        if (!$inBreak && !$isBooked && !$isPast) {
            $slots[] = [
                'start_time' => $current->format('H:i'),
                'end_time'   => $slotEnd->format('H:i'),
                'label'      => $current->format('H:i') . ' - ' . $slotEnd->format('H:i'),
            ];
        }

        $current->modify("+{$slotDuration} minutes");
    }

    if (empty($slots)) {
        respond(true, [], 'Bu tarihte müsait saat bulunmuyor.');
    }

    respond(true, $slots, '');

} catch (PDOException $e) {
    // Veritabanı hatasını da HTML değil JSON olarak döndür
    respond(false, [], 'Veritabanı hatası: ' . $e->getMessage());
}
