package com.smarthealthcare.backend.config;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DatabaseSchemaInitializer {

    private final JdbcTemplate jdbcTemplate;

    public DatabaseSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @PostConstruct
    public void ensureSchemaIntegrity() {
        try {
            log.info("Ensuring PostgreSQL schema integrity for Phase 4 Treatment Plan & Dose Logs...");

            // Create treatment_plans table if not exists
            jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS treatment_plans (
                    plan_id BIGSERIAL PRIMARY KEY,
                    user_id BIGINT NOT NULL,
                    prescription_id BIGINT NOT NULL,
                    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
                    start_date DATE,
                    end_date DATE
                );
            """);

            // Create dose_schedules table if not exists
            jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS dose_schedules (
                    schedule_id BIGSERIAL PRIMARY KEY,
                    plan_id BIGINT NOT NULL,
                    medicine_name VARCHAR(255) NOT NULL,
                    strength VARCHAR(100),
                    instruction VARCHAR(255),
                    dose_slot VARCHAR(50) NOT NULL,
                    scheduled_time TIME NOT NULL
                );
            """);

            // Create dose_logs table if not exists
            jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS dose_logs (
                    log_id BIGSERIAL PRIMARY KEY,
                    schedule_id BIGINT NOT NULL,
                    log_date DATE NOT NULL,
                    status VARCHAR(50) NOT NULL,
                    taken_at TIMESTAMP
                );
            """);

            // Add log_date column if missing from dose_logs
            jdbcTemplate.execute("""
                ALTER TABLE dose_logs ADD COLUMN IF NOT EXISTS log_date DATE;
            """);

            // Drop legacy foreign key constraints pointing to old medicine_schedules table
            jdbcTemplate.execute("""
                ALTER TABLE dose_logs DROP CONSTRAINT IF EXISTS fk_dose_schedule;
                ALTER TABLE dose_logs DROP CONSTRAINT IF EXISTS fk_dose_schedules;
            """);

            // Create pharmacies table if not exists
            jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS pharmacies (
                    pharmacy_id BIGSERIAL PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    address VARCHAR(255) NOT NULL,
                    latitude DOUBLE PRECISION NOT NULL,
                    longitude DOUBLE PRECISION NOT NULL,
                    phone VARCHAR(50),
                    operating_hours VARCHAR(100),
                    is_verified BOOLEAN NOT NULL DEFAULT TRUE
                );
            """);

            // Create pharmacy_stocks table if not exists
            jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS pharmacy_stocks (
                    stock_id BIGSERIAL PRIMARY KEY,
                    pharmacy_id BIGINT NOT NULL,
                    medicine_id BIGINT NOT NULL,
                    unit_price NUMERIC(10,2),
                    quantity_available INT NOT NULL DEFAULT 0
                );
            """);

            // Create prescription_reservations table if not exists
            jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS prescription_reservations (
                    reservation_id BIGSERIAL PRIMARY KEY,
                    prescription_id BIGINT NOT NULL,
                    pharmacy_id BIGINT NOT NULL,
                    user_id BIGINT NOT NULL,
                    status VARCHAR(50) NOT NULL DEFAULT 'CONFIRMED',
                    pickup_code VARCHAR(50) NOT NULL UNIQUE,
                    reserved_at TIMESTAMP NOT NULL
                );
            """);

            log.info("PostgreSQL schema integrity check complete!");
        } catch (Exception e) {
            log.error("Failed schema initialization: {}", e.getMessage());
        }
    }
}
