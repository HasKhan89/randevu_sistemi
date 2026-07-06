-- =====================================================================
-- Story 1.1 (Rev. 2): 3NF Uyumlu İlişkisel Hastane Veritabanı Şeması
-- Değişiklik özeti (önceki şemaya göre):
--   1) patients tablosu eklendi -> appointments'taki geçişli bağımlılık
--      (patient_full_name/phone/national_id) giderildi (3NF).
--   2) doctors.clinic_id kaldırıldı -> doctor_clinics (M:N + oda) eklendi.
--   3) services (randevu tipi/işlem) tablosu eklendi.
--   4) doctor_leaves (izin/tatil/istisna) tablosu eklendi.
--   5) appointment_status_logs (iptal/erteleme audit trail) eklendi.
--   6) appointments'a temel ödeme/sigorta alanları eklendi.
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- 1) PATIENTS (Hastalar)
--    Hasta verisi artık tek bir yerden yönetiliyor (3NF).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patients (
    patient_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    national_id         VARCHAR(20) NOT NULL,      -- TC Kimlik No
    first_name          VARCHAR(80) NOT NULL,
    last_name           VARCHAR(80) NOT NULL,
    phone               VARCHAR(20) NOT NULL,
    email               VARCHAR(150) DEFAULT NULL,
    birth_date          DATE DEFAULT NULL,
    gender              ENUM('MALE','FEMALE','OTHER','UNSPECIFIED')
                            NOT NULL DEFAULT 'UNSPECIFIED',
    address             VARCHAR(500) DEFAULT NULL,
    is_active           TINYINT(1) NOT NULL DEFAULT 1,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_patients_national_id UNIQUE (national_id),
    INDEX idx_patients_fullname (last_name, first_name),
    INDEX idx_patients_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 2) DEPARTMENTS (Bölümler)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS departments (
    department_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(500) DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_departments_name UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 3) CLINICS (Klinikler / Poliklinikler)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clinics (
    clinic_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id   INT UNSIGNED NOT NULL,
    name            VARCHAR(150) NOT NULL,
    location        VARCHAR(255) DEFAULT NULL,
    phone           VARCHAR(20) DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_clinics_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_clinics_dept_name UNIQUE (department_id, name),
    INDEX idx_clinics_department_id (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 4) DOCTORS (Doktorlar)
--    Artık tek bir clinic_id'ye sabitlenmiyor; ilişki doctor_clinics
--    junction tablosu üzerinden M:N kuruluyor.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doctors (
    doctor_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(80) NOT NULL,
    last_name       VARCHAR(80) NOT NULL,
    title           VARCHAR(50) DEFAULT NULL,
    specialty       VARCHAR(150) DEFAULT NULL,
    email           VARCHAR(150) DEFAULT NULL,
    phone           VARCHAR(20) DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_doctors_email UNIQUE (email),
    INDEX idx_doctors_fullname (last_name, first_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 5) DOCTOR_CLINICS (Doktor <-> Klinik/Poliklinik/Oda ilişkisi, M:N)
--    Bir doktor birden fazla klinikte, farklı odalarda çalışabilir.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doctor_clinics (
    doctor_clinic_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_id        INT UNSIGNED NOT NULL,
    clinic_id        INT UNSIGNED NOT NULL,
    room_number      VARCHAR(20) DEFAULT NULL,
    is_primary       TINYINT(1) NOT NULL DEFAULT 0,
    is_active        TINYINT(1) NOT NULL DEFAULT 1,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_doctor_clinics_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_doctor_clinics_clinic
        FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_doctor_clinics_pair UNIQUE (doctor_id, clinic_id, room_number),
    INDEX idx_doctor_clinics_doctor_id (doctor_id),
    INDEX idx_doctor_clinics_clinic_id (clinic_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 6) SERVICES (Randevu Türleri / Hizmetler / İşlemler)
--    Standart muayene, kontrol, kan tahlili, MR, ameliyat vb.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS services (
    service_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id       INT UNSIGNED DEFAULT NULL,   -- NULL: genel/departmandan bağımsız hizmet
    name                VARCHAR(150) NOT NULL,
    description         VARCHAR(500) DEFAULT NULL,
    default_duration_minutes INT UNSIGNED NOT NULL DEFAULT 20,
    price               DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_active           TINYINT(1) NOT NULL DEFAULT 1,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_services_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    INDEX idx_services_department_id (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 7) DOCTOR_AVAILABILITY (Doktor Müsaitlik Şablonları)
--    Artık doctor_clinics üzerinden hangi klinik/odada geçerli olduğu
--    da belli oluyor.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doctor_availability (
    availability_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_clinic_id     INT UNSIGNED NOT NULL,
    day_of_week          ENUM('MONDAY','TUESDAY','WEDNESDAY','THURSDAY',
                               'FRIDAY','SATURDAY','SUNDAY') NOT NULL,
    start_time           TIME NOT NULL,
    end_time             TIME NOT NULL,
    slot_duration_minutes INT UNSIGNED NOT NULL DEFAULT 20,
    is_active            TINYINT(1) NOT NULL DEFAULT 1,
    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                             ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_availability_doctor_clinic
        FOREIGN KEY (doctor_clinic_id) REFERENCES doctor_clinics(doctor_clinic_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_availability_time_order
        CHECK (start_time < end_time),

    CONSTRAINT uq_availability_dc_day_start
        UNIQUE (doctor_clinic_id, day_of_week, start_time),

    INDEX idx_availability_doctor_clinic_id (doctor_clinic_id),
    INDEX idx_availability_day (day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 8) DOCTOR_LEAVES (İzin / Rapor / Resmi Tatil İstisnaları)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doctor_leaves (
    leave_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_id       INT UNSIGNED NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    leave_type      ENUM('ANNUAL_LEAVE','SICK_LEAVE','PUBLIC_HOLIDAY',
                          'CONGRESS_TRAINING','OTHER') NOT NULL DEFAULT 'OTHER',
    notes           VARCHAR(500) DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_leaves_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_leaves_date_order
        CHECK (start_date <= end_date),

    INDEX idx_leaves_doctor_id (doctor_id),
    INDEX idx_leaves_date_range (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 9) APPOINTMENTS (Randevular)
--    patient_id ile 3NF sağlanıyor. doctor_id KASITLI olarak korundu:
--    her randevu mutlaka önceden tanımlı bir availability şablonundan
--    gelmeyebilir (acil/walk-in randevular). Bu nedenle availability_id
--    NULL olabilir; böyle durumlarda doctor_id tek referans kaynağıdır.
--    Bu yüzden bu alan artık "kazara redundancy" değil, iş kuralı
--    gereği bilinçli bir tasarım tercihidir.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id           BIGINT UNSIGNED NOT NULL,
    doctor_id            INT UNSIGNED NOT NULL,
    clinic_id            INT UNSIGNED NOT NULL,
    service_id           INT UNSIGNED DEFAULT NULL,
    availability_id      INT UNSIGNED DEFAULT NULL,  -- NULL: şablon dışı/acil randevu

    appointment_date     DATE NOT NULL,
    start_time           TIME NOT NULL,
    end_time             TIME NOT NULL,

    status               ENUM('SCHEDULED','CONFIRMED','CANCELLED',
                               'COMPLETED','NO_SHOW')
                               NOT NULL DEFAULT 'SCHEDULED',

    payment_status       ENUM('PENDING','PAID','INSURANCE_PENDING','WAIVED')
                               NOT NULL DEFAULT 'PENDING',
    insurance_provider   VARCHAR(150) DEFAULT NULL,   -- SGK, Özel Sigorta vb.
    insurance_policy_no  VARCHAR(50) DEFAULT NULL,

    notes                VARCHAR(500) DEFAULT NULL,
    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                             ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointments_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointments_clinic
        FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointments_service
        FOREIGN KEY (service_id) REFERENCES services(service_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_appointments_availability
        FOREIGN KEY (availability_id) REFERENCES doctor_availability(availability_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_appointments_time_order
        CHECK (start_time < end_time),

    -- Aynı doktor için aynı tarih+saatte çakışan randevu girişini engeller
    CONSTRAINT uq_appointments_doctor_date_start
        UNIQUE (doctor_id, appointment_date, start_time),

    INDEX idx_appointments_patient_id (patient_id),
    INDEX idx_appointments_doctor_id (doctor_id),
    INDEX idx_appointments_clinic_id (clinic_id),
    INDEX idx_appointments_date (appointment_date),
    INDEX idx_appointments_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 10) APPOINTMENT_STATUS_LOGS (İptal / Erteleme / Durum Değişikliği Logu)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS appointment_status_logs (
    log_id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    appointment_id    BIGINT UNSIGNED NOT NULL,
    previous_status   ENUM('SCHEDULED','CONFIRMED','CANCELLED',
                            'COMPLETED','NO_SHOW') DEFAULT NULL,
    new_status        ENUM('SCHEDULED','CONFIRMED','CANCELLED',
                            'COMPLETED','NO_SHOW') NOT NULL,
    reason            VARCHAR(500) DEFAULT NULL,
    changed_by        VARCHAR(150) DEFAULT NULL,  -- kullanıcı/personel adı ya da id (users tablosu eklenince FK'ya çevrilebilir)
    changed_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_status_logs_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    INDEX idx_status_logs_appointment_id (appointment_id),
    INDEX idx_status_logs_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- Hiyerarşi özeti:
--   departments (1)--<clinics (1)--<doctor_clinics>--(1) doctors
--   doctor_clinics (1)--<doctor_availability
--   patients (1)--<appointments>--(1) doctors, clinics, services,
--                                    doctor_availability (opsiyonel)
--   appointments (1)--<appointment_status_logs
--   doctors (1)--<doctor_leaves
--
-- 3NF kontrolü:
--   - Her tablo bir varlığı temsil ediyor; non-key sütunlar sadece kendi
--     primary key'ine bağlı (transitive dependency yok).
--   - Hasta bilgisi tek bir yerde (patients) tutuluyor; appointments
--     sadece patient_id referansı taşıyor -> güncelleme anormalliği
--     ortadan kalktı.
--
-- Bilinçli olarak "denormalize" bırakılan noktalar (iş kuralı gereği):
--   - appointments.doctor_id + clinic_id: availability_id NULL
--     olabileceği (walk-in/acil randevu) için korunuyor.
-- =====================================================================
