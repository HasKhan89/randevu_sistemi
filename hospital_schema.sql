-- =====================================================================
-- Story 1.1: İlişkisel Hastane Veritabanı Şemasının Oluşturulması
-- Açıklama: departments -> clinics -> doctors -> doctor_availability
--           hiyerarşisini ve appointments ilişkisini veri tutarlılığı
--           yüksek biçimde kuran MySQL şeması.
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- 1) DEPARTMENTS (Bölümler)
--    En üst seviye hiyerarşi: Kardiyoloji, Nöroloji, Ortopedi vb.
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
-- 2) CLINICS (Klinikler)
--    Her klinik tam olarak bir bölüme bağlıdır.
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
-- 3) DOCTORS (Doktorlar)
--    Her doktor tam olarak bir kliniğe bağlıdır.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doctors (
    doctor_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    clinic_id       INT UNSIGNED NOT NULL,
    first_name      VARCHAR(80) NOT NULL,
    last_name       VARCHAR(80) NOT NULL,
    title           VARCHAR(50) DEFAULT NULL,       -- Op. Dr., Prof. Dr. vb.
    specialty       VARCHAR(150) DEFAULT NULL,
    email           VARCHAR(150) DEFAULT NULL,
    phone           VARCHAR(20) DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_doctors_clinic
        FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_doctors_email UNIQUE (email),
    INDEX idx_doctors_clinic_id (clinic_id),
    INDEX idx_doctors_fullname (last_name, first_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 4) DOCTOR_AVAILABILITY (Doktor Müsaitlik Zamanları)
--    Bir doktorun haftalık tekrar eden müsaitlik aralıkları.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doctor_availability (
    availability_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_id       INT UNSIGNED NOT NULL,
    day_of_week     ENUM('MONDAY','TUESDAY','WEDNESDAY','THURSDAY',
                          'FRIDAY','SATURDAY','SUNDAY') NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    slot_duration_minutes INT UNSIGNED NOT NULL DEFAULT 20,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_availability_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_availability_time_order
        CHECK (start_time < end_time),

    CONSTRAINT uq_availability_doctor_day_start
        UNIQUE (doctor_id, day_of_week, start_time),

    INDEX idx_availability_doctor_id (doctor_id),
    INDEX idx_availability_day (day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;


-- ---------------------------------------------------------------------
-- 5) APPOINTMENTS (Randevular)
--    Bir doktora, isteğe bağlı olarak belirli bir müsaitlik aralığına
--    bağlı somut randevu kaydı.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_id            INT UNSIGNED NOT NULL,
    availability_id       INT UNSIGNED DEFAULT NULL,

    patient_full_name    VARCHAR(150) NOT NULL,
    patient_phone         VARCHAR(20) DEFAULT NULL,
    patient_national_id   VARCHAR(20) DEFAULT NULL,

    appointment_date      DATE NOT NULL,
    start_time            TIME NOT NULL,
    end_time               TIME NOT NULL,

    status                 ENUM('SCHEDULED','CONFIRMED','CANCELLED',
                                 'COMPLETED','NO_SHOW')
                                 NOT NULL DEFAULT 'SCHEDULED',
    notes                  VARCHAR(500) DEFAULT NULL,

    created_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_appointments_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointments_availability
        FOREIGN KEY (availability_id) REFERENCES doctor_availability(availability_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_appointments_time_order
        CHECK (start_time < end_time),

    -- Aynı doktor için aynı tarih+saatte çakışan randevu girilmesini engeller
    CONSTRAINT uq_appointments_doctor_date_start
        UNIQUE (doctor_id, appointment_date, start_time),

    INDEX idx_appointments_doctor_id (doctor_id),
    INDEX idx_appointments_date (appointment_date),
    INDEX idx_appointments_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- Hiyerarşi özeti:
--   departments (1) --< clinics (1) --< doctors (1) --< doctor_availability
--   doctors (1) --< appointments  (>-- doctor_availability, opsiyonel)
--
-- Notlar:
--  - ON DELETE RESTRICT: departments/clinics/doctors/appointments üzerinde
--    bağımlı kayıt varken üst kayıt silinemez (veri tutarlılığı için).
--  - ON DELETE CASCADE: bir doktor silinirse müsaitlik kayıtları da silinir.
--  - CHECK kısıtları (MySQL 8.0.16+ gerektirir) start_time < end_time
--    kuralını veritabanı seviyesinde garanti eder.
--  - UNIQUE kısıtlar aynı doktor için çakışan randevu/müsaitlik girişini
--    veritabanı seviyesinde engeller.
-- =====================================================================
