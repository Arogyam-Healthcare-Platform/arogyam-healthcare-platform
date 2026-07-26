# Arogyam Health Record Service — Implementation Plan

## Overview
Patient এর সম্পূর্ণ medical history manage করে — lab reports, prescriptions,
diagnoses, allergies, chronic conditions। HIPAA compliant, immutable audit log সহ।

## Domain Boundaries

```
Health Record Service owns:
  ├── Medical Records (diagnoses, visit notes)
  ├── Lab Results (blood test, X-ray, MRI reports)
  ├── Prescriptions (doctor লিখে দেওয়া medicine)
  ├── Allergies & Chronic Conditions
  └── Vitals History (BP, sugar, weight)

Does NOT own:
  ├── Patient profile → Patient Service
  ├── Doctor profile  → Doctor Service
  └── Appointments    → Appointment Service
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Java 17 |
| Framework | Spring Boot 3.2 |
| Database | PostgreSQL (arogyam_health_records DB) |
| File Storage | Local volume / S3-compatible (MinIO mock) |
| Messaging | Kafka Producer (record.created.v1) |
| Auth | gRPC → Auth Service (JWT validation) |
| API Docs | SpringDoc OpenAPI (Swagger UI) |
| Port | **8008** |

## Domain Models

```java
MedicalRecord {
  id, patientId, doctorId, appointmentId
  recordType: DIAGNOSIS | LAB_RESULT | PRESCRIPTION | VITAL | ALLERGY
  title, description
  attachmentUrl   // PDF/Image URL
  isDeleted: false  // Soft delete only
  version         // Optimistic locking
  createdAt, updatedAt
}

Prescription {
  id, recordId, patientId, doctorId
  medicines: List<PrescribedMedicine>
  instructions, duration
  issuedAt, expiresAt
}

PrescribedMedicine {
  name, dosage, frequency, duration, notes
}

LabResult {
  id, recordId, patientId
  testName, labName
  resultValue, normalRange, unit
  status: NORMAL | ABNORMAL | CRITICAL
  reportUrl
  testedAt
}

VitalRecord {
  id, patientId
  bloodPressureSystolic, bloodPressureDiastolic
  heartRate, bloodSugar, weight, height, temperature
  recordedAt
}

Allergy {
  id, patientId
  allergen, reaction, severity: MILD | MODERATE | SEVERE
  diagnosedAt
}
```

## API Endpoints

### Medical Records
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/records` | Create new medical record |
| `GET` | `/api/v1/records/{id}` | Get single record |
| `GET` | `/api/v1/records/patient/{patientId}` | All records for patient |
| `GET` | `/api/v1/records/patient/{patientId}?type=LAB_RESULT` | Filter by type |
| `DELETE` | `/api/v1/records/{id}` | Soft delete (sets is_deleted=true) |

### Prescriptions
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/prescriptions` | Create prescription |
| `GET` | `/api/v1/prescriptions/{id}` | Get prescription |
| `GET` | `/api/v1/prescriptions/patient/{patientId}` | Patient's prescriptions |
| `GET` | `/api/v1/prescriptions/{id}/download` | Download PDF |

### Lab Results
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/lab-results` | Upload lab result |
| `GET` | `/api/v1/lab-results/patient/{patientId}` | Patient's lab results |
| `GET` | `/api/v1/lab-results/{id}` | Single lab result |

### Vitals
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/vitals` | Record vitals |
| `GET` | `/api/v1/vitals/patient/{patientId}` | Vitals history (last 30 days) |

### Allergies
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/allergies` | Add allergy |
| `GET` | `/api/v1/allergies/patient/{patientId}` | Patient allergies |

### Health Check
| Method | Path | |
|--------|------|-|
| `GET` | `/health` | Service health |

## Kafka Events Published

```
record.created.v1         → Notification Service (new prescription/result alert)
prescription.created.v1   → Notification Service (push: "New prescription ready")
lab.result.uploaded.v1    → Notification Service (push: "Lab result available")
```

## Folder Structure (Clean Architecture)

```
arogyam-health-record-service/
├── src/main/java/com/arogyam/healthrecord/
│   ├── domain/
│   │   ├── model/
│   │   │   ├── MedicalRecord.java
│   │   │   ├── Prescription.java
│   │   │   ├── LabResult.java
│   │   │   ├── VitalRecord.java
│   │   │   └── Allergy.java
│   │   └── repository/
│   │       ├── IMedicalRecordRepository.java
│   │       └── IPrescriptionRepository.java
│   ├── application/
│   │   ├── dto/
│   │   └── usecase/
│   │       ├── CreateMedicalRecordUseCase.java
│   │       ├── GetPatientRecordsUseCase.java
│   │       └── CreatePrescriptionUseCase.java
│   ├── infrastructure/
│   │   ├── persistence/
│   │   ├── kafka/
│   │   │   └── RecordEventPublisher.java
│   │   └── grpc/
│   │       └── AuthGrpcClient.java
│   └── presentation/
│       └── controller/
│           ├── MedicalRecordController.java
│           ├── PrescriptionController.java
│           ├── LabResultController.java
│           ├── VitalController.java
│           └── AllergyController.java
├── Dockerfile
├── pom.xml
└── README.md
```

## Security
- JWT validation via gRPC → Auth Service (same as Patient/Doctor service)
- Patient শুধু নিজের records দেখতে পারবে
- Doctor শুধু নিজের patient এর records দেখতে পারবে
- Soft delete only — কোনো record কখনো DB থেকে permanently delete হবে না (HIPAA)

## docker-compose.yml Addition
```yaml
health-record-service:
  build: ./arogyam-health-record-service
  container_name: arogyam-health-record-service
  ports:
    - "8008:8008"
  environment:
    - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-db:5432/arogyam_health_records
    - SPRING_DATASOURCE_USERNAME=arogyam_admin
    - SPRING_DATASOURCE_PASSWORD=arogyam_secure_pass_2026
    - AUTH_SERVICE_GRPC_HOST=auth-service
    - AUTH_SERVICE_GRPC_PORT=50051
    - KAFKA_BOOTSTRAP_SERVERS=kafka:9092
  depends_on:
    postgres-db:
      condition: service_healthy
    kafka:
      condition: service_healthy
  networks:
    - arogyam-net
```

## Verification Plan
1. `GET /health` → 200 OK
2. `POST /api/v1/records` → record created
3. `GET /api/v1/records/patient/{id}` → records returned
4. Kafka event published verify: `docker compose logs notification-service`
5. Swagger UI: `http://localhost:8008/swagger-ui/index.html`
