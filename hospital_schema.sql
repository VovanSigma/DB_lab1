-- Лабораторна робота 1
-- Тема: Система управління лікарнею

-- Користувачі системи
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username      VARCHAR(50) UNIQUE NOT NULL,
    full_name     VARCHAR(150) NOT NULL,
    email         VARCHAR(100) UNIQUE,
    password_hash TEXT NOT NULL,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,

    -- аудит + soft delete
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    updated_by VARCHAR(50),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP,
    deleted_by VARCHAR(50)
);

-- Ролі
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- Зв'язок користувач-роль 
CREATE TABLE user_roles (
    user_id BIGINT NOT NULL REFERENCES users(id),
    role_id INT NOT NULL REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

-- Відділення
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    updated_by VARCHAR(50),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP,
    deleted_by VARCHAR(50)
);

-- Палати
CREATE TABLE rooms (
    id SERIAL PRIMARY KEY,
    department_id INT NOT NULL REFERENCES departments(id),
    room_number VARCHAR(10) NOT NULL,
    capacity INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Ліжка
CREATE TABLE beds (
    id SERIAL PRIMARY KEY,
    room_id INT NOT NULL REFERENCES rooms(id),
    bed_number VARCHAR(10) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Лікарі
CREATE TABLE doctors (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    department_id INT NOT NULL REFERENCES departments(id),
    first_name VARCHAR(100) NOT NULL,
    last_name  VARCHAR(100) NOT NULL,
    specialization VARCHAR(150),
    phone VARCHAR(30),
    email VARCHAR(100),

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    updated_by VARCHAR(50),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP,
    deleted_by VARCHAR(50)
);

-- Пацієнти 
CREATE TABLE patients (
    id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name  VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE,
    gender VARCHAR(10),
    phone VARCHAR(30),
    email VARCHAR(100),
    address TEXT,
    -- додаткова інфо JSONB
    additional_data JSONB,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    updated_by VARCHAR(50),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP,
    deleted_by VARCHAR(50)
);

-- Госпіталізації
CREATE TABLE admissions (
    id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES patients(id),
    doctor_id BIGINT REFERENCES doctors(id),
    department_id INT NOT NULL REFERENCES departments(id),
    bed_id INT REFERENCES beds(id),
    admit_datetime TIMESTAMP NOT NULL,
    discharge_datetime TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'active', -- active, discharged, cancelled

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    updated_by VARCHAR(50),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP,
    deleted_by VARCHAR(50)
);

-- Амбулаторні прийоми
CREATE TABLE appointments (
    id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES patients(id),
    doctor_id  BIGINT NOT NULL REFERENCES doctors(id),
    appointment_datetime TIMESTAMP NOT NULL,
    appointment_type VARCHAR(50),
    status VARCHAR(30) NOT NULL DEFAULT 'scheduled', -- scheduled, done, cancelled
    notes TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    updated_by VARCHAR(50),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP,
    deleted_by VARCHAR(50)
);

-- Медичні записи
CREATE TABLE medical_records (
    id BIGSERIAL PRIMARY KEY,
    admission_id BIGINT REFERENCES admissions(id),
    appointment_id BIGINT REFERENCES appointments(id),
    patient_id BIGINT NOT NULL REFERENCES patients(id),
    doctor_id BIGINT NOT NULL REFERENCES doctors(id),
    record_datetime TIMESTAMP NOT NULL DEFAULT NOW(),
    description TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    updated_by VARCHAR(50),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP,
    deleted_by VARCHAR(50)
);

-- Діагнози
CREATE TABLE diagnoses (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT
);

-- Зв'язок медичний запис-діагноз (m:n)
CREATE TABLE medical_record_diagnoses (
    medical_record_id BIGINT NOT NULL REFERENCES medical_records(id),
    diagnosis_id INT NOT NULL REFERENCES diagnoses(id),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (medical_record_id, diagnosis_id)
);

-- Медикаменти
CREATE TABLE medications (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    form VARCHAR(100),
    dosage VARCHAR(100),
    description TEXT
);

-- Рецепти
CREATE TABLE prescriptions (
    id BIGSERIAL PRIMARY KEY,
    medical_record_id BIGINT NOT NULL REFERENCES medical_records(id),
    prescribed_datetime TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Пункти рецептів
CREATE TABLE prescription_items (
    id BIGSERIAL PRIMARY KEY,
    prescription_id BIGINT NOT NULL REFERENCES prescriptions(id),
    medication_id INT NOT NULL REFERENCES medications(id),
    dosage VARCHAR(100),
    frequency VARCHAR(100),
    duration_days INT
);

-- Рахунки
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES patients(id),
    admission_id BIGINT REFERENCES admissions(id),
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'unpaid', -- unpaid, partially_paid, paid

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    updated_by VARCHAR(50)
);

-- Позиції рахунку
CREATE TABLE invoice_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id),
    description VARCHAR(255) NOT NULL,
    quantity NUMERIC(10,2) NOT NULL DEFAULT 1,
    unit_price NUMERIC(12,2) NOT NULL,
    amount NUMERIC(12,2) NOT NULL
);

