health-care-gammal-tech
# Healthcare Database Schema

A production-ready, normalized SQL schema for managing core healthcare data:
patients, providers, appointments, encounters, diagnoses, medications,
billing, and insurance claims. Designed with a clean 3NF relational model,
surrogate primary keys, foreign key constraints, and indexes for fast
analytical queries.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [File Structure](#file-structure)
- [Database Schema](#database-schema)
- [Getting Started](#getting-started)
- [Example Queries](#example-queries)
- [Design Decisions](#design-decisions)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository contains the foundational schema for a healthcare data
platform. It serves as the single source of truth for patient identities,
clinical encounters, and financial records without locking the project into a
specific application layer.

The schema is intentionally free of sample data so it can be used as a clean
starting point for real projects, local development, or academic work.

## Features

- Fully normalized design up to third normal form (3NF)
- Surrogate integer primary keys (`INTEGER PRIMARY KEY AUTOINCREMENT`)
- Referential integrity enforced through foreign key constraints
- `NOT NULL` and `CHECK` constraints for data quality
- Indexed foreign keys for fast joins and lookups
- Audit columns (`created_at`, `updated_at`) for change tracking
- Clear one-to-many and many-to-many relationships
- Extensible structure: new modules can be added without modifying existing tables

## File Structure

```
.
├── healthcare_schema.sql   # All CREATE TABLE, INDEX, and constraint statements
└── README.md               # Project documentation
```

## Database Schema

The schema is organized into four logical groups.

### 1. Reference Tables

| Table                | Description                                      |
|----------------------|--------------------------------------------------|
| `patients`           | Personal and demographic patient information     |
| `providers`          | Doctors, nurses, and other healthcare providers  |
| `facilities`         | Clinics, hospitals, labs, and departments        |
| `medications`        | Drug catalog with name, strength, and form       |
| `insurance_policies` | Insurance plans tied to a patient                |

### 2. Scheduling and Encounter Tables

| Table           | Description                                        |
|-----------------|----------------------------------------------------|
| `appointments`  | Booked visits linking patient, provider, and facility |
| `encounters`    | An actual patient visit with date, type, and reason |

### 3. Clinical Detail Tables

| Table            | Description                                        |
|------------------|----------------------------------------------------|
| `diagnoses`      | Diagnosis codes and descriptions per encounter     |
| `procedures`     | Medical procedures performed during an encounter   |
| `prescriptions`  | Medication prescriptions written at an encounter   |
| `lab_orders`     | Laboratory test requests for an encounter          |
| `lab_results`    | Results that belong to a lab order                 |

### 4. Billing and Insurance Tables

| Table      | Description                                            |
|------------|--------------------------------------------------------|
| `claims`   | Insurance claims generated from encounters            |

## Entity Relationship Overview

```
patients ─────┐
providers ────┼──> appointments ──> encounters ──┬─> diagnoses
facilities ───┘                                   ├─> procedures
                                                 ├─> prescriptions
                                                 ├─> lab_orders ──> lab_results
                                                 └─> claims <── insurance_policies
```

## Getting Started

### Prerequisites

- SQLite 3 (recommended) or any SQL-compatible database engine
- A terminal, or an online SQL editor such as
  [sqliteonline.com](https://sqliteonline.com)

### Running the Schema

Using the SQLite command line:

```bash
sqlite3 healthcare.db
.read healthcare_schema.sql
.tables
```

Using an online editor:

1. Open [sqliteonline.com](https://sqliteonline.com)
2. Paste the contents of `healthcare_schema.sql`
3. Click **Run**

All tables and indexes will be created. No sample data is inserted.

## Example Queries

```sql
-- Total encounters per patient
SELECT
    p.id,
    p.full_name,
    COUNT(e.id) AS visit_count
FROM patients p
LEFT JOIN encounters e
    ON e.patient_id = p.id
GROUP BY p.id, p.full_name
ORDER BY visit_count DESC;

-- Most common diagnoses
SELECT
    d.code,
    d.description,
    COUNT(*) AS occurrence
FROM diagnoses d
GROUP BY d.code, d.description
ORDER BY occurrence DESC;

-- Encounters by facility in the last 30 days
SELECT
    f.name AS facility,
    COUNT(e.id) AS encounters
FROM encounters e
JOIN facilities f
    ON f.id = e.facility_id
WHERE e.encounter_date >= date('now', '-30 days')
GROUP BY f.name;
```

## Design Decisions

- **Surrogate primary keys:** each table uses an auto-incrementing integer ID
  instead of natural composite keys. This keeps joins simple and avoids
  problems when real-world identifiers change.
- **Foreign keys everywhere:** every relationship is enforced by the database,
  preventing orphan rows.
- **Snake_case naming:** consistent lowercase naming with underscores for all
  objects, following common SQL style.
- **Audit columns:** `created_at` and `updated_at` allow change tracking and are
  populated by the application layer.
- **Separation of concerns:** reference data, events, clinical details, and
  billing are separated into distinct table groups so each area can evolve
  independently.

## Roadmap

- [ ] Add seed data generator scripts
- [ ] Create analytical views for common metrics
- [ ] Add database migrations tooling
- [ ] Add an Entity-Relationship diagram
- [ ] Support PostgreSQL and MySQL dialects

## Contributing

Contributions are welcome. Please open an issue first to discuss what you
would like to change.

## License

This project is licensed under the MIT License. See the repository license
file for details. 
