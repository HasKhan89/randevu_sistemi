<?php
/* =====================================================================
   business_hours.php - Doktor Çalışma Saati / Mola Ayarları (Admin)
   Story 1.2: Hastane çalışanının kendi çalışma günü, saati ve mola
   vaktini tanımlayabildiği sade bir admin ayarlar sayfası.
   Veriler business_hours tablosuna yazılır. Aynı doktor-klinik-gün
   kombinasyonu tekrar girilirse UPSERT yapılır (üzerine yazılır).
   ===================================================================== */

$db_host = "localhost";
$db_user = "root";
$db_pass = "";
$db_name = "randevu_sistemi";

$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) {
    die("Veritabanı bağlantı hatası: " . $conn->connect_error);
}
$conn->set_charset("utf8mb4");

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
        $stmt = $conn->prepare("
            INSERT INTO business_hours
                (doctor_clinic_id, day_of_week, start_time, end_time, break_start, break_end, slot_duration_minutes)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                start_time = VALUES(start_time),
                end_time   = VALUES(end_time),
                break_start = VALUES(break_start),
                break_end   = VALUES(break_end),
                slot_duration_minutes = VALUES(slot_duration_minutes)
        ");

        if ($stmt === false) {
            $error = "SQL Hatası: " . $conn->error . " — business_hours tablosu eksik olabilir, " .
                     "randevu_sistemi_master.sql'in tamamının çalıştırıldığından emin olun.";
        } else {
            $stmt->bind_param("isssssi",
                $doctor_clinic_id, $day_of_week, $start_time, $end_time,
                $break_start, $break_end, $slot_duration
            );

            if ($stmt->execute()) {
                $message = "Çalışma saati kaydedildi.";
            } else {
                $error = "Kayıt sırasında hata oluştu: " . $stmt->error;
            }
            $stmt->close();
        }
    }
}

// -----------------------------------------------------------------
// SİLME İŞLEMİ
// -----------------------------------------------------------------
if (isset($_GET['delete_id'])) {
    $delete_id = (int)$_GET['delete_id'];
    $stmt = $conn->prepare("DELETE FROM business_hours WHERE business_hour_id = ?");
    if ($stmt === false) {
        $error = "SQL Hatası: " . $conn->error;
    } else {
        $stmt->bind_param("i", $delete_id);
        $stmt->execute();
        $stmt->close();
        $message = "Kayıt silindi.";
    }
}