-- Платежі
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount NUMERIC(12,2) NOT NULL,
    method VARCHAR(50), -- cash, card, transfer
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ФУНКЦІЇ ТА ТРИГЕРИ (soft delete + аудит)

-- Тригер-функція для оновлення полів аудиту
CREATE OR REPLACE FUNCTION set_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    NEW.updated_by := CURRENT_USER;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Тригер-функція яка забороняє hard delete
CREATE OR REPLACE FUNCTION prevent_hard_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Hard delete is not allowed. Use soft delete instead.';
END;
$$ LANGUAGE plpgsql;

-- Тригери аудиту для основних таблиць
CREATE TRIGGER trg_users_audit
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_departments_audit
BEFORE UPDATE ON departments
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_doctors_audit
BEFORE UPDATE ON doctors
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_patients_audit
BEFORE UPDATE ON patients
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_admissions_audit
BEFORE UPDATE ON admissions
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_appointments_audit
BEFORE UPDATE ON appointments
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_medical_records_audit
BEFORE UPDATE ON medical_records
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_invoices_audit
BEFORE UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION set_audit_fields();

-- Заборона hard delete для пацієнтів і лікарів
CREATE TRIGGER trg_patients_prevent_delete
BEFORE DELETE ON patients
FOR EACH ROW
EXECUTE FUNCTION prevent_hard_delete();

CREATE TRIGGER trg_doctors_prevent_delete
BEFORE DELETE ON doctors
FOR EACH ROW
EXECUTE FUNCTION prevent_hard_delete();


