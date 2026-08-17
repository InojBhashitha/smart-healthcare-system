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

            // Ensure pharmacy columns and user foreign keys exist for Web Dashboard integration
            jdbcTemplate.execute("""
                ALTER TABLE pharmacies ADD COLUMN IF NOT EXISTS delivery_available BOOLEAN DEFAULT false;
                ALTER TABLE pharmacies ADD COLUMN IF NOT EXISTS contact_number VARCHAR(20);
                ALTER TABLE users ADD COLUMN IF NOT EXISTS pharmacy_id BIGINT;
            """);

            log.info("PostgreSQL schema integrity check complete!");
        } catch (Exception e) {
            log.error("Failed schema initialization: {}", e.getMessage());
        }
    }
}
