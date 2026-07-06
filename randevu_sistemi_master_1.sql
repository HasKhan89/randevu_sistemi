-- =====================================================================
-- RANDEVU_SISTEMI - MASTER KURULUM SCRIPTİ (tek dosya)
-- Bu dosya, önceki 3 ayrı dosyanın (full_setup + seed_data +
-- business_hours_setup) yerini alır. Baştan sona TEK SEFERDE çalıştırın.
--
-- Güvenle TEKRAR ÇALIŞTIRILABİLİR: mevcut tüm tablolar/trigger'lar
-- (business_hours dahil) temizlenip yeniden kurulur.
--
-- index.php ve business_hours.php dosyalarında HİÇBİR DEĞİŞİKLİK
-- GEREKMEZ; tablo/kolon adları birebir aynı korunmuştur.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS randevu_sistemi
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_turkish_ci;

USE randevu_sistemi;

SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- ESKİ TRIGGER VE TABLOLARI TEMİZLE (ters bağımlılık sırası)
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_appointments_no_overlap_insert;
DROP TRIGGER IF EXISTS trg_appointments_no_overlap_update;
DROP TRIGGER IF EXISTS trg_appointments_check_business_hours_insert;
DROP TRIGGER IF EXISTS trg_appointments_check_business_hours_update;
DROP TRIGGER IF EXISTS trg_appointments_before_insert;
DROP TRIGGER IF EXISTS trg_appointments_before_update;

DROP TABLE IF EXISTS business_hours;
DROP TABLE IF EXISTS appointment_status_logs;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS doctor_leaves;
DROP TABLE IF EXISTS doctor_availability;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS doctor_clinics;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS clinics;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS departments;


-- =====================================================================
-- 1) DEPARTMENTS
-- =====================================================================
CREATE TABLE departments (
    department_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(500) DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_departments_name UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 2) PATIENTS
-- =====================================================================
CREATE TABLE patients (
    patient_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    national_id         VARCHAR(20) NOT NULL,
    first_name          VARCHAR(80) NOT NULL,
    last_name           VARCHAR(80) NOT NULL,
    phone               VARCHAR(20) NOT NULL,
    email               VARCHAR(150) DEFAULT NULL,
    birth_date          DATE DEFAULT NULL,
    gender              ENUM('MALE','FEMALE','OTHER','UNSPECIFIED') NOT NULL DEFAULT 'UNSPECIFIED',
    address             VARCHAR(500) DEFAULT NULL,
    is_active           TINYINT(1) NOT NULL DEFAULT 1,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_patients_national_id UNIQUE (national_id),
    INDEX idx_patients_fullname (last_name, first_name),
    INDEX idx_patients_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 3) CLINICS
