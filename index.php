<?php
/* =====================================================================
   index.php - Randevu Sistemi Admin: Randevu Listesi
   Bölüm, Klinik ve Doktor seçerek appointments tablosunu filtreler.

   Story 2.3 (devamı): Bootstrap 5 ile görsel güncelleme. SADECE
   HTML/CSS/class isimleri değişti — sorgular, filtre mantığı, GET
   parametreleri birebir aynı kaldı.
   ===================================================================== */

require_once __DIR__ . '/Database.php';

try {
    $database = new Database();
    $pdo = $database->connect();
} catch (PDOException $e) {
    die("Veritabanı bağlantı hatası: " . htmlspecialchars($e->getMessage()) .
        "<br>XAMPP'ta MySQL servisinin çalıştığından ve randevu_sistemi " .
        "veritabanının oluşturulduğundan emin olun.");
}

// -----------------------------------------------------------------
// 2) FİLTRE DEĞERLERİNİ OKU (GET ile formdan gelir)
// -----------------------------------------------------------------
$selected_department = isset($_GET['department_id']) ? (int)$_GET['department_id'] : 0;
$selected_clinic      = isset($_GET['clinic_id']) ? (int)$_GET['clinic_id'] : 0;
$selected_doctor      = isset($_GET['doctor_id']) ? (int)$_GET['doctor_id'] : 0;

// -----------------------------------------------------------------
// 3) DROPDOWN İÇİN VERİLERİ ÇEK
// -----------------------------------------------------------------
$departments = $pdo->query("SELECT department_id, name FROM departments ORDER BY name")->fetchAll();
$clinics     = $pdo->query("SELECT clinic_id, name FROM clinics ORDER BY name")->fetchAll();
$doctors     = $pdo->query("SELECT doctor_id, first_name, last_name FROM doctors ORDER BY last_name, first_name")->fetchAll();

// -----------------------------------------------------------------
// 4) RANDEVULARI FİLTRELERE GÖRE ÇEK (prepared statement)
// -----------------------------------------------------------------
$sql = "
    SELECT
        a.appointment_id,
        p.first_name AS patient_first_name,
        p.last_name  AS patient_last_name,
        p.phone      AS patient_phone,
        d.first_name AS doctor_first_name,
        d.last_name  AS doctor_last_name,
        dep.name     AS department_name,
        c.name       AS clinic_name,
        s.name       AS service_name,
        a.appointment_date,
        a.start_time,
        a.end_time,
        a.status,
        a.payment_status
    FROM appointments a
    INNER JOIN patients   p   ON p.patient_id = a.patient_id
    INNER JOIN doctors    d   ON d.doctor_id = a.doctor_id
    INNER JOIN clinics    c   ON c.clinic_id = a.clinic_id
    INNER JOIN departments dep ON dep.department_id = c.department_id
    LEFT  JOIN services   s   ON s.service_id = a.service_id
    WHERE 1=1
";

$params = [];

if ($selected_department > 0) {
    $sql .= " AND dep.department_id = :department_id ";
    $params['department_id'] = $selected_department;
}
if ($selected_clinic > 0) {
    $sql .= " AND c.clinic_id = :clinic_id ";
    $params['clinic_id'] = $selected_clinic;
}
if ($selected_doctor > 0) {
    $sql .= " AND d.doctor_id = :doctor_id ";
    $params['doctor_id'] = $selected_doctor;
}

$sql .= " ORDER BY a.appointment_date, a.start_time ";

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$appointments = $stmt->fetchAll();
$total_count  = count($appointments);

// -----------------------------------------------------------------
// Sadece görsel amaçlı yardımcı: durum/ödeme değerine göre Bootstrap
// badge rengi seç. İş mantığını etkilemez, sadece renklendirme.
// -----------------------------------------------------------------
function statusBadgeClass($status) {
    $map = [
        'SCHEDULED' => 'text-bg-primary',
        'CONFIRMED' => 'text-bg-success',
        'COMPLETED' => 'text-bg-secondary',
        'CANCELLED' => 'text-bg-danger',
        'NO_SHOW'   => 'text-bg-warning',
    ];
    return $map[$status] ?? 'text-bg-light';
}

