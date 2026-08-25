-- Schema Refactoring for Health Data Pipeline

-- 1. Patients Master Table (Static Data)
CREATE TABLE IF NOT EXISTS patients (
    patient_id SERIAL PRIMARY KEY,
    age INT NOT NULL CHECK (age > 0 AND age < 120),
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Medical Measurements Table (Time-series / Dynamic Data)
CREATE TABLE IF NOT EXISTS patient_vitals (
    reading_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    bmi NUMERIC(4, 1) CHECK (bmi > 0.0),
    systolic_bp INT CHECK (systolic_bp BETWEEN 50 AND 250),
    diastolic_bp INT CHECK (diastolic_bp BETWEEN 30 AND 150),
    glucose_level INT CHECK (glucose_level > 0),
    is_diabetic SMALLINT DEFAULT 0 CHECK (is_diabetic IN (0, 1)), -- Target variable
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Composite Index for Machine Learning Data Extraction
CREATE INDEX idx_ml_features 
ON patient_vitals (patient_id, glucose_level, bmi, systolic_bp) 
WHERE is_diabetic IS NOT NULL;

-- 4. Analytical View for Data Science Consumption
CREATE VIEW vw_ml_diabetes_dataset AS
SELECT 
    p.patient_id,
    p.age,
    p.gender,
    v.bmi,
    v.systolic_bp,
    v.diastolic_bp,
    v.glucose_level,
    v.is_diabetic
FROM patients p
JOIN patient_vitals v ON p.patient_id = v.patient_id;
