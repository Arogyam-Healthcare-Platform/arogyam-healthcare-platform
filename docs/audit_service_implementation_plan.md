# Arogyam Audit Service — Implementation Plan

## Overview
HIPAA-compliant immutable audit log for all platform actions.
INSERT-only — no UPDATE or DELETE ever. Go + Kafka Consumer.
Every sensitive action across all services is logged here permanently.

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | Go 1.22 |
| Framework | Gin |
| Database | PostgreSQL (arogyam_audit DB) — INSERT ONLY |
| Messaging | Kafka Consumer (all service topics) |
| Port | **8013** |

## What Gets Logged

```
auth.user.registered      → "Patient John registered"
auth.login.success        → "User logged in from IP 1.2.3.4"
auth.login.failed         → "Failed login attempt for email X"
auth.token.revoked        → "Token revoked for user X"

appointment.created       → "Appointment booked: Patient A → Doctor B"
appointment.cancelled     → "Appointment cancelled by Patient A"
appointment.status.change → "Appointment PENDING → CONFIRMED"

record.created            → "Medical record created by Dr. X for Patient Y"
record.accessed           → "Medical record viewed by Dr. X"
prescription.created      → "Prescription issued by Dr. X"

payment.processed         → "Payment ₹500 processed for Invoice #123"
refund.initiated          → "Refund initiated for Invoice #123"

admin.doctor.verified     → "Dr. X verified by Admin Y"
admin.user.banned         → "User X banned by Admin Y"
```

## Database Schema (INSERT ONLY)

```sql
CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type      VARCHAR(100) NOT NULL,
    event_source    VARCHAR(50) NOT NULL,   -- which service
    actor_id        VARCHAR(64),            -- who did it (user/admin)
    actor_role      VARCHAR(20),
    target_type     VARCHAR(50),            -- PATIENT | DOCTOR | APPOINTMENT
    target_id       VARCHAR(64),
    action          VARCHAR(100) NOT NULL,
    payload         JSONB,                  -- full event data
    ip_address      VARCHAR(45),
    user_agent      TEXT,
    severity        VARCHAR(10) DEFAULT 'INFO',  -- INFO | WARN | CRITICAL
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- NO updated_at, NO deleted_at — immutable forever
);

-- No UPDATE or DELETE permissions granted on this table
-- DB user arogyam_audit_writer has INSERT + SELECT only
```

## Kafka Topics Consumed (All Services)

```
auth.*
appointment.*
record.*
prescription.*
payment.*
admin.*
```

## API Endpoints (Read Only)

| Method | Path | Role Required |
|--------|------|--------------|
| `GET` | `/api/v1/audit/logs` | AUDITOR+ |
| `GET` | `/api/v1/audit/logs?actor_id=X` | AUDITOR+ |
| `GET` | `/api/v1/audit/logs?target_id=X` | AUDITOR+ |
| `GET` | `/api/v1/audit/logs?event_type=X` | AUDITOR+ |
| `GET` | `/api/v1/audit/logs?severity=CRITICAL` | SUPER_ADMIN |
| `GET` | `/api/v1/audit/logs/{id}` | AUDITOR+ |
| `GET` | `/health` | Public |

## Folder Structure

```
arogyam-audit-service/
├── main.go
├── config/
│   └── config.go
├── consumer/
│   └── kafka_consumer.go      # Consumes all topics
├── handler/
│   └── audit_handler.go       # Kafka event → audit log
├── api/
│   ├── server.go
│   └── routes/
│       └── audit.go           # REST read endpoints
├── repository/
│   └── audit_repository.go    # INSERT-only repository
├── domain/
│   └── audit_log.go
├── Dockerfile
├── go.mod
└── README.md
```

## docker-compose.yml Addition
```yaml
audit-service:
  build: ./arogyam-audit-service
  container_name: arogyam-audit-service
  ports:
    - "8013:8013"
  environment:
    - DB_HOST=postgres-db
    - DB_PORT=5432
    - DB_USER=arogyam_admin
    - DB_PASSWORD=arogyam_secure_pass_2026
    - DB_NAME=arogyam_audit
    - KAFKA_BROKERS=kafka:9092
    - KAFKA_GROUP_ID=arogyam-audit-consumer
  depends_on:
    postgres-db:
      condition: service_healthy
    kafka:
      condition: service_healthy
  networks:
    - arogyam-net
```