function paymentBadgeClass($status) {
    $map = [
        'PAID'              => 'text-bg-success',
        'PENDING'           => 'text-bg-warning',
        'WAIVED'            => 'text-bg-secondary',
        'INSURANCE_PENDING' => 'text-bg-info',
    ];
    return $map[$status] ?? 'text-bg-light';
}
?>
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Randevu Sistemi - Admin: Randevu Listesi</title>

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
        .form-select:focus { border-color: var(--brand); box-shadow: 0 0 0 0.2rem rgba(15, 110, 140, 0.15); }
        .btn-brand { background: var(--brand); border-color: var(--brand); color: #fff; }
        .btn-brand:hover { background: var(--brand-dark); border-color: var(--brand-dark); color: #fff; }
        .table thead th {
            background: var(--brand-soft); color: var(--brand-dark);
            font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.03em;
            border-bottom: none; white-space: nowrap;
        }
        .table td { vertical-align: middle; font-size: 0.9rem; }
        .badge { font-weight: 600; font-size: 0.72rem; }
    </style>
</head>
<body>

    <nav class="navbar navbar-light bg-white border-bottom mb-4">
        <div class="container-fluid px-4">
            <span class="navbar-brand navbar-brand-custom">
                <i class="bi bi-clipboard2-pulse me-2"></i>Randevu Sistemi - Admin
            </span>
            <div class="d-flex gap-3">
                <a href="business_hours.php" class="text-decoration-none small text-muted">
                    <i class="bi bi-clock-history"></i> Çalışma Saati Ayarları
                </a>
                <a href="rezervasyon.php" class="text-decoration-none small text-muted">
                    <i class="bi bi-calendar-plus"></i> Müşteri: Online Randevu Al
                </a>
            </div>
        </div>
    </nav>

    <div class="container-fluid px-4">

        <div class="card card-panel mb-4">
            <div class="card-body p-4">
                <h1 class="h5 fw-bold mb-3" style="color: var(--brand-dark);">
                    <i class="bi bi-funnel me-1"></i> Randevu Filtrele
                </h1>

                <form method="get" action="index.php" class="row g-3 align-items-end">

                    <div class="col-sm-6 col-lg-3">
                        <label for="department_id" class="form-label small fw-semibold">Bölüm</label>
                        <select name="department_id" id="department_id" class="form-select">
                            <option value="0">-- Tümü --</option>
                            <?php foreach ($departments as $row): ?>
                                <option value="<?= $row['department_id'] ?>"
                                    <?= ($selected_department == $row['department_id']) ? 'selected' : '' ?>>
                                    <?= htmlspecialchars($row['name']) ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>

                    <div class="col-sm-6 col-lg-3">
                        <label for="clinic_id" class="form-label small fw-semibold">Klinik</label>
                        <select name="clinic_id" id="clinic_id" class="form-select">
                            <option value="0">-- Tümü --</option>
                            <?php foreach ($clinics as $row): ?>
                                <option value="<?= $row['clinic_id'] ?>"
                                    <?= ($selected_clinic == $row['clinic_id']) ? 'selected' : '' ?>>
                                    <?= htmlspecialchars($row['name']) ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>

                    <div class="col-sm-6 col-lg-3">
                        <label for="doctor_id" class="form-label small fw-semibold">Doktor</label>
                        <select name="doctor_id" id="doctor_id" class="form-select">
                            <option value="0">-- Tümü --</option>
                            <?php foreach ($doctors as $row): ?>
                                <option value="<?= $row['doctor_id'] ?>"
                                    <?= ($selected_doctor == $row['doctor_id']) ? 'selected' : '' ?>>
                                    <?= htmlspecialchars($row['last_name'] . ' ' . $row['first_name']) ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>

                    <div class="col-sm-6 col-lg-3 d-flex gap-2">
                        <button type="submit" class="btn btn-brand flex-fill">
                            <i class="bi bi-search me-1"></i>Filtrele
                        </button>
                        <a href="index.php" class="btn btn-outline-secondary" title="Filtreleri Temizle">
                            <i class="bi bi-x-lg"></i>
                        </a>
                    </div>

                </form>
            </div>
        </div>

        <div class="card card-panel">
            <div class="card-body p-4">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h2 class="h6 fw-bold mb-0" style="color: var(--brand-dark);">
                        <i class="bi bi-list-check me-1"></i> Randevular
                    </h2>
                    <span class="badge text-bg-light border">Toplam kayıt: <?= $total_count ?></span>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Hasta</th>
                                <th>Telefon</th>
                                <th>Doktor</th>
                                <th>Bölüm</th>
                                <th>Klinik</th>
                                <th>Hizmet</th>
                                <th>Tarih</th>
                                <th>Başlangıç</th>
                                <th>Bitiş</th>
                                <th>Durum</th>
                                <th>Ödeme</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if ($total_count === 0): ?>
                                <tr>
                                    <td colspan="12" class="text-center text-muted py-4">
                                        <i class="bi bi-inbox me-1"></i>
                                        Seçilen filtrelere uygun randevu bulunamadı.
                                    </td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($appointments as $row): ?>
                                    <tr>
                                        <td class="text-muted">#<?= $row['appointment_id'] ?></td>
                                        <td class="fw-semibold"><?= htmlspecialchars($row['patient_first_name'] . ' ' . $row['patient_last_name']) ?></td>
                                        <td><?= htmlspecialchars($row['patient_phone']) ?></td>
                                        <td><?= htmlspecialchars($row['doctor_first_name'] . ' ' . $row['doctor_last_name']) ?></td>
                                        <td><?= htmlspecialchars($row['department_name']) ?></td>
                                        <td><?= htmlspecialchars($row['clinic_name']) ?></td>
                                        <td><?= htmlspecialchars($row['service_name'] ?? '-') ?></td>
                                        <td><?= htmlspecialchars($row['appointment_date']) ?></td>
                                        <td><?= htmlspecialchars($row['start_time']) ?></td>
                                        <td><?= htmlspecialchars($row['end_time']) ?></td>
                                        <td><span class="badge <?= statusBadgeClass($row['status']) ?>"><?= htmlspecialchars($row['status']) ?></span></td>
                                        <td><span class="badge <?= paymentBadgeClass($row['payment_status']) ?>"><?= htmlspecialchars($row['payment_status']) ?></span></td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    </div>

    <div class="mb-4"></div>

</body>
</html>
