<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <?php
/* =====================================================================
   index.php - Randevu Sistemi Test Arayüzü
   Amaç: Tasarımsız, sade HTML5 ile appointments tablosunu (ve ilişkili
   patients/doctors/clinics/departments/services tablolarını) Bölüm,
   Klinik ve Doktor seçerek filtreleyip test etmek.
   ===================================================================== */

// -----------------------------------------------------------------
// 1) VERİTABANI BAĞLANTISI - kendi bilgilerinizle değiştirin
// -----------------------------------------------------------------
$db_host = "localhost";
$db_user = "root";
$db_pass = "";
$db_name = "randevu_sistemi";

$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) {
    die("Veritabanı bağlantı hatası: " . $conn->connect_error);
}
$conn->set_charset("utf8mb4");

// -----------------------------------------------------------------
// 2) FİLTRE DEĞERLERİNİ OKU (GET ile formdan gelir)
// -----------------------------------------------------------------
$selected_department = isset($_GET['department_id']) ? (int)$_GET['department_id'] : 0;
$selected_clinic      = isset($_GET['clinic_id']) ? (int)$_GET['clinic_id'] : 0;
$selected_doctor      = isset($_GET['doctor_id']) ? (int)$_GET['doctor_id'] : 0;

// -----------------------------------------------------------------
// 3) DROPDOWN İÇİN VERİLERİ ÇEK
// -----------------------------------------------------------------
$departments = $conn->query("SELECT department_id, name FROM departments ORDER BY name");
$clinics     = $conn->query("SELECT clinic_id, name FROM clinics ORDER BY name");
$doctors     = $conn->query("SELECT doctor_id, first_name, last_name FROM doctors ORDER BY last_name, first_name");

// -----------------------------------------------------------------
// 4) RANDEVULARI FİLTRELERE GÖRE ÇEK (prepared statement)
// -----------------------------------------------------------------
$sql = "
    SELECT
        a.appointment_id,
        p.first_name AS patient_first_name,
        p.last_name  AS patient_last_name,
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
$types  = "";

if ($selected_department > 0) {
    $sql .= " AND dep.department_id = ? ";
    $params[] = $selected_department;
    $types   .= "i";
}
if ($selected_clinic > 0) {
    $sql .= " AND c.clinic_id = ? ";
    $params[] = $selected_clinic;
    $types   .= "i";
}
if ($selected_doctor > 0) {
    $sql .= " AND d.doctor_id = ? ";
    $params[] = $selected_doctor;
    $types   .= "i";
}

$sql .= " ORDER BY a.appointment_date, a.start_time ";

$stmt = $conn->prepare($sql);
if ($params) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$result = $stmt->get_result();
?>
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>Randevu Sistemi - Test Arayüzü</title>
</head>
<body>

    <h1>Randevu Sistemi - Test Arayüzü</h1>

    <form method="get" action="index.php">

        <label for="department_id">Bölüm:</label>
        <select name="department_id" id="department_id">
            <option value="0">-- Tümü --</option>
            <?php while ($row = $departments->fetch_assoc()): ?>
                <option value="<?= $row['department_id'] ?>"
                    <?= ($selected_department == $row['department_id']) ? 'selected' : '' ?>>
                    <?= htmlspecialchars($row['name']) ?>
                </option>
            <?php endwhile; ?>
        </select>

        <label for="clinic_id">Klinik:</label>
        <select name="clinic_id" id="clinic_id">
            <option value="0">-- Tümü --</option>
            <?php while ($row = $clinics->fetch_assoc()): ?>
                <option value="<?= $row['clinic_id'] ?>"
                    <?= ($selected_clinic == $row['clinic_id']) ? 'selected' : '' ?>>
                    <?= htmlspecialchars($row['name']) ?>
                </option>
            <?php endwhile; ?>
        </select>

        <label for="doctor_id">Doktor:</label>
        <select name="doctor_id" id="doctor_id">
            <option value="0">-- Tümü --</option>
            <?php while ($row = $doctors->fetch_assoc()): ?>
                <option value="<?= $row['doctor_id'] ?>"
                    <?= ($selected_doctor == $row['doctor_id']) ? 'selected' : '' ?>>
                    <?= htmlspecialchars($row['last_name'] . ' ' . $row['first_name']) ?>
                </option>
            <?php endwhile; ?>
        </select>

        <input type="submit" value="Filtrele">
        <a href="index.php">Filtreleri Temizle</a>

    </form>

    <hr>

    <table border="1" cellpadding="5" cellspacing="0">
        <thead>
            <tr>
                <th>Randevu ID</th>
                <th>Hasta</th>
                <th>Doktor</th>
                <th>Bölüm</th>
                <th>Klinik</th>
                <th>Hizmet</th>
                <th>Tarih</th>
                <th>Başlangıç</th>
                <th>Bitiş</th>
                <th>Durum</th>
                <th>Ödeme Durumu</th>
            </tr>
        </thead>
        <tbody>
            <?php if ($result->num_rows === 0): ?>
                <tr>
                    <td colspan="11">Seçilen filtrelere uygun randevu bulunamadı.</td>
                </tr>
            <?php else: ?>
                <?php while ($row = $result->fetch_assoc()): ?>
                    <tr>
                        <td><?= $row['appointment_id'] ?></td>
                        <td><?= htmlspecialchars($row['patient_first_name'] . ' ' . $row['patient_last_name']) ?></td>
                        <td><?= htmlspecialchars($row['doctor_first_name'] . ' ' . $row['doctor_last_name']) ?></td>
                        <td><?= htmlspecialchars($row['department_name']) ?></td>
                        <td><?= htmlspecialchars($row['clinic_name']) ?></td>
                        <td><?= htmlspecialchars($row['service_name'] ?? '-') ?></td>
                        <td><?= htmlspecialchars($row['appointment_date']) ?></td>
                        <td><?= htmlspecialchars($row['start_time']) ?></td>
                        <td><?= htmlspecialchars($row['end_time']) ?></td>
                        <td><?= htmlspecialchars($row['status']) ?></td>
                        <td><?= htmlspecialchars($row['payment_status']) ?></td>
                    </tr>
                <?php endwhile; ?>
            <?php endif; ?>
        </tbody>
    </table>

    <p>Toplam kayıt: <?= $result->num_rows ?></p>

</body>
</html>
<?php
$stmt->close();
$conn->close();
?>

</body>
</html>