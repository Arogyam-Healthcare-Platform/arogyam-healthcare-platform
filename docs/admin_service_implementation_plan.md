# Arogyam Admin Service — Implementation Plan

## Overview
Platform administration — doctor verification, user management, content moderation.
Strict RBAC: Super Admin > Doctor Admin > Hospital Admin > Support > Auditor.

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | Python 3.11 |
| Framework | FastAPI |
| Database | PostgreSQL (arogyam_admin DB) |
| Auth | JWT + Role check (gRPC → Auth Service) |
| KYC | Third-party API mock (Setu/Zoop later) |
| Port | **8011** |

## RBAC Roles

```
SUPER_ADMIN    → Full platform access
DOCTOR_ADMIN   → Verify/reject doctors, view doctor profiles
HOSPITAL_ADMIN → Manage hospital-associated doctors
SUPPORT        → View users, handle complaints
AUDITOR        → Read-only access to all audit logs
```

## Domain Models

```python
class DoctorVerification:
    id: str
    doctor_id: str
    medical_registration_id: str
    aadhaar_number: str  # encrypted
    status: PENDING | VERIFIED | REJECTED
    verified_by: str     # admin user id
    rejection_reason: str
    kyc_api_response: dict
    submitted_at: datetime
    reviewed_at: datetime

class AdminAuditLog:
    id: str
    admin_id: str
    action: str          # VERIFY_DOCTOR | REJECT_DOCTOR | BAN_USER
    target_type: str     # DOCTOR | PATIENT | APPOINTMENT
    target_id: str
    before_state: dict
    after_state: dict
    ip_address: str
    performed_at: datetime
```

## API Endpoints

### Doctor Verification
| Method | Path | Role Required |
|--------|------|--------------|
| `GET` | `/api/v1/admin/verifications/pending` | DOCTOR_ADMIN+ |
| `GET` | `/api/v1/admin/verifications/{id}` | DOCTOR_ADMIN+ |
| `POST` | `/api/v1/admin/verifications/{id}/verify` | DOCTOR_ADMIN+ |
| `POST` | `/api/v1/admin/verifications/{id}/reject` | DOCTOR_ADMIN+ |
| `POST` | `/api/v1/admin/verifications/{id}/kyc-check` | DOCTOR_ADMIN+ |

### User Management
| Method | Path | Role Required |
|--------|------|--------------|
| `GET` | `/api/v1/admin/users` | SUPPORT+ |
| `GET` | `/api/v1/admin/users/{id}` | SUPPORT+ |
| `POST` | `/api/v1/admin/users/{id}/ban` | SUPER_ADMIN |
| `POST` | `/api/v1/admin/users/{id}/unban` | SUPER_ADMIN |

### Dashboard Stats
| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/admin/stats/overview` | Platform metrics |
| `GET` | `/api/v1/admin/stats/doctors` | Doctor stats |
| `GET` | `/api/v1/admin/audit-logs` | Audit log (AUDITOR+) |
| `GET` | `/health` | Health check |

## KYC Integration (Mock → Real)
```python
# Mock (current):
async def verify_via_kyc_api(registration_id: str) -> dict:
    return {"status": "VERIFIED", "name": "Dr. Mock", "council": "MCI"}

# Production (Setu/Zoop):
async def verify_via_kyc_api(registration_id: str) -> dict:
    response = await setu_client.verify_medical_registration(registration_id)
    return response
```

## Kafka Events Published
```
doctor.verified.v1    → Notification Service (push: "Profile verified!")
doctor.rejected.v1    → Notification Service (push: "Verification failed")
user.banned.v1        → Auth Service (invalidate tokens)
```

## docker-compose.yml Addition
```yaml
admin-service:
  build: ./arogyam-admin-service
  container_name: arogyam-admin-service
  ports:
    - "8011:8011"
  environment:
    - POSTGRES_SERVER=postgres-db
    - POSTGRES_PORT=5432
    - POSTGRES_USER=arogyam_admin
    - POSTGRES_PASSWORD=arogyam_secure_pass_2026
    - POSTGRES_DB=arogyam_admin
    - AUTH_SERVICE_GRPC_HOST=auth-service
    - AUTH_SERVICE_GRPC_PORT=50051
    - KAFKA_BROKERS=kafka:9092
    - KYC_MODE=MOCK
  depends_on:
    postgres-db:
      condition: service_healthy
  networks:
    - arogyam-net
```
