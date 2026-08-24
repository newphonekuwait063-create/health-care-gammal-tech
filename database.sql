-- =================https://github.com/newphonekuwait063-create/health-care-gammal-tech/tree/main====================================
-- ----------------------------------------------
-- Table: patients
-- ---------------------------------------------------
CREATE TABLE IF NOT EXISTS patients (
    id            CHAR(36)     NOT NULL PRIMARY KEY DEFAULT (UUID()),
    name          VARCHAR(150) NOT NULL,
    phone         VARCHAR(20)  NOT NULL,
    age           SMALLINT UNSIGNED NULL,
    gender        ENUM('male', 'female') NOT NULL DEFAULT 'male',
    address       VARCHAR(255) NULL,
    notes         TEXT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_patients_name (name),
    INDEX idx_patients_phone (phone)
) ENGINE=InnoDB;

-- ---------------------------------------------------
-- Table: appointments
-- ---------------------------------------------------
CREATE TABLE IF NOT EXISTS appointments (
    id            CHAR(36)     NOT NULL PRIMARY KEY DEFAULT (UUID()),
    patient_id    CHAR(36)     NOT NULL,
    appt_date     DATE         NOT NULL,
    appt_time     TIME         NOT NULL,
    reason        VARCHAR(255) NULL,
    status        ENUM('upcoming', 'done', 'cancelled') NOT NULL DEFAULT 'upcoming',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id) REFERENCES patients(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_appointments_date (appt_date, appt_time),
    INDEX idx_appointments_status (status)
) ENGINE=InnoDB;

-- ---------------------------------------------------
-- Table: invoices
-- ---------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    id            CHAR(36)     NOT NULL PRIMARY KEY DEFAULT (UUID()),
    patient_id    CHAR(36)     NOT NULL,
    invoice_date  DATE         NOT NULL,
    amount        DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    description   VARCHAR(255) NULL,
    paid          BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_invoices_patient
        FOREIGN KEY (patient_id) REFERENCES patients(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_invoices_date (invoice_date),
    INDEX idx_invoices_paid (paid)
) ENGINE=InnoDB;

-- ---------------------------------------------------
-- Optional: users table (for staff login later)
-- ---------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id            CHAR(36)     NOT NULL PRIMARY KEY DEFAULT (UUID()),
    full_name     VARCHAR(150) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('admin', 'doctor', 'receptionist') NOT NULL DEFAULT 'receptionist',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------
-- Sample data (optional - remove if not needed)
-- ---------------------------------------------------
-- INSERT INTO patients (name, phone, age, gender, address, notes)
-- VALUES ('أحمد محمود', '01012345678', 34, 'male', 'القاهرة', 'حساسية من البنسلين');

-- INSERT INTO appointments (patient_id, appt_date, appt_time, reason, status)
-- SELECT id, '2026-08-25', '10:00:00', 'كشف دوري', 'upcoming' FROM patients LIMIT 1;

-- INSERT INTO invoices (patient_id, invoice_date, amount, description, paid)
-- SELECT id, '2026-08-24', 300.00, 'كشف + تحاليل', TRUE FROM patients LIMIT 1;

-- ---------------------------------------------------
-- Useful views
-- ---------------------------------------------------
CREATE OR REPLACE VIEW v_upcoming_appointments AS
SELECT a.id, p.name AS patient_name, p.phone, a.appt_date, a.appt_time, a.reason
FROM appointments a
JOIN patients p ON p.id = a.patient_id
WHERE a.status = 'upcoming'
ORDER BY a.appt_date, a.appt_time;

CREATE OR REPLACE VIEW v_unpaid_invoices AS
SELECT i.id, p.name AS patient_name, p.phone, i.invoice_date, i.amount, i.description
FROM invoices i
JOIN patients p ON p.id = i.patient_id
WHERE i.paid = FALSE
ORDER BY i.invoice_date;
