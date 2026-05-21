
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- SCHEMAS
-- =====================================================

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS gate;
CREATE SCHEMA IF NOT EXISTS billing;
CREATE SCHEMA IF NOT EXISTS customs;
CREATE SCHEMA IF NOT EXISTS security;
CREATE SCHEMA IF NOT EXISTS weighbridge;
CREATE SCHEMA IF NOT EXISTS yard;
CREATE SCHEMA IF NOT EXISTS workflow;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS iot;
CREATE SCHEMA IF NOT EXISTS audit;

-- =====================================================
-- CORE TABLES
-- =====================================================

CREATE TABLE core.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255),
    company_type VARCHAR(100),
    tax_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE core.drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES core.companies(id),
    full_name VARCHAR(255),
    national_id VARCHAR(100),
    mobile VARCHAR(50),
    biometric_id VARCHAR(100),
    license_number VARCHAR(100),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE core.trucks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES core.companies(id),
    plate_number VARCHAR(50),
    truck_type VARCHAR(100),
    rfid_tag VARCHAR(100),
    tare_weight NUMERIC,
    max_weight NUMERIC,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE core.containers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    container_number VARCHAR(50),
    iso_type VARCHAR(50),
    container_size VARCHAR(20),
    cargo_type VARCHAR(100),
    hazardous BOOLEAN DEFAULT FALSE,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- GATE OPERATIONS
-- =====================================================

CREATE TABLE gate.appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_no VARCHAR(100),
    truck_id UUID REFERENCES core.trucks(id),
    driver_id UUID REFERENCES core.drivers(id),
    container_id UUID REFERENCES core.containers(id),
    slot_start TIMESTAMP,
    slot_end TIMESTAMP,
    appointment_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE gate.gate_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_no VARCHAR(100),
    truck_id UUID REFERENCES core.trucks(id),
    driver_id UUID REFERENCES core.drivers(id),
    container_id UUID REFERENCES core.containers(id),
    gate_name VARCHAR(100),
    direction VARCHAR(20),
    arrival_time TIMESTAMP,
    gate_in_time TIMESTAMP,
    gate_out_time TIMESTAMP,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE gate.anpr_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES gate.gate_transactions(id),
    plate_number VARCHAR(50),
    confidence NUMERIC,
    image_url TEXT,
    captured_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE gate.rfid_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES gate.gate_transactions(id),
    rfid_tag VARCHAR(100),
    reader_name VARCHAR(100),
    captured_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- CUSTOMS
-- =====================================================

CREATE TABLE customs.customs_clearance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES gate.gate_transactions(id),
    customs_reference VARCHAR(100),
    clearance_status VARCHAR(50),
    hold_reason TEXT,
    release_code VARCHAR(100),
    cleared_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE customs.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES gate.gate_transactions(id),
    document_type VARCHAR(100),
    document_no VARCHAR(100),
    file_path TEXT,
    verified BOOLEAN DEFAULT FALSE,
    uploaded_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- WEIGHBRIDGE
-- =====================================================

CREATE TABLE weighbridge.weight_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES gate.gate_transactions(id),
    truck_id UUID REFERENCES core.trucks(id),
    gross_weight NUMERIC,
    tare_weight NUMERIC,
    net_weight NUMERIC,
    vgm_weight NUMERIC,
    overweight BOOLEAN DEFAULT FALSE,
    recorded_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- SECURITY
-- =====================================================

CREATE TABLE security.inspections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES gate.gate_transactions(id),
    inspection_type VARCHAR(100),
    inspection_result VARCHAR(50),
    remarks TEXT,
    inspected_by VARCHAR(100),
    inspection_time TIMESTAMP DEFAULT NOW()
);

CREATE TABLE security.blacklist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50),
    entity_value VARCHAR(255),
    reason TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- YARD OPERATIONS
-- =====================================================

CREATE TABLE yard.yard_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_name VARCHAR(100),
    block_name VARCHAR(100),
    slot_name VARCHAR(100),
    location_status VARCHAR(50)
);

CREATE TABLE yard.container_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    container_id UUID REFERENCES core.containers(id),
    from_location UUID REFERENCES yard.yard_locations(id),
    to_location UUID REFERENCES yard.yard_locations(id),
    moved_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- BILLING & FINANCE
-- =====================================================

CREATE TABLE billing.tariffs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tariff_name VARCHAR(255),
    tariff_type VARCHAR(100),
    truck_type VARCHAR(100),
    container_type VARCHAR(100),
    base_fee NUMERIC,
    vat_percentage NUMERIC,
    active BOOLEAN DEFAULT TRUE,
    effective_from DATE,
    effective_to DATE
);

CREATE TABLE billing.invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_no VARCHAR(100),
    transaction_id UUID REFERENCES gate.gate_transactions(id),
    subtotal NUMERIC,
    vat_amount NUMERIC,
    total_amount NUMERIC,
    payment_status VARCHAR(50),
    issued_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE billing.invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID REFERENCES billing.invoices(id),
    item_name VARCHAR(255),
    quantity NUMERIC,
    unit_price NUMERIC,
    vat_percentage NUMERIC,
    total NUMERIC
);

CREATE TABLE billing.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID REFERENCES billing.invoices(id),
    payment_method VARCHAR(100),
    payment_reference VARCHAR(100),
    paid_amount NUMERIC,
    payment_status VARCHAR(50),
    paid_at TIMESTAMP
);

CREATE TABLE billing.parking_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    truck_id UUID REFERENCES core.trucks(id),
    entry_time TIMESTAMP,
    exit_time TIMESTAMP,
    duration_minutes INTEGER,
    fee NUMERIC
);

-- =====================================================
-- IOT & OPENREMOTE
-- =====================================================

CREATE TABLE iot.devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_name VARCHAR(255),
    device_type VARCHAR(100),
    mqtt_topic VARCHAR(255),
    openremote_asset_id VARCHAR(255),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE iot.telemetry (
    id BIGSERIAL PRIMARY KEY,
    device_id UUID REFERENCES iot.devices(id),
    metric_name VARCHAR(100),
    metric_value NUMERIC,
    recorded_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- WORKFLOW
-- =====================================================

CREATE TABLE workflow.process_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_name VARCHAR(255),
    reference_id UUID,
    process_status VARCHAR(50),
    started_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE TABLE workflow.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_instance_id UUID REFERENCES workflow.process_instances(id),
    task_name VARCHAR(255),
    assigned_to VARCHAR(100),
    task_status VARCHAR(50),
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- =====================================================
-- ANALYTICS
-- =====================================================

CREATE TABLE analytics.kpi_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_name VARCHAR(255),
    kpi_value NUMERIC,
    kpi_date DATE
);

-- =====================================================
-- AUDIT
-- =====================================================

CREATE TABLE audit.audit_logs (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100),
    action_type VARCHAR(100),
    entity_name VARCHAR(100),
    entity_id UUID,
    details JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_gate_transactions_truck
ON gate.gate_transactions(truck_id);

CREATE INDEX idx_gate_transactions_container
ON gate.gate_transactions(container_id);

CREATE INDEX idx_telemetry_time
ON iot.telemetry(recorded_at);

CREATE INDEX idx_invoice_status
ON billing.invoices(payment_status);

CREATE INDEX idx_customs_status
ON customs.customs_clearance(clearance_status);