-- Soft delete пацієнта
CREATE OR REPLACE FUNCTION soft_delete_patient(p_patient_id BIGINT, p_user VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE patients
    SET is_deleted = TRUE,
        deleted_at = NOW(),
        deleted_by = p_user
    WHERE id = p_patient_id;
END;
$$ LANGUAGE plpgsql;

-- Soft delete лікаря
CREATE OR REPLACE FUNCTION soft_delete_doctor(p_doctor_id BIGINT, p_user VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE doctors
    SET is_deleted = TRUE,
        deleted_at = NOW(),
        deleted_by = p_user
    WHERE id = p_doctor_id;
END;
$$ LANGUAGE plpgsql;

-- Створення пацієнта
CREATE OR REPLACE FUNCTION create_patient(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_middle_name VARCHAR,
    p_dob DATE,
    p_gender VARCHAR,
    p_phone VARCHAR,
    p_email VARCHAR,
    p_address TEXT,
    p_additional_data JSONB,
    p_user VARCHAR
) RETURNS BIGINT AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO patients(
        first_name, last_name, middle_name, date_of_birth, gender,
        phone, email, address, additional_data,
        created_at, updated_at, updated_by
    )
    VALUES (
        p_first_name, p_last_name, p_middle_name, p_dob, p_gender,
        p_phone, p_email, p_address, p_additional_data,
        NOW(), NOW(), p_user
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Запис на прийом (перевірка конфлікту часу)
CREATE OR REPLACE FUNCTION schedule_appointment(
    p_patient_id BIGINT,
    p_doctor_id BIGINT,
    p_datetime TIMESTAMP,
    p_type VARCHAR,
    p_user VARCHAR
) RETURNS BIGINT AS $$
DECLARE
    v_id BIGINT;
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM appointments
        WHERE doctor_id = p_doctor_id
          AND appointment_datetime = p_datetime
          AND is_deleted = FALSE
          AND status <> 'cancelled'
    ) INTO v_exists;

    IF v_exists THEN
        RAISE EXCEPTION 'Doctor already has an appointment at this time';
    END IF;

    INSERT INTO appointments(
        patient_id, doctor_id, appointment_datetime,
        appointment_type, status,
        created_at, updated_at, updated_by
    )
    VALUES (
        p_patient_id, p_doctor_id, p_datetime,
        p_type, 'scheduled',
        NOW(), NOW(), p_user
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Реєстрація госпіталізації
CREATE OR REPLACE FUNCTION register_admission(
    p_patient_id BIGINT,
    p_doctor_id BIGINT,
    p_department_id INT,
    p_bed_id INT,
    p_admit_datetime TIMESTAMP,
    p_user VARCHAR
) RETURNS BIGINT AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO admissions(
        patient_id, doctor_id, department_id, bed_id,
        admit_datetime, status,
        created_at, updated_at, updated_by
    )
    VALUES (
        p_patient_id, p_doctor_id, p_department_id, p_bed_id,
        p_admit_datetime, 'active',
        NOW(), NOW(), p_user
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Створення рахунку для госпіталізації
CREATE OR REPLACE FUNCTION create_invoice_for_admission(
    p_admission_id BIGINT,
    p_user VARCHAR
) RETURNS BIGINT AS $$
DECLARE
    v_patient_id BIGINT;
    v_invoice_id BIGINT;
BEGIN
    SELECT patient_id INTO v_patient_id
    FROM admissions
    WHERE id = p_admission_id;

    IF v_patient_id IS NULL THEN
        RAISE EXCEPTION 'Admission not found';
    END IF;

    INSERT INTO invoices(
        patient_id, admission_id, invoice_date,
        total_amount, status,
        created_at, updated_at, updated_by
    )
    VALUES (
        v_patient_id, p_admission_id, CURRENT_DATE,
        0, 'unpaid',
        NOW(), NOW(), p_user
    )
    RETURNING id INTO v_invoice_id;

    RETURN v_invoice_id;
END;
$$ LANGUAGE plpgsql;

-- UDF: тривалість госпіталізації в днях
CREATE OR REPLACE FUNCTION fn_calc_stay_days(p_admission_id BIGINT)
RETURNS INT AS $$
DECLARE
    v_admit TIMESTAMP;
    v_discharge TIMESTAMP;
BEGIN
    SELECT admit_datetime,
           COALESCE(discharge_datetime, NOW())
    INTO v_admit, v_discharge
    FROM admissions
    WHERE id = p_admission_id;

    IF v_admit IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN (v_discharge::date - v_admit::date);
END;
$$ LANGUAGE plpgsql;

-- UDF: баланс пацієнта (борг=сума рахунків - сума оплат)
CREATE OR REPLACE FUNCTION fn_get_patient_balance(p_patient_id BIGINT)
RETURNS NUMERIC AS $$
DECLARE
    v_invoices NUMERIC;
    v_payments NUMERIC;
BEGIN
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_invoices
    FROM invoices
    WHERE patient_id = p_patient_id;

    SELECT COALESCE(SUM(p.amount), 0)
    INTO v_payments
    FROM payments p
    JOIN invoices i ON p.invoice_id = i.id
    WHERE i.patient_id = p_patient_id;

    RETURN v_invoices - v_payments;
END;
$$ LANGUAGE plpgsql;

-- Додати позицію рахунку + оновити total_amount
CREATE OR REPLACE FUNCTION add_invoice_item(
    p_invoice_id BIGINT,
    p_description VARCHAR,
    p_quantity NUMERIC,
    p_unit_price NUMERIC
) RETURNS BIGINT AS $$
DECLARE
    v_id BIGINT;
    v_amount NUMERIC;
BEGIN
    v_amount := p_quantity * p_unit_price;

    INSERT INTO invoice_items(invoice_id, description, quantity, unit_price, amount)
    VALUES (p_invoice_id, p_description, p_quantity, p_unit_price, v_amount)
    RETURNING id INTO v_id;

    UPDATE invoices
    SET total_amount = (
        SELECT COALESCE(SUM(amount), 0)
        FROM invoice_items
        WHERE invoice_id = p_invoice_id
    )
    WHERE id = p_invoice_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Створення медичного запису
CREATE OR REPLACE FUNCTION create_medical_record(
    p_patient_id BIGINT,
    p_doctor_id BIGINT,
    p_admission_id BIGINT,
    p_appointment_id BIGINT,
    p_description TEXT,
    p_user VARCHAR
) RETURNS BIGINT AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO medical_records(
        admission_id, appointment_id, patient_id, doctor_id,
        record_datetime, description,
        created_at, updated_at, updated_by
    )
    VALUES (
        p_admission_id, p_appointment_id, p_patient_id, p_doctor_id,
        NOW(), p_description,
        NOW(), NOW(), p_user
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;


-- VIEW (розрізи даних)

-- Активні (не видалені) пацієнти
CREATE OR REPLACE VIEW vw_active_patients AS
SELECT
    id,
    first_name,
    last_name,
    middle_name,
    date_of_birth,
    gender,
    phone,
    email,
    address,
    additional_data,
    created_at,
    updated_at
FROM patients
WHERE is_deleted = FALSE;

-- Детальні прийоми
CREATE OR REPLACE VIEW vw_appointments_detailed AS
SELECT
    a.id,
    a.appointment_datetime,
    a.status,
    a.appointment_type,
    p.id AS patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    d.id AS doctor_id,
    d.first_name || ' ' || d.last_name AS doctor_name,
    dep.name AS department_name
FROM appointments a
JOIN patients p ON a.patient_id = p.id
JOIN doctors d ON a.doctor_id = d.id
JOIN departments dep ON d.department_id = dep.id
WHERE a.is_deleted = FALSE;

-- ІНДЕКСИ

-- Звичайні B-Tree індекси
CREATE INDEX idx_appointments_doctor_datetime
    ON appointments (doctor_id, appointment_datetime);

CREATE INDEX idx_patients_phone
    ON patients (phone);

-- GIN-індекс по JSONB 
CREATE INDEX idx_patients_additional_data_gin
    ON patients
    USING gin (additional_data);