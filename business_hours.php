<?php
/* =====================================================================
   business_hours.php - Doktor Çalışma Saati / Mola Ayarları (Admin)
   Story 1.2: Hastane çalışanının kendi çalışma günü, saati ve mola
   vaktini tanımlayabildiği sade bir admin ayarlar sayfası.
   Veriler business_hours tablosuna yazılır. Aynı doktor-klinik-gün
   kombinasyonu tekrar girilirse UPSERT yapılır (üzerine yazılır).

   Story 2.3 (devamı): Bootstrap 5 ile görsel güncelleme. SADECE
   HTML/CSS/class isimleri değişti — POST/GET işleme mantığı, SQL
   sorguları, doğrulama kuralları birebir aynı kaldı.
   ===================================================================== */

require_once __DIR__ . '/Database.php';

try {
    $database = new Database();
    $pdo = $database->connect();
} catch (PDOException $e) {
    die("Veritabanı bağlantı hatası: " . htmlspecialchars($e->getMessage()));
}

$days = ['MONDAY' => 'Pazartesi', 'TUESDAY' => 'Salı', 'WEDNESDAY' => 'Çarşamba',
         'THURSDAY' => 'Perşembe', 'FRIDAY' => 'Cuma', 'SATURDAY' => 'Cumartesi',
         'SUNDAY' => 'Pazar'];

$message = "";
$error   = "";

// -----------------------------------------------------------------
// FORM GÖNDERİLDİYSE: KAYDET (INSERT ... ON DUPLICATE KEY UPDATE)
// -----------------------------------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_business_hour'])) {

    $doctor_clinic_id = (int)$_POST['doctor_clinic_id'];
    $day_of_week       = $_POST['day_of_week'];
    $start_time        = $_POST['start_time'];
    $end_time          = $_POST['end_time'];
    $break_start       = trim($_POST['break_start']) !== '' ? $_POST['break_start'] : null;
    $break_end         = trim($_POST['break_end'])   !== '' ? $_POST['break_end']   : null;
    $slot_duration     = (int)$_POST['slot_duration_minutes'];

    // Basit sunucu tarafı doğrulama
    if ($doctor_clinic_id <= 0 || !array_key_exists($day_of_week, $days) || !$start_time || !$end_time) {
        $error = "Lütfen doktor/klinik, gün, başlangıç ve bitiş saatini eksiksiz doldurun.";
    } elseif ($start_time >= $end_time) {
        $error = "Başlangıç saati, bitiş saatinden önce olmalıdır.";
    } elseif (($break_start && !$break_end) || (!$break_start && $break_end)) {
        $error = "Mola başlangıç ve bitiş saatinin ikisi de girilmeli veya ikisi de boş bırakılmalı.";
    } elseif ($break_start && $break_end && ($break_start >= $break_end || $break_start < $start_time || $break_end > $end_time)) {
        $error = "Mola saati, çalışma saati aralığı içinde ve mantıklı bir sırada olmalıdır.";
    } else {
        try {
            $stmt = $pdo->prepare("
                INSERT INTO business_hours
                    (doctor_clinic_id, day_of_week, start_time, end_time, break_start, break_end, slot_duration_minutes)
                VALUES (:doctor_clinic_id, :day_of_week, :start_time, :end_time, :break_start, :break_end, :slot_duration)
                ON DUPLICATE KEY UPDATE
                    start_time = VALUES(start_time),
                    end_time   = VALUES(end_time),
                    break_start = VALUES(break_start),
                    break_end   = VALUES(break_end),
                    slot_duration_minutes = VALUES(slot_duration_minutes)
            ");

            $stmt->execute([
                'doctor_clinic_id' => $doctor_clinic_id,
                'day_of_week'      => $day_of_week,
                'start_time'       => $start_time,
                'end_time'         => $end_time,
                'break_start'      => $break_start,
                'break_end'        => $break_end,
                'slot_duration'    => $slot_duration,
            ]);

            $message = "Çalışma saati kaydedildi.";
        } catch (PDOException $e) {
            $error = "SQL Hatası: " . $e->getMessage() .
                     " — business_hours tablosu eksik olabilir, " .
                     "randevu_sistemi_master.sql'in tamamının çalıştırıldığından emin olun.";
        }
    }
}

// -----------------------------------------------------------------
// SİLME İŞLEMİ
// -----------------------------------------------------------------
if (isset($_GET['delete_id'])) {
    $delete_id = (int)$_GET['delete_id'];
    try {
        $stmt = $pdo->prepare("DELETE FROM business_hours WHERE business_hour_id = :id");
        $stmt->execute(['id' => $delete_id]);
        $message = "Kayıt silindi.";
    } catch (PDOException $e) {
        $error = "SQL Hatası: " . $e->getMessage();
    }
}

