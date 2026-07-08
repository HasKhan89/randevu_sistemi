-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 08, 2026 at 04:48 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `randevu_sistemi`
--

-- --------------------------------------------------------

--
-- Table structure for table `appointments`
--

CREATE TABLE `appointments` (
  `appointment_id` bigint(20) UNSIGNED NOT NULL,
  `patient_id` bigint(20) UNSIGNED NOT NULL,
  `doctor_id` int(10) UNSIGNED NOT NULL,
  `clinic_id` int(10) UNSIGNED NOT NULL,
  `service_id` int(10) UNSIGNED DEFAULT NULL,
  `availability_id` int(10) UNSIGNED DEFAULT NULL,
  `appointment_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `status` enum('SCHEDULED','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW') NOT NULL DEFAULT 'SCHEDULED',
  `payment_status` enum('PENDING','PAID','INSURANCE_PENDING','WAIVED') NOT NULL DEFAULT 'PENDING',
  `insurance_provider` varchar(150) DEFAULT NULL,
  `insurance_policy_no` varchar(50) DEFAULT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

--
-- Dumping data for table `appointments`
--

INSERT INTO `appointments` (`appointment_id`, `patient_id`, `doctor_id`, `clinic_id`, `service_id`, `availability_id`, `appointment_date`, `start_time`, `end_time`, `status`, `payment_status`, `insurance_provider`, `insurance_policy_no`, `notes`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 1, NULL, '2026-07-06', '09:00:00', '09:20:00', 'CONFIRMED', 'PAID', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(2, 2, 1, 1, 3, NULL, '2026-07-06', '09:20:00', '09:40:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(3, 5, 1, 1, 1, NULL, '2026-07-08', '09:00:00', '09:20:00', 'NO_SHOW', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(4, 3, 2, 2, 1, NULL, '2026-07-07', '10:00:00', '10:20:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(5, 6, 2, 2, 1, NULL, '2026-07-09', '11:00:00', '11:20:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(6, 4, 3, 3, 1, NULL, '2026-07-07', '13:00:00', '13:20:00', 'CONFIRMED', 'PAID', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(7, 5, 3, 3, 4, NULL, '2026-07-07', '13:20:00', '14:05:00', 'SCHEDULED', 'INSURANCE_PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(8, 6, 3, 3, 5, NULL, '2026-07-14', '15:00:00', '15:10:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(9, 6, 4, 4, 1, NULL, '2026-07-06', '10:00:00', '10:20:00', 'COMPLETED', 'PAID', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(10, 7, 4, 4, 6, NULL, '2026-07-06', '10:20:00', '10:50:00', 'COMPLETED', 'PAID', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(11, 10, 4, 4, 6, NULL, '2026-07-16', '10:00:00', '10:30:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(12, 7, 5, 4, 5, NULL, '2026-07-10', '11:00:00', '11:10:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(13, 7, 5, 4, 1, NULL, '2026-07-17', '09:30:00', '09:50:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(14, 9, 6, 5, 1, NULL, '2026-07-07', '09:00:00', '09:20:00', 'CANCELLED', 'WAIVED', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(15, 10, 6, 5, 2, NULL, '2026-07-07', '09:20:00', '09:35:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(16, 8, 6, 5, 1, NULL, '2026-07-14', '09:40:00', '10:00:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(17, 1, 7, 6, 1, NULL, '2026-07-08', '13:00:00', '13:20:00', 'CONFIRMED', 'PAID', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(18, 2, 7, 6, 2, NULL, '2026-07-08', '13:20:00', '13:35:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(19, 9, 7, 6, 2, NULL, '2026-07-15', '13:20:00', '13:35:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(20, 4, 8, 6, 1, NULL, '2026-07-06', '13:00:00', '13:20:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(21, 11, 6, 5, NULL, NULL, '2026-07-14', '11:00:00', '11:20:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-08 12:34:12', '2026-07-08 12:34:12'),
(22, 12, 8, 6, NULL, NULL, '2026-07-13', '10:00:00', '10:20:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-08 12:53:32', '2026-07-08 12:53:32'),
(23, 17, 5, 4, NULL, NULL, '2026-07-10', '14:00:00', '14:20:00', 'SCHEDULED', 'PENDING', NULL, NULL, NULL, '2026-07-08 13:14:54', '2026-07-08 13:14:54');

--
-- Triggers `appointments`
--
DELIMITER $$
CREATE TRIGGER `trg_appointments_before_insert` BEFORE INSERT ON `appointments` FOR EACH ROW BEGIN
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
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_appointments_before_update` BEFORE UPDATE ON `appointments` FOR EACH ROW BEGIN
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `appointment_status_logs`
--

CREATE TABLE `appointment_status_logs` (
  `log_id` bigint(20) UNSIGNED NOT NULL,
  `appointment_id` bigint(20) UNSIGNED NOT NULL,
  `previous_status` enum('SCHEDULED','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW') DEFAULT NULL,
  `new_status` enum('SCHEDULED','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW') NOT NULL,
  `reason` varchar(500) DEFAULT NULL,
  `changed_by` varchar(150) DEFAULT NULL,
  `changed_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

--
-- Dumping data for table `appointment_status_logs`
--

INSERT INTO `appointment_status_logs` (`log_id`, `appointment_id`, `previous_status`, `new_status`, `reason`, `changed_by`, `changed_at`) VALUES
(1, 9, 'CONFIRMED', 'COMPLETED', 'Muayene tamamlandı', 'sistem', '2026-07-06 16:28:41'),
(2, 10, 'CONFIRMED', 'COMPLETED', 'Muayene tamamlandı', 'sistem', '2026-07-06 16:28:41'),
(3, 14, 'SCHEDULED', 'CANCELLED', 'Hasta iptal etti', 'çağrı merkezi', '2026-07-06 16:28:41'),
(4, 3, 'CONFIRMED', 'NO_SHOW', 'Hasta randevuya gelmedi', 'sistem', '2026-07-06 16:28:41');

-- --------------------------------------------------------

--
-- Table structure for table `business_hours`
--

CREATE TABLE `business_hours` (
  `business_hour_id` int(10) UNSIGNED NOT NULL,
  `doctor_clinic_id` int(10) UNSIGNED NOT NULL,
  `day_of_week` enum('MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY') NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `break_start` time DEFAULT NULL,
  `break_end` time DEFAULT NULL,
  `slot_duration_minutes` int(10) UNSIGNED NOT NULL DEFAULT 20,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

--
-- Dumping data for table `business_hours`
--

INSERT INTO `business_hours` (`business_hour_id`, `doctor_clinic_id`, `day_of_week`, `start_time`, `end_time`, `break_start`, `break_end`, `slot_duration_minutes`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 'MONDAY', '09:00:00', '18:00:00', '12:00:00', '13:00:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(2, 1, 'WEDNESDAY', '09:00:00', '18:00:00', '12:00:00', '13:00:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(3, 3, 'TUESDAY', '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(4, 3, 'THURSDAY', '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(5, 4, 'TUESDAY', '13:00:00', '18:00:00', NULL, NULL, 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(6, 5, 'MONDAY', '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(7, 5, 'THURSDAY', '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(8, 6, 'FRIDAY', '09:00:00', '17:00:00', '12:00:00', '13:00:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(9, 7, 'TUESDAY', '09:00:00', '16:00:00', '12:00:00', '12:30:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(10, 8, 'WEDNESDAY', '13:00:00', '20:00:00', NULL, NULL, 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(11, 8, 'FRIDAY', '13:00:00', '20:00:00', NULL, NULL, 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(12, 9, 'MONDAY', '09:00:00', '15:00:00', '12:00:00', '12:30:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(13, 9, 'THURSDAY', '09:00:00', '15:00:00', '12:00:00', '12:30:00', 20, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(14, 9, 'WEDNESDAY', '09:00:00', '18:00:00', '12:00:00', '13:00:00', 20, 1, '2026-07-08 12:09:48', '2026-07-08 12:09:48'),
(15, 4, 'THURSDAY', '09:00:00', '18:30:00', NULL, NULL, 20, 1, '2026-07-08 12:32:32', '2026-07-08 12:32:32');

-- --------------------------------------------------------

--
-- Table structure for table `clinics`
--

CREATE TABLE `clinics` (
  `clinic_id` int(10) UNSIGNED NOT NULL,
  `department_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

--
-- Dumping data for table `clinics`
--

INSERT INTO `clinics` (`clinic_id`, `department_id`, `name`, `location`, `phone`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 'Kardiyoloji Polikliniği A', 'A Blok, Kat 2', '02123334455', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(2, 1, 'Kardiyoloji Polikliniği B', 'A Blok, Kat 3', '02123334456', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(3, 2, 'Nöroloji Polikliniği', 'B Blok, Kat 1', '02123334457', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(4, 3, 'Ortopedi Polikliniği', 'C Blok, Kat 1', '02123334458', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(5, 4, 'Göz Polikliniği', 'B Blok, Kat 2', '02123334459', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(6, 5, 'Dahiliye Polikliniği', 'A Blok, Kat 1', '02123334460', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41');

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `department_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`department_id`, `name`, `description`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Kardiyoloji', 'Kalp ve damar hastalıkları bölümü', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(2, 'Nöroloji', 'Sinir sistemi hastalıkları bölümü', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(3, 'Ortopedi', 'Kemik, eklem ve kas hastalıkları bölümü', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(4, 'Göz Hastalıkları', 'Göz sağlığı ve hastalıkları bölümü', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(5, 'Dahiliye', 'İç hastalıkları bölümü', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41');

-- --------------------------------------------------------

--
-- Table structure for table `doctors`
--

CREATE TABLE `doctors` (
  `doctor_id` int(10) UNSIGNED NOT NULL,
  `first_name` varchar(80) NOT NULL,
  `last_name` varchar(80) NOT NULL,
  `title` varchar(50) DEFAULT NULL,
  `specialty` varchar(150) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

--
-- Dumping data for table `doctors`
--

INSERT INTO `doctors` (`doctor_id`, `first_name`, `last_name`, `title`, `specialty`, `email`, `phone`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Kemal', 'Aksoy', 'Prof. Dr.', 'Kardiyoloji', 'kemal.aksoy@hastane.com', '02129990001', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(2, 'Sibel', 'Turan', 'Doç. Dr.', 'Kardiyoloji', 'sibel.turan@hastane.com', '02129990002', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(3, 'Murat', 'Güneş', 'Op. Dr.', 'Nöroloji', 'murat.gunes@hastane.com', '02129990003', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(4, 'Derya', 'Polat', 'Uzm. Dr.', 'Ortopedi', 'derya.polat@hastane.com', '02129990004', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(5, 'Emre', 'Bulut', 'Uzm. Dr.', 'Ortopedi', 'emre.bulut@hastane.com', '02129990005', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(6, 'Gül', 'Aktaş', 'Uzm. Dr.', 'Göz Hastalıkları', 'gul.aktas@hastane.com', '02129990006', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(7, 'Serkan', 'Yavuz', 'Uzm. Dr.', 'Dahiliye', 'serkan.yavuz@hastane.com', '02129990007', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(8, 'Burcu', 'Erdem', 'Uzm. Dr.', 'Dahiliye', 'burcu.erdem@hastane.com', '02129990008', 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41');

-- --------------------------------------------------------

--
-- Table structure for table `doctor_availability`
--

CREATE TABLE `doctor_availability` (
  `availability_id` int(10) UNSIGNED NOT NULL,
  `doctor_clinic_id` int(10) UNSIGNED NOT NULL,
  `day_of_week` enum('MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY') NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `slot_duration_minutes` int(10) UNSIGNED NOT NULL DEFAULT 20,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `doctor_clinics`
--

CREATE TABLE `doctor_clinics` (
  `doctor_clinic_id` int(10) UNSIGNED NOT NULL,
  `doctor_id` int(10) UNSIGNED NOT NULL,
  `clinic_id` int(10) UNSIGNED NOT NULL,
  `room_number` varchar(20) DEFAULT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

--
-- Dumping data for table `doctor_clinics`
--

INSERT INTO `doctor_clinics` (`doctor_clinic_id`, `doctor_id`, `clinic_id`, `room_number`, `is_primary`, `is_active`, `created_at`) VALUES
(1, 1, 1, '201', 1, 1, '2026-07-06 16:28:41'),
(2, 2, 1, '202', 0, 1, '2026-07-06 16:28:41'),
(3, 2, 2, '301', 1, 1, '2026-07-06 16:28:41'),
(4, 3, 3, '101', 1, 1, '2026-07-06 16:28:41'),
(5, 4, 4, '105', 1, 1, '2026-07-06 16:28:41'),
(6, 5, 4, '106', 0, 1, '2026-07-06 16:28:41'),
(7, 6, 5, '210', 1, 1, '2026-07-06 16:28:41'),
(8, 7, 6, '110', 1, 1, '2026-07-06 16:28:41'),
(9, 8, 6, '111', 0, 1, '2026-07-06 16:28:41');

-- --------------------------------------------------------

--
-- Table structure for table `doctor_leaves`
--

CREATE TABLE `doctor_leaves` (
  `leave_id` int(10) UNSIGNED NOT NULL,
  `doctor_id` int(10) UNSIGNED NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `leave_type` enum('ANNUAL_LEAVE','SICK_LEAVE','PUBLIC_HOLIDAY','CONGRESS_TRAINING','OTHER') NOT NULL DEFAULT 'OTHER',
  `notes` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `patients`
--

CREATE TABLE `patients` (
  `patient_id` bigint(20) UNSIGNED NOT NULL,
  `national_id` varchar(11) DEFAULT NULL,
  `first_name` varchar(80) NOT NULL,
  `last_name` varchar(80) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `email` varchar(150) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `gender` enum('MALE','FEMALE','OTHER','UNSPECIFIED') NOT NULL DEFAULT 'UNSPECIFIED',
  `address` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

--
-- Dumping data for table `patients`
--

INSERT INTO `patients` (`patient_id`, `national_id`, `first_name`, `last_name`, `phone`, `email`, `birth_date`, `gender`, `address`, `is_active`, `created_at`, `updated_at`) VALUES
(1, '10000000001', 'Ahmet', 'Yılmaz', '05321112233', 'ahmet.yilmaz@example.com', '1985-03-12', 'MALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(2, '10000000002', 'Ayşe', 'Kaya', '05331112244', 'ayse.kaya@example.com', '1990-07-25', 'FEMALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(3, '10000000003', 'Mehmet', 'Demir', '05341112255', 'mehmet.demir@example.com', '1978-11-02', 'MALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(4, '10000000004', 'Fatma', 'Çelik', '05351112266', 'fatma.celik@example.com', '1995-01-19', 'FEMALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(5, '10000000005', 'Mustafa', 'Şahin', '05361112277', 'mustafa.sahin@example.com', '1982-06-30', 'MALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(6, '10000000006', 'Zeynep', 'Yıldız', '05371112288', 'zeynep.yildiz@example.com', '1999-09-14', 'FEMALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(7, '10000000007', 'Ali', 'Aydın', '05381112299', 'ali.aydin@example.com', '1970-12-05', 'MALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(8, '10000000008', 'Elif', 'Öztürk', '05391112300', 'elif.ozturk@example.com', '1988-04-22', 'FEMALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(9, '10000000009', 'Hasan', 'Arslan', '05301112311', 'hasan.arslan@example.com', '1965-08-08', 'MALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(10, '10000000010', 'Merve', 'Koç', '05311112322', 'merve.koc@example.com', '1993-02-17', 'FEMALE', NULL, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(11, '10000000382', 'Hasan', 'Kahraman', '05071234567', 'hasan.kahraman@example.com', '1988-03-15', 'MALE', NULL, 1, '2026-07-08 12:05:12', '2026-07-08 13:22:33'),
(12, '10000000450', 'Sevcan', 'Kahraman', '05381234567', 'sevcan.kahraman@example.com', '1992-09-08', 'FEMALE', NULL, 1, '2026-07-08 12:53:32', '2026-07-08 13:22:33'),
(17, '10000000146', 'Rıdvan', 'Kahraman', '05061234567', 'ridvan.kahraman@example.com', '1990-05-20', 'MALE', NULL, 1, '2026-07-08 13:14:54', '2026-07-08 13:22:33');

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `service_id` int(10) UNSIGNED NOT NULL,
  `department_id` int(10) UNSIGNED DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `default_duration_minutes` int(10) UNSIGNED NOT NULL DEFAULT 20,
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_turkish_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`service_id`, `department_id`, `name`, `description`, `default_duration_minutes`, `price`, `is_active`, `created_at`, `updated_at`) VALUES
(1, NULL, 'Standart Muayene', 'Genel muayene hizmeti', 20, 350.00, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(2, NULL, 'Kontrol Muayenesi', 'Takip/kontrol muayenesi', 15, 200.00, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(3, 1, 'EKG Çekimi', 'Elektrokardiyografi', 15, 250.00, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(4, 2, 'MR Çekimi', 'Manyetik rezonans görüntüleme', 45, 1500.00, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(5, 3, 'Kan Tahlili', 'Rutin kan tahlili paneli', 10, 300.00, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41'),
(6, 3, 'Ameliyat Konsültasyonu', 'Ortopedik ameliyat öncesi görüşme', 30, 500.00, 1, '2026-07-06 16:28:41', '2026-07-06 16:28:41');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `appointments`
--
ALTER TABLE `appointments`
  ADD PRIMARY KEY (`appointment_id`),
  ADD UNIQUE KEY `uq_appointments_doctor_date_start` (`doctor_id`,`appointment_date`,`start_time`),
  ADD KEY `fk_appointments_service` (`service_id`),
  ADD KEY `fk_appointments_availability` (`availability_id`),
  ADD KEY `idx_appointments_patient_id` (`patient_id`),
  ADD KEY `idx_appointments_doctor_id` (`doctor_id`),
  ADD KEY `idx_appointments_clinic_id` (`clinic_id`),
  ADD KEY `idx_appointments_date` (`appointment_date`),
  ADD KEY `idx_appointments_status` (`status`);

--
-- Indexes for table `appointment_status_logs`
--
ALTER TABLE `appointment_status_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_status_logs_appointment_id` (`appointment_id`),
  ADD KEY `idx_status_logs_changed_at` (`changed_at`);

--
-- Indexes for table `business_hours`
--
ALTER TABLE `business_hours`
  ADD PRIMARY KEY (`business_hour_id`),
  ADD UNIQUE KEY `uq_business_hours_dc_day` (`doctor_clinic_id`,`day_of_week`),
  ADD KEY `idx_business_hours_doctor_clinic_id` (`doctor_clinic_id`),
  ADD KEY `idx_business_hours_day` (`day_of_week`);

--
-- Indexes for table `clinics`
--
ALTER TABLE `clinics`
  ADD PRIMARY KEY (`clinic_id`),
  ADD UNIQUE KEY `uq_clinics_dept_name` (`department_id`,`name`),
  ADD KEY `idx_clinics_department_id` (`department_id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`department_id`),
  ADD UNIQUE KEY `uq_departments_name` (`name`);

--
-- Indexes for table `doctors`
--
ALTER TABLE `doctors`
  ADD PRIMARY KEY (`doctor_id`),
  ADD UNIQUE KEY `uq_doctors_email` (`email`),
  ADD KEY `idx_doctors_fullname` (`last_name`,`first_name`);

--
-- Indexes for table `doctor_availability`
--
ALTER TABLE `doctor_availability`
  ADD PRIMARY KEY (`availability_id`),
  ADD UNIQUE KEY `uq_availability_dc_day_start` (`doctor_clinic_id`,`day_of_week`,`start_time`),
  ADD KEY `idx_availability_doctor_clinic_id` (`doctor_clinic_id`),
  ADD KEY `idx_availability_day` (`day_of_week`);

--
-- Indexes for table `doctor_clinics`
--
ALTER TABLE `doctor_clinics`
  ADD PRIMARY KEY (`doctor_clinic_id`),
  ADD UNIQUE KEY `uq_doctor_clinics_pair` (`doctor_id`,`clinic_id`,`room_number`),
  ADD KEY `idx_doctor_clinics_doctor_id` (`doctor_id`),
  ADD KEY `idx_doctor_clinics_clinic_id` (`clinic_id`);

--
-- Indexes for table `doctor_leaves`
--
ALTER TABLE `doctor_leaves`
  ADD PRIMARY KEY (`leave_id`),
  ADD KEY `idx_leaves_doctor_id` (`doctor_id`),
  ADD KEY `idx_leaves_date_range` (`start_date`,`end_date`);

--
-- Indexes for table `patients`
--
ALTER TABLE `patients`
  ADD PRIMARY KEY (`patient_id`),
  ADD UNIQUE KEY `uq_patients_national_id` (`national_id`),
  ADD KEY `idx_patients_fullname` (`last_name`,`first_name`),
  ADD KEY `idx_patients_phone` (`phone`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`service_id`),
  ADD KEY `idx_services_department_id` (`department_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `appointments`
--
ALTER TABLE `appointments`
  MODIFY `appointment_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `appointment_status_logs`
--
ALTER TABLE `appointment_status_logs`
  MODIFY `log_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `business_hours`
--
ALTER TABLE `business_hours`
  MODIFY `business_hour_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `clinics`
--
ALTER TABLE `clinics`
  MODIFY `clinic_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `department_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `doctors`
--
ALTER TABLE `doctors`
  MODIFY `doctor_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `doctor_availability`
--
ALTER TABLE `doctor_availability`
  MODIFY `availability_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `doctor_clinics`
--
ALTER TABLE `doctor_clinics`
  MODIFY `doctor_clinic_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `doctor_leaves`
--
ALTER TABLE `doctor_leaves`
  MODIFY `leave_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `patients`
--
ALTER TABLE `patients`
  MODIFY `patient_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `services`
--
ALTER TABLE `services`
  MODIFY `service_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `appointments`
--
ALTER TABLE `appointments`
  ADD CONSTRAINT `fk_appointments_availability` FOREIGN KEY (`availability_id`) REFERENCES `doctor_availability` (`availability_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_appointments_clinic` FOREIGN KEY (`clinic_id`) REFERENCES `clinics` (`clinic_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_appointments_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_appointments_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_appointments_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`service_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `appointment_status_logs`
--
ALTER TABLE `appointment_status_logs`
  ADD CONSTRAINT `fk_status_logs_appointment` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`appointment_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `business_hours`
--
ALTER TABLE `business_hours`
  ADD CONSTRAINT `fk_business_hours_doctor_clinic` FOREIGN KEY (`doctor_clinic_id`) REFERENCES `doctor_clinics` (`doctor_clinic_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `clinics`
--
ALTER TABLE `clinics`
  ADD CONSTRAINT `fk_clinics_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON UPDATE CASCADE;

--
-- Constraints for table `doctor_availability`
--
ALTER TABLE `doctor_availability`
  ADD CONSTRAINT `fk_availability_doctor_clinic` FOREIGN KEY (`doctor_clinic_id`) REFERENCES `doctor_clinics` (`doctor_clinic_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `doctor_clinics`
--
ALTER TABLE `doctor_clinics`
  ADD CONSTRAINT `fk_doctor_clinics_clinic` FOREIGN KEY (`clinic_id`) REFERENCES `clinics` (`clinic_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_doctor_clinics_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `doctor_leaves`
--
ALTER TABLE `doctor_leaves`
  ADD CONSTRAINT `fk_leaves_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `services`
--
ALTER TABLE `services`
  ADD CONSTRAINT `fk_services_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
