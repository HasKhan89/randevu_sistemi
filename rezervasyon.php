<?php
/* =====================================================================
   rezervasyon.php - Epic 2 Sprint: Cascade (Zincirleme) Randevu Formu
   Bölüm -> Klinik -> Doktor -> Tarih seçimi, hepsi sayfa yenilenmeden
   (Fetch API) yapılır. Son adımda boş saatler buton olarak listelenir.

   Story 2.3: Bootstrap 5 ile görsel iyileştirme. Bu güncellemede SADECE
   HTML/CSS/class isimleri değişti — fetch() çağrıları, endpoint'ler,
   veri akışı ve iş mantığı birebir aynı kaldı.

   Kullanılan uç noktalar:
     - get_clinics.php          (Adım: Bölüm seçilince)
     - get_doctors.php          (Adım: Klinik seçilince)
     - get_available_slots.php  (Adım: Doktor + Tarih seçilince)
     - create_appointment.php   (Adım: Saat + Ad Soyad + Telefon ile kaydet)
   ===================================================================== */

require_once __DIR__ . '/Database.php';

try {
    $database = new Database();
    $pdo = $database->connect();
} catch (PDOException $e) {
    die("Veritabanı bağlantı hatası: " . htmlspecialchars($e->getMessage()));
}

// Sadece ilk select (Bölüm) sayfa yüklenirken PHP ile dolduruluyor.
// Klinik/Doktor/Tarih zincirleme olarak JS ile açılacak.
$departments = $pdo->query("SELECT department_id, name FROM departments ORDER BY name")->fetchAll();
?>
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Randevu Al - Bölüm / Klinik / Doktor / Tarih</title>

    <link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.3.3/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">

    <style>
        :root {
            /* Klinik/hastane hissi veren sakin, güven telkin eden ton paleti.
               Bootstrap'ın varsayılan mavisi yerine biraz daha yumuşak bir
               teal-mavi kullanıyoruz. */
            --brand: #0f6e8c;
            --brand-dark: #0a5069;
            --brand-soft: #eaf5f8;
            --ok: #1a7f5a;
        }
        body {
            background: #f6f8f9;
            font-family: "Segoe UI", system-ui, -apple-system, sans-serif;
        }
        .navbar-brand-custom {
            font-weight: 700;
            color: var(--brand-dark) !important;
            letter-spacing: -0.02em;
        }
        .card-booking {
            border: none;
            border-radius: 16px;
            box-shadow: 0 4px 24px rgba(15, 110, 140, 0.08);
        }
        .step-label {
            font-weight: 600;
            font-size: 0.85rem;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            color: var(--brand-dark);
        }
        .form-select:focus, .form-control:focus {
            border-color: var(--brand);
            box-shadow: 0 0 0 0.2rem rgba(15, 110, 140, 0.15);
        }
        #time_slots { display: flex; flex-wrap: wrap; gap: 8px; }
        .slot-btn {
            min-width: 84px;
            padding: 10px 6px;
            border: 1px solid #cfd8dc;
            background: #fff;
            border-radius: 10px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            color: #37474f;
            transition: all 0.15s ease;
        }
        .slot-btn:hover { border-color: var(--brand); background: var(--brand-soft); }
        .slot-btn.selected {
            background: var(--brand);
            color: #fff;
            border-color: var(--brand);
            box-shadow: 0 2px 8px rgba(15, 110, 140, 0.35);
        }
        #patientSection { display: none; }
        .badge-step {
            width: 28px; height: 28px;
            border-radius: 50%;
            background: var(--brand-soft);
            color: var(--brand-dark);
            display: inline-flex;
            align-items: center; justify-content: center;
            font-weight: 700; font-size: 0.85rem;
        }
        .btn-brand {
            background: var(--brand); border-color: var(--brand); color: #fff;
        }
        .btn-brand:hover { background: var(--brand-dark); border-color: var(--brand-dark); color: #fff; }
        .btn-brand:disabled { opacity: 0.5; }
    </style>
</head>
<body>

    <nav class="navbar navbar-light bg-white border-bottom mb-4">
        <div class="container">
            <span class="navbar-brand navbar-brand-custom">
                <i class="bi bi-hospital me-2"></i>Online Randevu
            </span>
            <div class="d-flex gap-3">
                <a href="index.php" class="text-decoration-none small text-muted">
                    <i class="bi bi-clipboard2-pulse"></i> Admin: Randevu Listesi
                </a>
                <a href="business_hours.php" class="text-decoration-none small text-muted">
                    <i class="bi bi-clock-history"></i> Admin: Çalışma Saatleri
                </a>
            </div>
        </div>
    </nav>

    <div class="container" style="max-width: 720px;">
        <div class="card card-booking mb-4">
            <div class="card-body p-4 p-md-5">

                <h1 class="h3 fw-bold mb-1" style="color: var(--brand-dark);">Randevunuzu Oluşturun</h1>
                <p class="text-muted mb-4">Bölüm, klinik ve doktor seçin; size uygun bir saat bulalım.</p>

                <!-- ADIM 1: Bölüm -->
                <div class="mb-3">
                    <label for="department" class="form-label step-label">
                        <span class="badge-step me-1">1</span> Bölüm
                    </label>
                    <select id="department" class="form-select form-select-lg">
                        <option value="">-- Bölüm Seçiniz --</option>
                        <?php foreach ($departments as $row): ?>
                            <option value="<?= $row['department_id'] ?>"><?= htmlspecialchars($row['name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <!-- ADIM 2: Klinik -->
                <div class="mb-3">
                    <label for="clinic" class="form-label step-label">
                        <span class="badge-step me-1">2</span> Klinik
                    </label>
                    <select id="clinic" class="form-select form-select-lg" disabled>
                        <option value="">-- Önce bölüm seçin --</option>
                    </select>
                </div>

                <!-- ADIM 3: Doktor -->
                <div class="mb-3">
                    <label for="doctor" class="form-label step-label">
                        <span class="badge-step me-1">3</span> Doktor
                    </label>
                    <select id="doctor" class="form-select form-select-lg" disabled>
                        <option value="">-- Önce klinik seçin --</option>
                    </select>
                </div>

                <!-- ADIM 4: Tarih -->
                <div class="mb-4">
                    <label for="appointment_date" class="form-label step-label">
                        <span class="badge-step me-1">4</span> Tarih
                    </label>
                    <input type="date" id="appointment_date" class="form-control form-control-lg" disabled>
                </div>

                <!-- ADIM 5: Saatler -->
                <div class="mb-4">
                    <label class="form-label step-label">
                        <span class="badge-step me-1">5</span> Uygun Saatler
                    </label>
                    <div id="time_slots"></div>
                    <div id="slotsInfo" class="text-muted small mt-2"></div>
                </div>

                <!-- ADIM 6: Hasta Bilgileri -->
                <div id="patientSection" class="border-top pt-4">
                    <h2 class="h6 fw-bold step-label mb-3">
                        <span class="badge-step me-1">6</span> Hasta Bilgileri
                    </h2>

                    <div class="mb-3">
                        <label for="full_name" class="form-label">Ad Soyad</label>
                        <input type="text" id="full_name" class="form-control" required>
                    </div>

                    <div class="mb-3">
                        <label for="national_id" class="form-label">TC Kimlik No</label>
                        <input type="text" id="national_id" class="form-control"
                               placeholder="11 haneli TC Kimlik No" pattern="[1-9][0-9]{10}"
                               maxlength="11" inputmode="numeric" required>
                    </div>

                    <div class="mb-4">
                        <label for="phone" class="form-label">Telefon</label>
                        <input type="tel" id="phone" class="form-control"
                               placeholder="05XXXXXXXXX" pattern="0[0-9]{10}" required>
                    </div>

                    <button type="button" id="submitBtn" class="btn btn-brand btn-lg w-100">
                        <i class="bi bi-calendar-check me-1"></i> Randevu Oluştur
                    </button>
                </div>

                <div id="resultMessage" class="mt-3 fw-semibold"></div>

            </div>
        </div>
    </div>

    <script>
    const departmentSelect = document.getElementById('department');
    const clinicSelect     = document.getElementById('clinic');
    const doctorSelect     = document.getElementById('doctor');
    const dateInput        = document.getElementById('appointment_date');
    const timeSlotsDiv     = document.getElementById('time_slots');
    const slotsInfo        = document.getElementById('slotsInfo');
    const patientSection   = document.getElementById('patientSection');
    const submitBtn        = document.getElementById('submitBtn');
    const resultMessage    = document.getElementById('resultMessage');

    let selectedSlot = null; // { start_time, end_time }

    // Bugünden önceki tarihler seçilemesin
    dateInput.min = new Date().toISOString().split('T')[0];

    // -----------------------------------------------------------
    // Yardımcı: bir select box'ı sıfırla ve devre dışı bırak
    // -----------------------------------------------------------
    function resetSelect(selectEl, placeholderText) {
        selectEl.innerHTML = '<option value="">' + placeholderText + '</option>';
        selectEl.disabled = true;
    }

    function resetSlots() {
        timeSlotsDiv.innerHTML = '';
        slotsInfo.textContent = '';
        selectedSlot = null;
        patientSection.style.display = 'none';
        resultMessage.textContent = '';
        resultMessage.className = 'mt-3 fw-semibold';
    }

    // -----------------------------------------------------------
    // ADIM: Bölüm değişince -> get_clinics.php
    // -----------------------------------------------------------
    departmentSelect.addEventListener('change', function () {
        resetSelect(clinicSelect, '-- Önce bölüm seçin --');
        resetSelect(doctorSelect, '-- Önce klinik seçin --');
        dateInput.value = '';
        dateInput.disabled = true;
        resetSlots();

        const departmentId = departmentSelect.value;
        if (!departmentId) return;

        clinicSelect.innerHTML = '<option value="">Yükleniyor...</option>';

        fetch('get_clinics.php?department_id=' + encodeURIComponent(departmentId))
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (!data.success) {
                    resetSelect(clinicSelect, '-- Hata --');
                    slotsInfo.textContent = data.message || 'Klinikler yüklenemedi.';
                    return;
                }
                if (data.clinics.length === 0) {
                    resetSelect(clinicSelect, '-- Bu bölümde klinik yok --');
                    slotsInfo.textContent = data.message || '';
                    return;
                }
                clinicSelect.innerHTML = '<option value="">-- Klinik Seçiniz --</option>';
                data.clinics.forEach(function (c) {
                    const opt = document.createElement('option');
                    opt.value = c.id;
                    opt.textContent = c.name;
                    clinicSelect.appendChild(opt);
                });
                clinicSelect.disabled = false;
            })
            .catch(function (err) {
                resetSelect(clinicSelect, '-- Hata --');
                slotsInfo.textContent = 'Sunucuya ulaşılamadı: ' + err;
            });
    });

    // -----------------------------------------------------------
    // ADIM: Klinik değişince -> get_doctors.php
    // -----------------------------------------------------------
    clinicSelect.addEventListener('change', function () {
        resetSelect(doctorSelect, '-- Önce klinik seçin --');
        dateInput.value = '';
        dateInput.disabled = true;
        resetSlots();

        const clinicId = clinicSelect.value;
        if (!clinicId) return;

        doctorSelect.innerHTML = '<option value="">Yükleniyor...</option>';

        fetch('get_doctors.php?clinic_id=' + encodeURIComponent(clinicId))
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (!data.success) {
                    resetSelect(doctorSelect, '-- Hata --');
                    slotsInfo.textContent = data.message || 'Doktorlar yüklenemedi.';
                    return;
                }
                if (data.doctors.length === 0) {
                    resetSelect(doctorSelect, '-- Bu klinikte doktor yok --');
                    slotsInfo.textContent = data.message || '';
                    return;
                }
                doctorSelect.innerHTML = '<option value="">-- Doktor Seçiniz --</option>';
                data.doctors.forEach(function (d) {
                    const opt = document.createElement('option');
                    // NOT: value = doctor_clinic_id (get_available_slots.php ve
                    // create_appointment.php bu id'yi bekliyor).
                    opt.value = d.id;
                    opt.textContent = d.last_name + ' ' + d.first_name +
                        (d.specialty ? ' (' + d.specialty + ')' : '');
                    doctorSelect.appendChild(opt);
                });
                doctorSelect.disabled = false;
            })
            .catch(function (err) {
                resetSelect(doctorSelect, '-- Hata --');
                slotsInfo.textContent = 'Sunucuya ulaşılamadı: ' + err;
            });
    });

    // -----------------------------------------------------------
    // ADIM: Doktor seçilince tarih alanı aktifleşir
    // -----------------------------------------------------------
    doctorSelect.addEventListener('change', function () {
        dateInput.value = '';
        resetSlots();
        dateInput.disabled = !doctorSelect.value;
    });

    // -----------------------------------------------------------
    // ADIM: Doktor + Tarih hazır olunca -> get_available_slots.php
    // -----------------------------------------------------------
    function loadSlots() {
        resetSlots();

        const doctorClinicId = doctorSelect.value;
        const date = dateInput.value;
        if (!doctorClinicId || !date) return;

        timeSlotsDiv.innerHTML = '';
        slotsInfo.innerHTML = '<span class="spinner-border spinner-border-sm text-secondary me-1"></span> Yükleniyor...';

        fetch('get_available_slots.php?doctor_clinic_id=' + encodeURIComponent(doctorClinicId) + '&date=' + encodeURIComponent(date))
            .then(function (r) { return r.json(); })
            .then(function (data) {
                timeSlotsDiv.innerHTML = '';
                slotsInfo.innerHTML = '';

                if (!data.success) {
                    slotsInfo.textContent = data.message || 'Bir hata oluştu.';
                    return;
                }

                if (data.slots.length === 0) {
                    slotsInfo.innerHTML = '<i class="bi bi-calendar-x me-1"></i>' +
                        (data.message || 'Bu tarihte uygun randevu saati bulunmamaktadır.');
                    return;
                }

                data.slots.forEach(function (slot) {
                    const btn = document.createElement('button');
                    btn.type = 'button';
                    btn.className = 'slot-btn';
                    btn.textContent = slot.start_time;
                    btn.dataset.start = slot.start_time;
                    btn.dataset.end = slot.end_time;

                    btn.addEventListener('click', function () {
                        document.querySelectorAll('.slot-btn.selected').forEach(function (b) {
                            b.classList.remove('selected');
                        });
                        btn.classList.add('selected');
                        selectedSlot = { start_time: slot.start_time, end_time: slot.end_time };
                        patientSection.style.display = 'block';
                        resultMessage.textContent = '';
                        resultMessage.className = 'mt-3 fw-semibold';
                    });

                    timeSlotsDiv.appendChild(btn);
                });
            })
            .catch(function (err) {
                slotsInfo.textContent = 'Sunucuya ulaşılamadı: ' + err;
            });
    }

    dateInput.addEventListener('change', loadSlots);

    // -----------------------------------------------------------
    // ADIM: Randevu Oluştur -> create_appointment.php
    // -----------------------------------------------------------
    submitBtn.addEventListener('click', function () {
        if (!selectedSlot) {
            resultMessage.className = 'mt-3 fw-semibold text-danger';
            resultMessage.textContent = 'Lütfen bir saat seçin.';
            return;
        }

        const fullName = document.getElementById('full_name').value.trim();
        const nationalId = document.getElementById('national_id').value.trim();
        const phone = document.getElementById('phone').value.trim();

        if (!fullName || !nationalId || !phone) {
            resultMessage.className = 'mt-3 fw-semibold text-danger';
            resultMessage.textContent = 'Lütfen ad soyad, TC Kimlik No ve telefon bilgisini girin.';
            return;
        }

        if (!/^[1-9][0-9]{10}$/.test(nationalId)) {
            resultMessage.className = 'mt-3 fw-semibold text-danger';
            resultMessage.textContent = 'TC Kimlik No 11 haneli olmalı ve 0 ile başlamamalıdır.';
            return;
        }

        const formData = new FormData();
        formData.append('doctor_clinic_id', doctorSelect.value);
        formData.append('date', dateInput.value);
        formData.append('start_time', selectedSlot.start_time);
        formData.append('end_time', selectedSlot.end_time);
        formData.append('full_name', fullName);
        formData.append('national_id', nationalId);
        formData.append('phone', phone);

        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> Gönderiliyor...';
        resultMessage.className = 'mt-3 fw-semibold';
        resultMessage.textContent = '';

        fetch('create_appointment.php', { method: 'POST', body: formData })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="bi bi-calendar-check me-1"></i> Randevu Oluştur';

                if (data.success) {
                    resultMessage.className = 'mt-3 fw-semibold text-success';
                    resultMessage.innerHTML = '<i class="bi bi-check-circle-fill me-1"></i>' + data.message;
                    // Formu sıfırla, yeniden başlasın
                    document.getElementById('full_name').value = '';
                    document.getElementById('national_id').value = '';
                    document.getElementById('phone').value = '';
                    loadSlots(); // aynı günün güncel boş saatlerini tekrar çek
                } else {
                    resultMessage.className = 'mt-3 fw-semibold text-danger';
                    resultMessage.innerHTML = '<i class="bi bi-exclamation-triangle-fill me-1"></i>HATA: ' + data.message;
                }
            })
            .catch(function (err) {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="bi bi-calendar-check me-1"></i> Randevu Oluştur';
                resultMessage.className = 'mt-3 fw-semibold text-danger';
                resultMessage.textContent = 'Sunucuya ulaşılamadı: ' + err;
            });
    });
    </script>

</body>
</html>
