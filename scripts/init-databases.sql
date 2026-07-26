-- PostgreSQL Database Initialization Script for Arogyam Healthcare Platform
-- Creates isolated databases per microservice (Database-per-Service Pattern)

CREATE DATABASE arogyam_identity;
CREATE DATABASE arogyam_patient;
CREATE DATABASE arogyam_doctor;
CREATE DATABASE arogyam_appointment;
CREATE DATABASE arogyam_pharmacy;
CREATE DATABASE arogyam_health_record;
CREATE DATABASE arogyam_billing;
CREATE DATABASE arogyam_admin;
CREATE DATABASE arogyam_audit;

-- Grant all privileges on all databases to admin user
GRANT ALL PRIVILEGES ON DATABASE arogyam_identity TO arogyam_admin;
GRANT ALL PRIVILEGES ON DATABASE arogyam_patient TO arogyam_admin;
GRANT ALL PRIVILEGES ON DATABASE arogyam_doctor TO arogyam_admin;
GRANT ALL PRIVILEGES ON DATABASE arogyam_appointment TO arogyam_admin;
GRANT ALL PRIVILEGES ON DATABASE arogyam_pharmacy TO arogyam_admin;
GRANT ALL PRIVILEGES ON DATABASE arogyam_health_record TO arogyam_admin;
GRANT ALL PRIVILEGES ON DATABASE arogyam_billing TO arogyam_admin;
GRANT ALL PRIVILEGES ON DATABASE arogyam_admin TO arogyam_admin;
GRANT ALL PRIVILEGES ON DATABASE arogyam_audit TO arogyam_admin;