// -----------------------------------------------------------------
// DROPDOWN İÇİN: Doktor + Klinik kombinasyonları (doctor_clinics)
// -----------------------------------------------------------------
try {
    $doctor_clinics = $pdo->query("
        SELECT dc.doctor_clinic_id, d.first_name, d.last_name, c.name AS clinic_name, dc.room_number
        FROM doctor_clinics dc
        INNER JOIN doctors d ON d.doctor_id = dc.doctor_id
        INNER JOIN clinics c ON c.clinic_id = dc.clinic_id
        WHERE dc.is_active = 1
        ORDER BY d.last_name, d.first_name
    ")->fetchAll();
} catch (PDOException $e) {
    die("SQL Hatası (doctor_clinics sorgusu): " . htmlspecialchars($e->getMessage()) .
        "<br>Muhtemel sebep: doctor_clinics/doctors/clinics tabloları eksik. " .
        "randevu_sistemi_master.sql dosyasının BAŞTAN SONA (tek parça halinde) " .
        "çalıştırıldığından emin olun.");
}

// -----------------------------------------------------------------
// MEVCUT ÇALIŞMA SAATLERİNİ LİSTELE
// -----------------------------------------------------------------
try {
    $existing = $pdo->query("
        SELECT bh.business_hour_id, bh.day_of_week, bh.start_time, bh.end_time,
               bh.break_start, bh.break_end, bh.slot_duration_minutes,
               d.first_name, d.last_name, c.name AS clinic_name
        FROM business_hours bh
        INNER JOIN doctor_clinics dc ON dc.doctor_clinic_id = bh.doctor_clinic_id
        INNER JOIN doctors d ON d.doctor_id = dc.doctor_id
        INNER JOIN clinics c ON c.clinic_id = dc.clinic_id
        ORDER BY d.last_name, d.first_name,
                 FIELD(bh.day_of_week,'MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY')
    ")->fetchAll();
} catch (PDOException $e) {
    die("SQL Hatası (business_hours sorgusu): " . htmlspecialchars($e->getMessage()) .
        "<br>Muhtemel sebep: business_hours tablosu henüz oluşturulmamış. " .
        "randevu_sistemi_master.sql dosyasının BAŞTAN SONA çalıştırıldığından emin olun.");
}
?>
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Doktor Çalışma Saati Ayarları</title>

    <link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.3.3/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">

    <style>
        :root {
            --brand: #0f6e8c;
            --brand-dark: #0a5069;
            --brand-soft: #eaf5f8;
        }
        body { background: #f6f8f9; font-family: "Segoe UI", system-ui, -apple-system, sans-serif; }
        .navbar-brand-custom { font-weight: 700; color: var(--brand-dark) !important; letter-spacing: -0.02em; }
        .card-panel { border: none; border-radius: 16px; box-shadow: 0 4px 24px rgba(15, 110, 140, 0.08); }
        .form-select:focus, .form-control:focus { border-color: var(--brand); box-shadow: 0 0 0 0.2rem rgba(15, 110, 140, 0.15); }
        .btn-brand { background: var(--brand); border-color: var(--brand); color: #fff; }
        .btn-brand:hover { background: var(--brand-dark); border-color: var(--brand-dark); color: #fff; }
        .table thead th {
            background: var(--brand-soft); color: var(--brand-dark);
            font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.03em;
            border-bottom: none; white-space: nowrap;
        }
        .table td { vertical-align: middle; font-size: 0.9rem; }
        .section-title { color: var(--brand-dark); font-weight: 700; }
    </style>
</head>
<body>

    <nav class="navbar navbar-light bg-white border-bottom mb-4">
        <div class="container-fluid px-4">
            <span class="navbar-brand navbar-brand-custom">
                <i class="bi bi-clock-history me-2"></i>Çalışma Saati Ayarları
            </span>
            <div class="d-flex gap-3">
                <a href="index.php" class="text-decoration-none small text-muted">
                    <i class="bi bi-clipboard2-pulse"></i> Randevu Listesine Dön
                </a>
                <a href="rezervasyon.php" class="text-decoration-none small text-muted">
                    <i class="bi bi-calendar-plus"></i> Müşteri: Online Randevu Al
                </a>
            </div>
        </div>
    </nav>

    <div class="container-fluid px-4">

        <?php if ($message): ?>
            <div class="alert alert-success d-flex align-items-center" role="alert">
                <i class="bi bi-check-circle-fill me-2"></i> <?= htmlspecialchars($message) ?>
            </div>
        <?php endif; ?>
        <?php if ($error): ?>
            <div class="alert alert-danger d-flex align-items-center" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2"></i> <?= htmlspecialchars($error) ?>
            </div>
        <?php endif; ?>

        <div class="card card-panel mb-4">
            <div class="card-body p-4">
                <h1 class="h5 section-title mb-3">
                    <i class="bi bi-plus-circle me-1"></i> Yeni Çalışma Saati Tanımla / Güncelle
                </h1>

                <form method="post" action="business_hours.php" class="row g-3">

                    <div class="col-md-6">
                        <label for="doctor_clinic_id" class="form-label small fw-semibold">Doktor - Klinik</label>
                        <select name="doctor_clinic_id" id="doctor_clinic_id" class="form-select" required>
                            <option value="">-- Seçiniz --</option>
                            <?php foreach ($doctor_clinics as $row): ?>
                                <option value="<?= $row['doctor_clinic_id'] ?>">
                                    <?= htmlspecialchars($row['last_name'] . ' ' . $row['first_name'] . ' - ' . $row['clinic_name'] . ' (Oda: ' . $row['room_number'] . ')') ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>

                    <div class="col-md-6">
                        <label for="day_of_week" class="form-label small fw-semibold">Gün</label>
                        <select name="day_of_week" id="day_of_week" class="form-select" required>
                            <option value="">-- Seçiniz --</option>
                            <?php foreach ($days as $key => $label): ?>
                                <option value="<?= $key ?>"><?= $label ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>

                    <div class="col-md-3">
                        <label for="start_time" class="form-label small fw-semibold">Çalışma Başlangıç</label>
                        <input type="time" name="start_time" id="start_time" class="form-control" required>
                    </div>

                    <div class="col-md-3">
                        <label for="end_time" class="form-label small fw-semibold">Çalışma Bitiş</label>
                        <input type="time" name="end_time" id="end_time" class="form-control" required>
                    </div>

                    <div class="col-md-3">
                        <label for="break_start" class="form-label small fw-semibold">Mola Başlangıç</label>
                        <input type="time" name="break_start" id="break_start" class="form-control">
                    </div>

                    <div class="col-md-3">
                        <label for="break_end" class="form-label small fw-semibold">Mola Bitiş</label>
                        <input type="time" name="break_end" id="break_end" class="form-control">
                        <div class="form-text">Mola tanımlamak istemiyorsanız boş bırakın.</div>
                    </div>

                    <div class="col-md-4">
                        <label for="slot_duration_minutes" class="form-label small fw-semibold">Randevu Aralığı (dakika)</label>
                        <input type="number" name="slot_duration_minutes" id="slot_duration_minutes" class="form-control" value="20" min="5" max="120" required>
                    </div>

                    <div class="col-12">
                        <button type="submit" name="save_business_hour" value="1" class="btn btn-brand">
                            <i class="bi bi-save me-1"></i> Kaydet
                        </button>
                    </div>

                </form>
            </div>
        </div>

        <div class="card card-panel">
            <div class="card-body p-4">
                <h2 class="h6 section-title mb-3">
                    <i class="bi bi-table me-1"></i> Tanımlı Çalışma Saatleri
                </h2>

                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
                            <tr>
                                <th>Doktor</th>
                                <th>Klinik</th>
                                <th>Gün</th>
                                <th>Başlangıç</th>
                                <th>Bitiş</th>
                                <th>Mola Başlangıç</th>
                                <th>Mola Bitiş</th>
                                <th>Aralık (dk)</th>
                                <th class="text-end">İşlem</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (count($existing) === 0): ?>
                                <tr>
                                    <td colspan="9" class="text-center text-muted py-4">
                                        <i class="bi bi-inbox me-1"></i> Henüz tanımlı çalışma saati yok.
                                    </td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($existing as $row): ?>
                                    <tr>
                                        <td class="fw-semibold"><?= htmlspecialchars($row['last_name'] . ' ' . $row['first_name']) ?></td>
                                        <td><?= htmlspecialchars($row['clinic_name']) ?></td>
                                        <td><span class="badge text-bg-light border"><?= htmlspecialchars($days[$row['day_of_week']] ?? $row['day_of_week']) ?></span></td>
                                        <td><?= htmlspecialchars($row['start_time']) ?></td>
                                        <td><?= htmlspecialchars($row['end_time']) ?></td>
                                        <td><?= htmlspecialchars($row['break_start'] ?? '-') ?></td>
                                        <td><?= htmlspecialchars($row['break_end'] ?? '-') ?></td>
                                        <td><?= htmlspecialchars($row['slot_duration_minutes']) ?></td>
                                        <td class="text-end">
                                            <a href="business_hours.php?delete_id=<?= $row['business_hour_id'] ?>"
                                               class="btn btn-sm btn-outline-danger"
                                               onclick="return confirm('Bu çalışma saatini silmek istediğinize emin misiniz?');">
                                                <i class="bi bi-trash3"></i> Sil
                                            </a>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>

                <div class="alert alert-info d-flex align-items-start mt-4 mb-0" role="alert">
                    <i class="bi bi-info-circle-fill me-2 mt-1"></i>
                    <div>
                        Bir doktor için haftanın bir günü burada listede yoksa, o doktor o gün
                        <strong>çalışmıyor</strong> kabul edilir ve <code>appointments</code>
                        tablosundaki trigger o güne randevu girişini otomatik olarak reddeder.
                    </div>
                </div>
            </div>
        </div>

    </div>

    <div class="mb-4"></div>

</body>
</html>