// -----------------------------------------------------------------
// DROPDOWN İÇİN: Doktor + Klinik kombinasyonları (doctor_clinics)
// -----------------------------------------------------------------
$doctor_clinics = $conn->query("
    SELECT dc.doctor_clinic_id, d.first_name, d.last_name, c.name AS clinic_name, dc.room_number
    FROM doctor_clinics dc
    INNER JOIN doctors d ON d.doctor_id = dc.doctor_id
    INNER JOIN clinics c ON c.clinic_id = dc.clinic_id
    WHERE dc.is_active = 1
    ORDER BY d.last_name, d.first_name
");
if ($doctor_clinics === false) {
    die("SQL Hatası (doctor_clinics sorgusu): " . $conn->error .
        "<br>Muhtemel sebep: doctor_clinics/doctors/clinics tabloları eksik. " .
        "randevu_sistemi_master.sql dosyasının BAŞTAN SONA (tek parça halinde) " .
        "çalıştırıldığından emin olun.");
}

// -----------------------------------------------------------------
// MEVCUT ÇALIŞMA SAATLERİNİ LİSTELE
// -----------------------------------------------------------------
$existing = $conn->query("
    SELECT bh.business_hour_id, bh.day_of_week, bh.start_time, bh.end_time,
           bh.break_start, bh.break_end, bh.slot_duration_minutes,
           d.first_name, d.last_name, c.name AS clinic_name
    FROM business_hours bh
    INNER JOIN doctor_clinics dc ON dc.doctor_clinic_id = bh.doctor_clinic_id
    INNER JOIN doctors d ON d.doctor_id = dc.doctor_id
    INNER JOIN clinics c ON c.clinic_id = dc.clinic_id
    ORDER BY d.last_name, d.first_name,
             FIELD(bh.day_of_week,'MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY')
");
if ($existing === false) {
    die("SQL Hatası (business_hours sorgusu): " . $conn->error .
        "<br>Muhtemel sebep: business_hours tablosu henüz oluşturulmamış. " .
        "randevu_sistemi_master.sql dosyasının BAŞTAN SONA çalıştırıldığından emin olun.");
}
?>
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>Doktor Çalışma Saati Ayarları</title>
</head>
<body>

    <h1>Doktor Çalışma Saati / Mola Ayarları</h1>
    <p><a href="index.php">&laquo; Randevu listesine dön</a></p>

    <?php if ($message): ?>
        <p><strong><?= htmlspecialchars($message) ?></strong></p>
    <?php endif; ?>
    <?php if ($error): ?>
        <p><strong>HATA:</strong> <?= htmlspecialchars($error) ?></p>
    <?php endif; ?>

    <h2>Yeni Çalışma Saati Tanımla / Güncelle</h2>

    <form method="post" action="business_hours.php">

        <label for="doctor_clinic_id">Doktor - Klinik:</label>
        <select name="doctor_clinic_id" id="doctor_clinic_id" required>
            <option value="">-- Seçiniz --</option>
            <?php while ($row = $doctor_clinics->fetch_assoc()): ?>
                <option value="<?= $row['doctor_clinic_id'] ?>">
                    <?= htmlspecialchars($row['last_name'] . ' ' . $row['first_name'] . ' - ' . $row['clinic_name'] . ' (Oda: ' . $row['room_number'] . ')') ?>
                </option>
            <?php endwhile; ?>
        </select>
        <br><br>

        <label for="day_of_week">Gün:</label>
        <select name="day_of_week" id="day_of_week" required>
            <option value="">-- Seçiniz --</option>
            <?php foreach ($days as $key => $label): ?>
                <option value="<?= $key ?>"><?= $label ?></option>
            <?php endforeach; ?>
        </select>
        <br><br>

        <label for="start_time">Çalışma Başlangıç Saati:</label>
        <input type="time" name="start_time" id="start_time" required>
        &nbsp;&nbsp;
        <label for="end_time">Çalışma Bitiş Saati:</label>
        <input type="time" name="end_time" id="end_time" required>
        <br><br>

        <label for="break_start">Mola (Öğle Arası) Başlangıç:</label>
        <input type="time" name="break_start" id="break_start">
        &nbsp;&nbsp;
        <label for="break_end">Mola Bitiş:</label>
        <input type="time" name="break_end" id="break_end">
        <br><small>Mola tanımlamak istemiyorsanız bu iki alanı boş bırakın.</small>
        <br><br>

        <label for="slot_duration_minutes">Randevu Aralığı (dakika):</label>
        <input type="number" name="slot_duration_minutes" id="slot_duration_minutes" value="20" min="5" max="120" required>
        <br><br>

        <input type="submit" name="save_business_hour" value="Kaydet">

    </form>

    <hr>

    <h2>Tanımlı Çalışma Saatleri</h2>

    <table border="1" cellpadding="5" cellspacing="0">
        <thead>
            <tr>
                <th>Doktor</th>
                <th>Klinik</th>
                <th>Gün</th>
                <th>Başlangıç</th>
                <th>Bitiş</th>
                <th>Mola Başlangıç</th>
                <th>Mola Bitiş</th>
                <th>Randevu Aralığı (dk)</th>
                <th>İşlem</th>
            </tr>
        </thead>
        <tbody>
            <?php if ($existing->num_rows === 0): ?>
                <tr><td colspan="9">Henüz tanımlı çalışma saati yok.</td></tr>
            <?php else: ?>
                <?php while ($row = $existing->fetch_assoc()): ?>
                    <tr>
                        <td><?= htmlspecialchars($row['last_name'] . ' ' . $row['first_name']) ?></td>
                        <td><?= htmlspecialchars($row['clinic_name']) ?></td>
                        <td><?= htmlspecialchars($days[$row['day_of_week']] ?? $row['day_of_week']) ?></td>
                        <td><?= htmlspecialchars($row['start_time']) ?></td>
                        <td><?= htmlspecialchars($row['end_time']) ?></td>
                        <td><?= htmlspecialchars($row['break_start'] ?? '-') ?></td>
                        <td><?= htmlspecialchars($row['break_end'] ?? '-') ?></td>
                        <td><?= htmlspecialchars($row['slot_duration_minutes']) ?></td>
                        <td>
                            <a href="business_hours.php?delete_id=<?= $row['business_hour_id'] ?>"
                               onclick="return confirm('Bu çalışma saatini silmek istediğinize emin misiniz?');">
                                Sil
                            </a>
                        </td>
                    </tr>
                <?php endwhile; ?>
            <?php endif; ?>
        </tbody>
    </table>

    <p>
        Not: Bir doktor için haftanın bir günü burada listede yoksa,
        o doktor o gün <strong>çalışmıyor</strong> kabul edilir ve
        appointments tablosundaki trigger o güne randevu girişini
        otomatik olarak reddeder.
    </p>

</body>
</html>
<?php
$conn->close();
?>