-- =====================================================================
CREATE TABLE clinics (
    clinic_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id   INT UNSIGNED NOT NULL,
    name            VARCHAR(150) NOT NULL,
    location        VARCHAR(255) DEFAULT NULL,
    phone           VARCHAR(20) DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_clinics_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_clinics_dept_name UNIQUE (department_id, name),
    INDEX idx_clinics_department_id (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 4) DOCTORS
-- =====================================================================
CREATE TABLE doctors (
    doctor_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(80) NOT NULL,
    last_name       VARCHAR(80) NOT NULL,
    title           VARCHAR(50) DEFAULT NULL,
    specialty       VARCHAR(150) DEFAULT NULL,
    email           VARCHAR(150) DEFAULT NULL,
    phone           VARCHAR(20) DEFAULT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_doctors_email UNIQUE (email),
    INDEX idx_doctors_fullname (last_name, first_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 5) DOCTOR_CLINICS (M:N)
-- =====================================================================
CREATE TABLE doctor_clinics (
    doctor_clinic_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_id        INT UNSIGNED NOT NULL,
    clinic_id        INT UNSIGNED NOT NULL,
    room_number      VARCHAR(20) DEFAULT NULL,
    is_primary       TINYINT(1) NOT NULL DEFAULT 0,
    is_active        TINYINT(1) NOT NULL DEFAULT 1,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_doctor_clinics_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_doctor_clinics_clinic FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_doctor_clinics_pair UNIQUE (doctor_id, clinic_id, room_number),
    INDEX idx_doctor_clinics_doctor_id (doctor_id),
    INDEX idx_doctor_clinics_clinic_id (clinic_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 6) SERVICES
-- =====================================================================
CREATE TABLE services (
    service_id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id             INT UNSIGNED DEFAULT NULL,
    name                      VARCHAR(150) NOT NULL,
    description               VARCHAR(500) DEFAULT NULL,
    default_duration_minutes  INT UNSIGNED NOT NULL DEFAULT 20,
    price                     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_active                 TINYINT(1) NOT NULL DEFAULT 1,
    created_at                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_services_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_services_department_id (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 7) DOCTOR_AVAILABILITY (şablon tablo; bu sürümde appointments artık
--    business_hours üzerinden doğrulandığı için availability_id her
--    randevuda NULL bırakılabilir - opsiyonel/gelecekteki kullanım içindir)
-- =====================================================================
CREATE TABLE doctor_availability (
    availability_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_clinic_id        INT UNSIGNED NOT NULL,
    day_of_week              ENUM('MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY') NOT NULL,
    start_time               TIME NOT NULL,
    end_time                 TIME NOT NULL,
    slot_duration_minutes    INT UNSIGNED NOT NULL DEFAULT 20,
    is_active                TINYINT(1) NOT NULL DEFAULT 1,
    created_at               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_availability_doctor_clinic FOREIGN KEY (doctor_clinic_id) REFERENCES doctor_clinics(doctor_clinic_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_availability_time_order CHECK (start_time < end_time),
    CONSTRAINT uq_availability_dc_day_start UNIQUE (doctor_clinic_id, day_of_week, start_time),
    INDEX idx_availability_doctor_clinic_id (doctor_clinic_id),
    INDEX idx_availability_day (day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 8) DOCTOR_LEAVES
-- =====================================================================
CREATE TABLE doctor_leaves (
    leave_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_id       INT UNSIGNED NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    leave_type      ENUM('ANNUAL_LEAVE','SICK_LEAVE','PUBLIC_HOLIDAY','CONGRESS_TRAINING','OTHER') NOT NULL DEFAULT 'OTHER',
    notes           VARCHAR(500) DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_leaves_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_leaves_date_order CHECK (start_date <= end_date),
    INDEX idx_leaves_doctor_id (doctor_id),
    INDEX idx_leaves_date_range (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 9) BUSINESS_HOURS  (Story 1.2 - Kabul Kriteri)
--    Bir gün için satır yoksa -> doktor o gün ÇALIŞMIYOR demektir.
-- =====================================================================
CREATE TABLE business_hours (
    business_hour_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_clinic_id        INT UNSIGNED NOT NULL,
    day_of_week              ENUM('MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY') NOT NULL,
    start_time               TIME NOT NULL,
    end_time                 TIME NOT NULL,
    break_start              TIME DEFAULT NULL,
    break_end                TIME DEFAULT NULL,
    slot_duration_minutes    INT UNSIGNED NOT NULL DEFAULT 20,
    is_active                TINYINT(1) NOT NULL DEFAULT 1,
    created_at               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_business_hours_doctor_clinic FOREIGN KEY (doctor_clinic_id) REFERENCES doctor_clinics(doctor_clinic_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_business_hours_time_order CHECK (start_time < end_time),
    CONSTRAINT chk_business_hours_break_order CHECK (
        (break_start IS NULL AND break_end IS NULL)
        OR (break_start < break_end AND break_start >= start_time AND break_end <= end_time)
    ),
    CONSTRAINT uq_business_hours_dc_day UNIQUE (doctor_clinic_id, day_of_week),
    INDEX idx_business_hours_doctor_clinic_id (doctor_clinic_id),
    INDEX idx_business_hours_day (day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 10) APPOINTMENTS
-- =====================================================================
CREATE TABLE appointments (
    appointment_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id           BIGINT UNSIGNED NOT NULL,
    doctor_id            INT UNSIGNED NOT NULL,
    clinic_id            INT UNSIGNED NOT NULL,
    service_id           INT UNSIGNED DEFAULT NULL,
    availability_id      INT UNSIGNED DEFAULT NULL,
    appointment_date     DATE NOT NULL,
    start_time           TIME NOT NULL,
    end_time             TIME NOT NULL,
    status               ENUM('SCHEDULED','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW') NOT NULL DEFAULT 'SCHEDULED',
    payment_status       ENUM('PENDING','PAID','INSURANCE_PENDING','WAIVED') NOT NULL DEFAULT 'PENDING',
    insurance_provider   VARCHAR(150) DEFAULT NULL,
    insurance_policy_no  VARCHAR(50) DEFAULT NULL,
    notes                VARCHAR(500) DEFAULT NULL,
    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_appointments_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_clinic FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_service FOREIGN KEY (service_id) REFERENCES services(service_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_appointments_availability FOREIGN KEY (availability_id) REFERENCES doctor_availability(availability_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_appointments_time_order CHECK (start_time < end_time),
    CONSTRAINT uq_appointments_doctor_date_start UNIQUE (doctor_id, appointment_date, start_time),
    INDEX idx_appointments_patient_id (patient_id),
    INDEX idx_appointments_doctor_id (doctor_id),
    INDEX idx_appointments_clinic_id (clinic_id),
    INDEX idx_appointments_date (appointment_date),
    INDEX idx_appointments_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

-- =====================================================================
-- 11) APPOINTMENT_STATUS_LOGS
-- =====================================================================
CREATE TABLE appointment_status_logs (
    log_id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    appointment_id    BIGINT UNSIGNED NOT NULL,
    previous_status   ENUM('SCHEDULED','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW') DEFAULT NULL,
    new_status        ENUM('SCHEDULED','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW') NOT NULL,
    reason            VARCHAR(500) DEFAULT NULL,
    changed_by        VARCHAR(150) DEFAULT NULL,
    changed_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_status_logs_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    INDEX idx_status_logs_appointment_id (appointment_id),
    INDEX idx_status_logs_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

SET FOREIGN_KEY_CHECKS = 1;


-- =====================================================================
-- TRIGGER'LAR (tek insert + tek update trigger'ı; hem çakışma hem
-- çalışma saati/mola kontrolünü birlikte yapar)
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_appointments_before_insert
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
    DECLARE v_doctor_clinic_id INT UNSIGNED;
    DECLARE v_day             VARCHAR(10);
    DECLARE v_bh_count        INT;
    DECLARE v_start           TIME;
    DECLARE v_end             TIME;
    DECLARE v_break_start     TIME;
    DECLARE v_break_end       TIME;
    DECLARE v_overlap_count   INT;

    -- 1) ÇAKIŞMA KONTROLÜ: aynı doktor, aynı tarih, kesişen saat aralığı
    SELECT COUNT(*) INTO v_overlap_count
    FROM appointments
    WHERE doctor_id = NEW.doctor_id
      AND appointment_date = NEW.appointment_date
      AND status <> 'CANCELLED'
      AND NEW.start_time < end_time
      AND NEW.end_time > start_time;

    IF v_overlap_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Çakışma: Bu doktor için seçilen saat aralığında mevcut bir randevu var.';
    END IF;

    -- 2) ÇALIŞMA SAATİ / MOLA KONTROLÜ (business_hours)
    SELECT doctor_clinic_id INTO v_doctor_clinic_id
    FROM doctor_clinics
    WHERE doctor_id = NEW.doctor_id AND clinic_id = NEW.clinic_id
    LIMIT 1;

    IF v_doctor_clinic_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bu doktor, seçilen klinikte görev yapmıyor.';
    END IF;

    SET v_day = UPPER(DAYNAME(NEW.appointment_date));

    SELECT COUNT(*) INTO v_bh_count
    FROM business_hours
    WHERE doctor_clinic_id = v_doctor_clinic_id AND day_of_week = v_day AND is_active = 1;

    IF v_bh_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doktor bu gün çalışmıyor, randevu oluşturulamaz.';
    END IF;

    SELECT start_time, end_time, break_start, break_end
        INTO v_start, v_end, v_break_start, v_break_end
    FROM business_hours
    WHERE doctor_clinic_id = v_doctor_clinic_id AND day_of_week = v_day AND is_active = 1
    LIMIT 1;

    IF NEW.start_time < v_start OR NEW.end_time > v_end THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Randevu saati doktorun çalışma saatleri dışında.';
    END IF;

    IF v_break_start IS NOT NULL AND v_break_end IS NOT NULL THEN
        IF NEW.start_time < v_break_end AND NEW.end_time > v_break_start THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Randevu saati mola (öğle arası) ile çakışıyor.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_appointments_before_update
BEFORE UPDATE ON appointments
FOR EACH ROW
BEGIN
    DECLARE v_doctor_clinic_id INT UNSIGNED;
    DECLARE v_day             VARCHAR(10);
    DECLARE v_bh_count        INT;
    DECLARE v_start           TIME;
    DECLARE v_end             TIME;
    DECLARE v_break_start     TIME;
    DECLARE v_break_end       TIME;
    DECLARE v_overlap_count   INT;

    IF NEW.status <> 'CANCELLED' THEN

        SELECT COUNT(*) INTO v_overlap_count
        FROM appointments
        WHERE doctor_id = NEW.doctor_id
          AND appointment_date = NEW.appointment_date
          AND status <> 'CANCELLED'
          AND appointment_id <> NEW.appointment_id
          AND NEW.start_time < end_time
          AND NEW.end_time > start_time;

        IF v_overlap_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Çakışma: Bu doktor için seçilen saat aralığında mevcut bir randevu var.';
        END IF;

        SELECT doctor_clinic_id INTO v_doctor_clinic_id
        FROM doctor_clinics
        WHERE doctor_id = NEW.doctor_id AND clinic_id = NEW.clinic_id
        LIMIT 1;

        IF v_doctor_clinic_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bu doktor, seçilen klinikte görev yapmıyor.';
        END IF;

        SET v_day = UPPER(DAYNAME(NEW.appointment_date));

        SELECT COUNT(*) INTO v_bh_count
        FROM business_hours
        WHERE doctor_clinic_id = v_doctor_clinic_id AND day_of_week = v_day AND is_active = 1;

        IF v_bh_count = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doktor bu gün çalışmıyor, randevu oluşturulamaz.';
        END IF;

        SELECT start_time, end_time, break_start, break_end
            INTO v_start, v_end, v_break_start, v_break_end
        FROM business_hours
        WHERE doctor_clinic_id = v_doctor_clinic_id AND day_of_week = v_day AND is_active = 1
        LIMIT 1;

        IF NEW.start_time < v_start OR NEW.end_time > v_end THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Randevu saati doktorun çalışma saatleri dışında.';
        END IF;

        IF v_break_start IS NOT NULL AND v_break_end IS NOT NULL THEN
            IF NEW.start_time < v_break_end AND NEW.end_time > v_break_start THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Randevu saati mola (öğle arası) ile çakışıyor.';
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;


-- =====================================================================
-- SEED VERİLERİ
-- =====================================================================

-- DEPARTMENTS (5)
INSERT INTO departments (name, description) VALUES
('Kardiyoloji', 'Kalp ve damar hastalıkları bölümü'),
('Nöroloji', 'Sinir sistemi hastalıkları bölümü'),
('Ortopedi', 'Kemik, eklem ve kas hastalıkları bölümü'),
('Göz Hastalıkları', 'Göz sağlığı ve hastalıkları bölümü'),
('Dahiliye', 'İç hastalıkları bölümü');

-- PATIENTS (10)
INSERT INTO patients (national_id, first_name, last_name, phone, email, birth_date, gender) VALUES
('10000000001', 'Ahmet', 'Yılmaz', '05321112233', 'ahmet.yilmaz@example.com', '1985-03-12', 'MALE'),
('10000000002', 'Ayşe', 'Kaya', '05331112244', 'ayse.kaya@example.com', '1990-07-25', 'FEMALE'),
('10000000003', 'Mehmet', 'Demir', '05341112255', 'mehmet.demir@example.com', '1978-11-02', 'MALE'),
('10000000004', 'Fatma', 'Çelik', '05351112266', 'fatma.celik@example.com', '1995-01-19', 'FEMALE'),
('10000000005', 'Mustafa', 'Şahin', '05361112277', 'mustafa.sahin@example.com', '1982-06-30', 'MALE'),
('10000000006', 'Zeynep', 'Yıldız', '05371112288', 'zeynep.yildiz@example.com', '1999-09-14', 'FEMALE'),
('10000000007', 'Ali', 'Aydın', '05381112299', 'ali.aydin@example.com', '1970-12-05', 'MALE'),
('10000000008', 'Elif', 'Öztürk', '05391112300', 'elif.ozturk@example.com', '1988-04-22', 'FEMALE'),
('10000000009', 'Hasan', 'Arslan', '05301112311', 'hasan.arslan@example.com', '1965-08-08', 'MALE'),
('10000000010', 'Merve', 'Koç', '05311112322', 'merve.koc@example.com', '1993-02-17', 'FEMALE');

-- CLINICS (6)
INSERT INTO clinics (department_id, name, location, phone) VALUES
(1, 'Kardiyoloji Polikliniği A', 'A Blok, Kat 2', '02123334455'),
(1, 'Kardiyoloji Polikliniği B', 'A Blok, Kat 3', '02123334456'),
(2, 'Nöroloji Polikliniği', 'B Blok, Kat 1', '02123334457'),
(3, 'Ortopedi Polikliniği', 'C Blok, Kat 1', '02123334458'),
(4, 'Göz Polikliniği', 'B Blok, Kat 2', '02123334459'),
(5, 'Dahiliye Polikliniği', 'A Blok, Kat 1', '02123334460');

-- DOCTORS (8)
INSERT INTO doctors (first_name, last_name, title, specialty, email, phone) VALUES
('Kemal', 'Aksoy', 'Prof. Dr.', 'Kardiyoloji', 'kemal.aksoy@hastane.com', '02129990001'),
('Sibel', 'Turan', 'Doç. Dr.', 'Kardiyoloji', 'sibel.turan@hastane.com', '02129990002'),
('Murat', 'Güneş', 'Op. Dr.', 'Nöroloji', 'murat.gunes@hastane.com', '02129990003'),
('Derya', 'Polat', 'Uzm. Dr.', 'Ortopedi', 'derya.polat@hastane.com', '02129990004'),
('Emre', 'Bulut', 'Uzm. Dr.', 'Ortopedi', 'emre.bulut@hastane.com', '02129990005'),
('Gül', 'Aktaş', 'Uzm. Dr.', 'Göz Hastalıkları', 'gul.aktas@hastane.com', '02129990006'),
('Serkan', 'Yavuz', 'Uzm. Dr.', 'Dahiliye', 'serkan.yavuz@hastane.com', '02129990007'),
('Burcu', 'Erdem', 'Uzm. Dr.', 'Dahiliye', 'burcu.erdem@hastane.com', '02129990008');

-- DOCTOR_CLINICS (9 - Burcu Erdem'in kliniği eksikliği düzeltildi)
-- Sıra: 1 Kemal Aksoy | 2-3 Sibel Turan | 4 Murat Güneş | 5 Derya Polat |
-- 6 Emre Bulut | 7 Gül Aktaş | 8 Serkan Yavuz | 9 Burcu Erdem
INSERT INTO doctor_clinics (doctor_id, clinic_id, room_number, is_primary) VALUES
(1, 1, '201', 1),
(2, 1, '202', 0),
(2, 2, '301', 1),
(3, 3, '101', 1),
(4, 4, '105', 1),
(5, 4, '106', 0),
(6, 5, '210', 1),
(7, 6, '110', 1),
(8, 6, '111', 0);

-- SERVICES (6)
INSERT INTO services (department_id, name, description, default_duration_minutes, price) VALUES
(NULL, 'Standart Muayene', 'Genel muayene hizmeti', 20, 350.00),
(NULL, 'Kontrol Muayenesi', 'Takip/kontrol muayenesi', 15, 200.00),
(1, 'EKG Çekimi', 'Elektrokardiyografi', 15, 250.00),
(2, 'MR Çekimi', 'Manyetik rezonans görüntüleme', 45, 1500.00),
(3, 'Kan Tahlili', 'Rutin kan tahlili paneli', 10, 300.00),
(3, 'Ameliyat Konsültasyonu', 'Ortopedik ameliyat öncesi görüşme', 30, 500.00);

-- BUSINESS_HOURS (doctor_clinic_id 1,3,4,5,6,7,8,9 için - dc2 hiç aktif çalışmıyor kabul edildi)
-- Sıra: 1 Kemal Aksoy(Pzt/Çrş) | 3 Sibel Turan(Sal/Prş) | 4 Murat Güneş(Sal) |
-- 5 Derya Polat(Pzt/Prş) | 6 Emre Bulut(Cuma) | 7 Gül Aktaş(Sal) |
-- 8 Serkan Yavuz(Çrş/Cuma) | 9 Burcu Erdem(Pzt/Prş)
INSERT INTO business_hours (doctor_clinic_id, day_of_week, start_time, end_time, break_start, break_end, slot_duration_minutes) VALUES
(1, 'MONDAY',    '09:00:00', '18:00:00', '12:00:00', '13:00:00', 20),
(1, 'WEDNESDAY', '09:00:00', '18:00:00', '12:00:00', '13:00:00', 20),
(3, 'TUESDAY',   '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20),
(3, 'THURSDAY',  '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20),
(4, 'TUESDAY',   '13:00:00', '18:00:00', NULL,       NULL,       20),
(5, 'MONDAY',    '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20),
(5, 'THURSDAY',  '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20),
(6, 'FRIDAY',    '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20),
(7, 'TUESDAY',   '09:00:00', '16:00:00', '12:00:00', '12:30:00', 20),
(8, 'WEDNESDAY', '13:00:00', '20:00:00', NULL,       NULL,       20),
(8, 'FRIDAY',    '13:00:00', '20:00:00', NULL,       NULL,       20),
(9, 'MONDAY',    '09:00:00', '15:00:00', '12:00:00', '12:30:00', 20),
(9, 'THURSDAY',  '09:00:00', '15:00:00', '12:00:00', '12:30:00', 20);

-- APPOINTMENTS (20)
-- Not: appointment_date'lerin gün adı (2026-07-06 = Pazartesi referans
-- alınarak) ilgili doktorun business_hours'ıyla birebir uyumlu seçildi;
-- availability_id kasıtlı olarak NULL (business_hours esas kaynak).
-- Sıra: 1-2 Kemal Aksoy(Pzt/Çrş) | 3 Kemal Aksoy NO_SHOW(Çrş) |
-- 4-5 Sibel Turan(Sal/Prş) | 6-8 Murat Güneş(Sal) |
-- 9-11 Derya Polat(Pzt/Prş) | 12-13 Emre Bulut(Cuma) |
-- 14-16 Gül Aktaş(Sal, 14 CANCELLED) | 17-19 Serkan Yavuz(Çrş) |
-- 20 Burcu Erdem(Pzt)
-- ÖNEMLİ: Bu bloğu bir SQL istemcisine yapıştırırken satır sonlarının
-- (line break) korunduğundan emin olun; "--" yorumları satır sonuna
-- kadar her şeyi yuttuğu için satır kırılması kaybolursa hata alırsınız.
INSERT INTO appointments
(patient_id, doctor_id, clinic_id, service_id, appointment_date, start_time, end_time, status, payment_status) VALUES
(1,  1, 1, 1, '2026-07-06', '09:00:00', '09:20:00', 'CONFIRMED', 'PAID'),
(2,  1, 1, 3, '2026-07-06', '09:20:00', '09:40:00', 'SCHEDULED', 'PENDING'),
(5,  1, 1, 1, '2026-07-08', '09:00:00', '09:20:00', 'NO_SHOW',   'PENDING'),
(3,  2, 2, 1, '2026-07-07', '10:00:00', '10:20:00', 'SCHEDULED', 'PENDING'),
(6,  2, 2, 1, '2026-07-09', '11:00:00', '11:20:00', 'SCHEDULED', 'PENDING'),
(4,  3, 3, 1, '2026-07-07', '13:00:00', '13:20:00', 'CONFIRMED', 'PAID'),
(5,  3, 3, 4, '2026-07-07', '13:20:00', '14:05:00', 'SCHEDULED', 'INSURANCE_PENDING'),
(6,  3, 3, 5, '2026-07-14', '15:00:00', '15:10:00', 'SCHEDULED', 'PENDING'),
(6,  4, 4, 1, '2026-07-06', '10:00:00', '10:20:00', 'COMPLETED', 'PAID'),
(7,  4, 4, 6, '2026-07-06', '10:20:00', '10:50:00', 'COMPLETED', 'PAID'),
(10, 4, 4, 6, '2026-07-16', '10:00:00', '10:30:00', 'SCHEDULED', 'PENDING'),
(7,  5, 4, 5, '2026-07-10', '11:00:00', '11:10:00', 'SCHEDULED', 'PENDING'),
(7,  5, 4, 1, '2026-07-17', '09:30:00', '09:50:00', 'SCHEDULED', 'PENDING'),
(9,  6, 5, 1, '2026-07-07', '09:00:00', '09:20:00', 'CANCELLED', 'WAIVED'),
(10, 6, 5, 2, '2026-07-07', '09:20:00', '09:35:00', 'SCHEDULED', 'PENDING'),
(8,  6, 5, 1, '2026-07-14', '09:40:00', '10:00:00', 'SCHEDULED', 'PENDING'),
(1,  7, 6, 1, '2026-07-08', '13:00:00', '13:20:00', 'CONFIRMED', 'PAID'),
(2,  7, 6, 2, '2026-07-08', '13:20:00', '13:35:00', 'SCHEDULED', 'PENDING'),
(9,  7, 6, 2, '2026-07-15', '13:20:00', '13:35:00', 'SCHEDULED', 'PENDING'),
(4,  8, 6, 1, '2026-07-06', '13:00:00', '13:20:00', 'SCHEDULED', 'PENDING');

-- APPOINTMENT_STATUS_LOGS (appointment_id'ler yukarıdaki sıraya göre)
INSERT INTO appointment_status_logs (appointment_id, previous_status, new_status, reason, changed_by) VALUES
(9,  'CONFIRMED', 'COMPLETED', 'Muayene tamamlandı', 'sistem'),
(10, 'CONFIRMED', 'COMPLETED', 'Muayene tamamlandı', 'sistem'),
(14, 'SCHEDULED', 'CANCELLED', 'Hasta iptal etti', 'çağrı merkezi'),
(3,  'CONFIRMED', 'NO_SHOW',   'Hasta randevuya gelmedi', 'sistem');

-- =====================================================================
-- KURULUM TAMAMLANDI. Kontrol için:
--   SHOW TABLES;
--   SHOW TRIGGERS;
--   SELECT COUNT(*) FROM appointments;
-- =====================================================================
