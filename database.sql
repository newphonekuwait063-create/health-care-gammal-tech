PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- ============================================================
-- HEALTH CARE SYSTEM - PRODUCTION SCHEMA (SQLite)
-- Designed for scalability, normalization (3NF), and auditing.
-- No seed data included.
-- ============================================================

-- 1. Patients: core patient demographics and contact details
CREATE TABLE IF NOT EXISTS patients (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name    TEXT NOT NULL,
    last_name     TEXT NOT NULL,
    birth_date    TEXT,
    gender        TEXT CHECK (gender IN ('male', 'female', 'other')),
    phone         TEXT,
    email         TEXT,
    national_id   TEXT UNIQUE,
    address_line1 TEXT,
    address_line2 TEXT,
    city          TEXT,
    state         TEXT,
    postal_code   TEXT,
    country       TEXT DEFAULT 'Egypt',
    created_at    TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. Providers: doctors, nurses, technicians, any care provider
CREATE TABLE IF NOT EXISTS providers (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name     TEXT NOT NULL,
    last_name      TEXT NOT NULL,
    specialty      TEXT,
    license_number TEXT UNIQUE,
    phone          TEXT,
    email          TEXT,
    created_at     TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 3. Facilities: hospitals, clinics, labs, pharmacies, imaging centers
CREATE TABLE IF NOT EXISTS facilities (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT NOT NULL,
    facility_type TEXT NOT NULL CHECK (facility_type IN (
        'hospital', 'clinic', 'lab', 'pharmacy', 'imaging_center'
    )),
    address_line1 TEXT,
    address_line2 TEXT,
    city          TEXT,
    state         TEXT,
    postal_code   TEXT,
    country       TEXT DEFAULT 'Egypt',
    phone         TEXT,
    email         TEXT,
    created_at    TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 4. Many-to-many relationship between providers and facilities
CREATE TABLE IF NOT EXISTS provider_facilities (
    provider_id INTEGER NOT NULL,
    facility_id INTEGER NOT NULL,
    started_at  TEXT,
    ended_at    TEXT,
    PRIMARY KEY (provider_id, facility_id),
    FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE RESTRICT,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE RESTRICT
);

-- 5. Appointments: scheduled visits before they actually happen
CREATE TABLE IF NOT EXISTS appointments (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id       INTEGER NOT NULL,
    provider_id      INTEGER,
    facility_id      INTEGER,
    appointment_date TEXT NOT NULL,
    start_time       TEXT,
    end_time         TEXT,
    reason           TEXT,
    status           TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN (
        'scheduled', 'confirmed', 'checked_in', 'completed',
        'cancelled', 'no_show', 'rescheduled'
    )),
    notes            TEXT,
    created_at       TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (patient_id)  REFERENCES patients(id)  ON DELETE RESTRICT,
    FOREIGN KEY (provider_id) REFERENCES providers(id)  ON DELETE SET NULL,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE SET NULL,
    CHECK (start_time IS NULL OR end_time IS NULL OR start_time < end_time)
);

-- 6. Encounters: actual clinical visits or interactions
CREATE TABLE IF NOT EXISTS encounters (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id       INTEGER NOT NULL,
    provider_id      INTEGER,
    facility_id      INTEGER,
    appointment_id   INTEGER,
    encounter_date   TEXT NOT NULL,
    encounter_type   TEXT NOT NULL DEFAULT 'visit' CHECK (encounter_type IN (
        'visit', 'telemedicine', 'emergency', 'follow_up', 'procedure'
    )),
    chief_complaint  TEXT,
    conclusion       TEXT,
    notes            TEXT,
    created_at       TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (patient_id)     REFERENCES patients(id)     ON DELETE RESTRICT,
    FOREIGN KEY (provider_id)    REFERENCES providers(id)    ON DELETE SET NULL,
    FOREIGN KEY (facility_id)    REFERENCES facilities(id)   ON DELETE SET NULL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL
);

-- 7. Diagnoses: ICD-10 coded medical conditions per encounter
CREATE TABLE IF NOT EXISTS diagnoses (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    encounter_id      INTEGER NOT NULL,
    icd10_code        TEXT NOT NULL,
    description       TEXT,
    diagnosis_date    TEXT DEFAULT (datetime('now')),
    primary_diagnosis INTEGER NOT NULL DEFAULT 0 CHECK (primary_diagnosis IN (0, 1)),
    notes             TEXT,
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (encounter_id) REFERENCES encounters(id) ON DELETE RESTRICT
);

-- 8. Procedures: CPT-coded medical interventions and operations
CREATE TABLE IF NOT EXISTS procedures (
    id                     INTEGER PRIMARY KEY AUTOINCREMENT,
    encounter_id           INTEGER NOT NULL,
    cpt_code               TEXT NOT NULL,
    description            TEXT,
    procedure_date         TEXT,
    performing_provider_id INTEGER,
    facility_id            INTEGER,
    notes                  TEXT,
    created_at             TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at             TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (encounter_id)           REFERENCES encounters(id) ON DELETE RESTRICT,
    FOREIGN KEY (performing_provider_id) REFERENCES providers(id)  ON DELETE SET NULL,
    FOREIGN KEY (facility_id)            REFERENCES facilities(id) ON DELETE SET NULL
);

-- 9. Medications: master drug catalog
CREATE TABLE IF NOT EXISTS medications (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    name         TEXT NOT NULL,
    generic_name TEXT,
    form         TEXT CHECK (form IN (
        'tablet', 'capsule', 'syrup', 'injection', 'drops', 'topical', 'inhaler'
    )),
    strength     TEXT,
    unit         TEXT,
    route        TEXT,
    created_at   TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 10. Prescriptions: medication orders linked to encounters
CREATE TABLE IF NOT EXISTS prescriptions (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    encounter_id   INTEGER NOT NULL,
    medication_id  INTEGER NOT NULL,
    provider_id    INTEGER,
    dosage         TEXT,
    frequency      TEXT,
    duration_days  INTEGER CHECK (duration_days >= 0),
    quantity       INTEGER CHECK (quantity >= 0),
    refills        INTEGER NOT NULL DEFAULT 0 CHECK (refills >= 0),
    instructions   TEXT,
    prescribed_at  TEXT NOT NULL DEFAULT (datetime('now')),
    created_at     TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at     TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (encounter_id)  REFERENCES encounters(id)  ON DELETE RESTRICT,
    FOREIGN KEY (medication_id) REFERENCES medications(id)  ON DELETE RESTRICT,
    FOREIGN KEY (provider_id)   REFERENCES providers(id)    ON DELETE SET NULL
);

-- 11. Lab tests: master catalog of available tests
CREATE TABLE IF NOT EXISTS lab_tests (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    test_code      TEXT UNIQUE NOT NULL,
    name           TEXT NOT NULL,
    category       TEXT,
    unit           TEXT,
    reference_low  TEXT,
    reference_high TEXT,
    created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 12. Lab orders: requests for lab work linked to patients/encounters
CREATE TABLE IF NOT EXISTS lab_orders (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id            INTEGER NOT NULL,
    encounter_id          INTEGER,
    ordering_provider_id  INTEGER,
    performing_facility_id INTEGER,
    order_date            TEXT NOT NULL DEFAULT (datetime('now')),
    status                TEXT NOT NULL DEFAULT 'ordered' CHECK (status IN (
        'ordered', 'collected', 'processing', 'completed', 'cancelled'
    )),
    notes                 TEXT,
    created_at            TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at            TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (patient_id)             REFERENCES patients(id)   ON DELETE RESTRICT,
    FOREIGN KEY (encounter_id)           REFERENCES encounters(id) ON DELETE SET NULL,
    FOREIGN KEY (ordering_provider_id)   REFERENCES providers(id)  ON DELETE SET NULL,
    FOREIGN KEY (performing_facility_id) REFERENCES facilities(id) ON DELETE SET NULL
);

-- 13. Lab results: individual test results per lab order
CREATE TABLE IF NOT EXISTS lab_results (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    lab_order_id    INTEGER NOT NULL,
    lab_test_id     INTEGER NOT NULL,
    result_value    TEXT,
    result_unit     TEXT,
    result_date     TEXT NOT NULL DEFAULT (datetime('now')),
    reference_range TEXT,
    is_abnormal     INTEGER NOT NULL DEFAULT 0 CHECK (is_abnormal IN (0, 1)),
    comments        TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (lab_order_id) REFERENCES lab_orders(id) ON DELETE RESTRICT,
    FOREIGN KEY (lab_test_id)  REFERENCES lab_tests(id)  ON DELETE RESTRICT,
    UNIQUE (lab_order_id, lab_test_id)
);

-- 14. Insurance policies: coverage attached to a patient
CREATE TABLE IF NOT EXISTS insurance_policies (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id        INTEGER NOT NULL,
    insurance_company TEXT NOT NULL,
    policy_number     TEXT,
    group_number      TEXT,
    coverage_start    TEXT,
    coverage_end      TEXT,
    plan_type         TEXT,
    status            TEXT NOT NULL DEFAULT 'active' CHECK (status IN (
        'active', 'expired', 'cancelled'
    )),
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE RESTRICT
);

-- 15. Claims: billing claims submitted to insurance
CREATE TABLE IF NOT EXISTS claims (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id          INTEGER NOT NULL,
    encounter_id        INTEGER,
    insurance_policy_id INTEGER,
    claim_number        TEXT UNIQUE NOT NULL,
    claim_date          TEXT NOT NULL DEFAULT (datetime('now')),
    total_amount        NUMERIC NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    approved_amount     NUMERIC CHECK (approved_amount >= 0),
    status              TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
        'draft', 'submitted', 'approved', 'denied', 'paid', 'cancelled'
    )),
    denial_reason       TEXT,
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (patient_id)          REFERENCES patients(id)             ON DELETE RESTRICT,
    FOREIGN KEY (encounter_id)        REFERENCES encounters(id)           ON DELETE SET NULL,
    FOREIGN KEY (insurance_policy_id) REFERENCES insurance_policies(id)   ON DELETE SET NULL
);

-- ============================================================
-- INDEXES: speed up the most common clinical and billing queries
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_patients_name     ON patients(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_patients_phone    ON patients(phone);

CREATE INDEX IF NOT EXISTS idx_appointments_patient ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date    ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status  ON appointments(status);

CREATE INDEX IF NOT EXISTS idx_encounters_patient ON encounters(patient_id);
CREATE INDEX IF NOT EXISTS idx_encounters_date    ON encounters(encounter_date);
CREATE INDEX IF NOT EXISTS idx_encounters_type    ON encounters(encounter_type);

CREATE INDEX IF NOT EXISTS idx_diagnoses_encounter ON diagnoses(encounter_id);
CREATE INDEX IF NOT EXISTS idx_diagnoses_icd10     ON diagnoses(icd10_code);

CREATE INDEX IF NOT EXISTS idx_procedures_encounter ON procedures(encounter_id);
CREATE INDEX IF NOT EXISTS idx_procedures_cpt       ON procedures(cpt_code);

CREATE INDEX IF NOT EXISTS idx_prescriptions_encounter  ON prescriptions(encounter_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_medication ON prescriptions(medication_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_date       ON prescriptions(prescribed_at);

CREATE INDEX IF NOT EXISTS idx_lab_orders_patient ON lab_orders(patient_id);
CREATE INDEX IF NOT EXISTS idx_lab_orders_status  ON lab_orders(status);
CREATE INDEX IF NOT EXISTS idx_lab_orders_date    ON lab_orders(order_date);

CREATE INDEX IF NOT EXISTS idx_lab_results_order ON lab_results(lab_order_id);
CREATE INDEX IF NOT EXISTS idx_lab_results_test  ON lab_results(lab_test_id);

CREATE INDEX IF NOT EXISTS idx_insurance_patient ON insurance_policies(patient_id);
CREATE INDEX IF NOT EXISTS idx_insurance_status  ON insurance_policies(status);

CREATE INDEX IF NOT EXISTS idx_claims_patient ON claims(patient_id);
CREATE INDEX IF NOT EXISTS idx_claims_date    ON claims(claim_date);
CREATE INDEX IF NOT EXISTS idx_claims_status  ON claims(status);

COMMIT;
