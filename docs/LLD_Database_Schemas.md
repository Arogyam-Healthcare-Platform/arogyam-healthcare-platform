# Enterprise Database Schema Design (LLD)

This document provides a detailed, service-by-service breakdown of the database schemas for the Arogyam Healthcare Platform. Following the **Database-per-Service** microservice pattern, each service has its own isolated database (or logical schema) to ensure strict boundaries and high availability.

> [!NOTE]
> All primary keys (`id`) use `UUID` (Universally Unique Identifier) unless otherwise specified. UUIDs are essential for distributed systems to prevent ID collisions and guessing. Time audit fields (`created_at`, `updated_at`) are assumed to exist on almost every table.

---

## 1. Identity & Auth Service (PostgreSQL)
**Purpose:** Manages user credentials, roles, and session tokens.

### Table: `users`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | Unique user identifier. |
| `email` | VARCHAR | Unique, Not Null, Indexed | User's email for login. |
| `password_hash` | VARCHAR | Not Null | Bcrypt/Argon2 hashed password. |
| `role` | ENUM | Not Null | `PATIENT`, `DOCTOR`, `ADMIN`. |
| `is_active` | BOOLEAN | Default: true | Soft-ban or deactivate accounts. |
| `last_login` | TIMESTAMP | Nullable | Tracks last active session. |

### Table: `refresh_tokens`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `user_id` | UUID | Foreign Key (`users.id`) | |
| `token` | VARCHAR | Unique, Not Null | Securely generated refresh token string. |
| `expires_at` | TIMESTAMP | Not Null | Token expiration time. |
| `is_revoked` | BOOLEAN | Default: false | True if user logs out manually. |

### Table: `password_history`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `user_id` | UUID | Foreign Key (`users.id`) | |
| `password_hash` | VARCHAR | Not Null | |
| `created_at` | TIMESTAMP | Not Null | Prevents reusing recent passwords. |

### Table: `login_attempts`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `user_id` | UUID | Foreign Key (`users.id`) | |
| `ip_address` | VARCHAR | Not Null | |
| `is_success` | BOOLEAN | Not Null | |
| `attempt_time`| TIMESTAMP | Not Null | For rate limiting / brute force protection. |

### Table: `password_reset_tokens`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `user_id` | UUID | Foreign Key (`users.id`) | |
| `token` | VARCHAR | Unique, Not Null | |
| `expires_at` | TIMESTAMP | Not Null | |
| `is_used` | BOOLEAN | Default: false | |

### Table: `email_verification`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `user_id` | UUID | Foreign Key (`users.id`) | |
| `token` | VARCHAR | Unique, Not Null | |
| `expires_at` | TIMESTAMP | Not Null | |
| `is_verified` | BOOLEAN | Default: false | |

### Table: `mfa_devices`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `user_id` | UUID | Foreign Key (`users.id`) | |
| `device_type` | VARCHAR | Not Null | e.g., 'AUTHENTICATOR_APP', 'SMS' |
| `secret_key` | VARCHAR | Not Null | |
| `is_enabled` | BOOLEAN | Default: true | |

### Table: `device_sessions`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `user_id` | UUID | Foreign Key (`users.id`) | |
| `refresh_token_id`| UUID | Foreign Key (`refresh_tokens.id`) | |
| `ip_address` | VARCHAR | Not Null | |
| `user_agent` | VARCHAR | Not Null | e.g., 'Chrome 104 on Windows 11' |
| `last_active` | TIMESTAMP | Not Null | |

---

## 2. Patient Service (PostgreSQL)
**Purpose:** Manages patient demographics and family/dependent profiles.

### Table: `patients`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `user_id` | UUID | Unique, Indexed | App-Level Ref: Auth Service (`users.id`). |
| `full_name` | VARCHAR | Not Null | |
| `date_of_birth` | DATE | Not Null | |
| `gender` | ENUM | Not Null | `MALE`, `FEMALE`, `OTHER`. |
| `blood_group` | VARCHAR | Nullable | e.g., 'O+', 'AB-'. |
| `emergency_contact` | VARCHAR | Nullable | Phone number. |

### Table: `dependents` (For Family Accounts)
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `primary_patient_id`| UUID | Foreign Key (`patients.id`) | The account owner. |
| `full_name` | VARCHAR | Not Null | |
| `relation` | VARCHAR | Not Null | e.g., 'Child', 'Parent'. |
| `date_of_birth` | DATE | Not Null | |

### Table: `patient_insurance`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `patient_id` | UUID | Foreign Key (`patients.id`) | |
| `provider_name` | VARCHAR | Not Null | e.g., 'Star Health' |
| `policy_number` | VARCHAR | Not Null | |
| `valid_till` | DATE | Not Null | |

### Table: `patient_allergies`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `patient_id` | UUID | Foreign Key (`patients.id`) | |
| `allergy_name` | VARCHAR | Not Null | e.g., 'Penicillin', 'Peanuts' |
| `severity` | VARCHAR | Not Null | e.g., 'HIGH', 'MILD' |

### Table: `family_medical_history`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `patient_id` | UUID | Foreign Key (`patients.id`) | |
| `condition` | VARCHAR | Not Null | e.g., 'Diabetes Type 2' |
| `relation` | VARCHAR | Not Null | e.g., 'Father' |

---

## 3. Doctor Service (PostgreSQL)
**Purpose:** Manages doctor profiles, specializations, and availability schedules.

### Table: `doctors`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `user_id` | UUID | Unique, Indexed | App-Level Ref: Auth Service (`users.id`). |
| `full_name` | VARCHAR | Not Null | |
| `specialization` | VARCHAR | Not Null, Indexed | e.g., 'Cardiology'. |
| `experience_years` | INT | Not Null | |
| `consultation_fee` | DECIMAL | Not Null | Default base fee. |
| `bio` | TEXT | Nullable | Doctor's professional summary. |
| `is_verified` | BOOLEAN | Default: false | Set to true via Admin Service. |

### Table: `clinic_locations`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `doctor_id` | UUID | Foreign Key (`doctors.id`) | |
| `address` | VARCHAR | Not Null | |
| `city` | VARCHAR | Not Null, Indexed | |
| `latitude`, `longitude`| DECIMAL | Nullable | For geospatial queries (synced to Search). |

### Table: `availability_schedules`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `doctor_id` | UUID | Foreign Key (`doctors.id`) | |
| `day_of_week` | INT | Not Null | 0 (Sun) to 6 (Sat). |
| `start_time` | TIME | Not Null | e.g., 09:00:00. |
| `end_time` | TIME | Not Null | e.g., 17:00:00. |

### Table: `doctor_qualifications`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `doctor_id` | UUID | Foreign Key (`doctors.id`) | |
| `degree` | VARCHAR | Not Null | e.g., 'MBBS', 'MD' |
| `institute_name`| VARCHAR | Not Null | |
| `passing_year` | INT | Not Null | |

### Table: `doctor_medical_licenses`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `doctor_id` | UUID | Foreign Key (`doctors.id`) | |
| `license_number`| VARCHAR | Not Null | |
| `issuing_authority`| VARCHAR | Not Null | e.g., 'Medical Council of India' |
| `expiry_date` | DATE | Nullable | |

### Table: `doctor_languages`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `doctor_id` | UUID | Foreign Key (`doctors.id`) | |
| `language` | VARCHAR | Not Null | e.g., 'English', 'Bengali', 'Hindi' |

### Table: `consultation_modes`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `doctor_id` | UUID | Foreign Key (`doctors.id`) | |
| `mode` | ENUM | Not Null | `VIDEO_CALL`, `CLINIC_VISIT` |
| `fee` | DECIMAL | Not Null | Can override base fee for specific mode. |

### Table: `doctor_ratings`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `doctor_id` | UUID | Foreign Key (`doctors.id`) | |
| `patient_id` | UUID | Not Null | App-Level Ref: Patient Service |
| `appointment_id`| UUID | Not Null | App-Level Ref: Appointment Service |
| `rating` | INT | Not Null | 1 to 5 stars. |
| `review_text` | TEXT | Nullable | |
| `created_at` | TIMESTAMP | Not Null | |

---

## 4. Appointment Service (PostgreSQL)
**Purpose:** Handles the state machine and booking logic for appointments.

### Table: `appointments`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `patient_id` | UUID | Indexed | App-Level Ref: Patient Service (`patients.id`). |
| `doctor_id` | UUID | Indexed | App-Level Ref: Doctor Service (`doctors.id`). |
| `appointment_type` | ENUM | Not Null | `VIDEO_CALL`, `CLINIC_VISIT`. |
| `status` | ENUM | Not Null | `SCHEDULED`, `ONGOING`, `COMPLETED`, `CANCELLED`. |
| `scheduled_date` | DATE | Not Null, Indexed | |
| `start_time` | TIME | Not Null | |
| `issue_description` | TEXT | Nullable | Patient provided symptoms. |
| `meeting_link` | VARCHAR | Nullable | Used if `VIDEO_CALL`. |
| `version` | INT | Default: 1 | Optimistic Locking. |
| `is_deleted` | BOOLEAN | Default: false | Soft Delete flag. |
| `deleted_at` | TIMESTAMP | Nullable | Soft Delete timestamp. |

### Table: `appointment_status_history` (Event Sourcing)
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `appointment_id` | UUID | Foreign Key (`appointments.id`) | |
| `status` | ENUM | Not Null | `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED` |
| `changed_by` | UUID | Not Null | App-Level Ref: Who made the change (Patient/Doctor/System) |
| `reason` | VARCHAR | Nullable | E.g., 'Payment Failed', 'Doctor Unavailable' |
| `created_at` | TIMESTAMP | Not Null | |

---

## 5. Pharmacy Service (PostgreSQL)
**Purpose:** Manages digital prescriptions.

### Table: `prescriptions`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `appointment_id` | UUID | Indexed, Unique | App-Level Ref: Appointment Service (`appointments.id`). |
| `patient_id` | UUID | Indexed | App-Level Ref: Patient Service (`patients.id`). |
| `doctor_id` | UUID | Indexed | App-Level Ref: Doctor Service (`doctors.id`). |
| `notes` | TEXT | Nullable | General advice from doctor. |

### Table: `prescription_items`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `prescription_id`| UUID | Foreign Key (`prescriptions.id`) | |
| `medicine_id` | UUID | Foreign Key (`medicine_master.id`) | Links to standard medicine directory. |
| `dosage` | VARCHAR | Not Null | e.g., '1-0-1' (Morning, Night). |
| `duration_days` | INT | Not Null | e.g., 7. |
| `instructions` | VARCHAR | Nullable | e.g., 'After food'. |

### Table: `medicine_master`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `brand_name` | VARCHAR | Not Null, Indexed | e.g., 'Napa', 'Calpol' |
| `generic_name` | VARCHAR | Not Null, Indexed | e.g., 'Paracetamol' |
| `manufacturer` | VARCHAR | Nullable | |
| `strength` | VARCHAR | Nullable | e.g., '500mg' |

### Table: `drug_interactions`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `medicine_a_id` | UUID | Foreign Key (`medicine_master.id`) | |
| `medicine_b_id` | UUID | Foreign Key (`medicine_master.id`) | |
| `severity` | ENUM | Not Null | `SEVERE`, `MODERATE`, `MILD` |
| `description` | TEXT | Not Null | E.g., 'Can cause severe liver damage if taken together.' |

### Table: `prescription_refills`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `prescription_id`| UUID | Foreign Key (`prescriptions.id`) | |
| `patient_id` | UUID | Not Null | App-Level Ref: Patient Service |
| `refill_date` | DATE | Not Null | |
| `status` | ENUM | Not Null | `PENDING`, `APPROVED`, `REJECTED`, `FULFILLED` |
| `notes` | TEXT | Nullable | |

---

## 6. Health Record Service (PostgreSQL)
**Purpose:** Long-term storage of medical history and IoT health sync data.

### Table: `health_records`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `patient_id` | UUID | Indexed | App-Level Ref: Patient Service (`patients.id`). |
| `record_type` | ENUM | Not Null | `LAB_REPORT`, `PRESCRIPTION_PDF`, `SCAN`. |
| `bucket_name` | VARCHAR | Not Null | Storage bucket reference. |
| `storage_provider` | ENUM | Not Null | `AWS_S3`, `AZURE_BLOB`, `GCP`, `LOCAL`. |
| `storage_key` | VARCHAR | Not Null | Exact object key (e.g., `patients/123/report.pdf`). |
| `mime_type` | VARCHAR | Not Null | e.g., 'application/pdf', 'image/png'. |
| `file_size` | BIGINT | Not Null | Size in bytes. |
| `checksum` | VARCHAR | Not Null | MD5/SHA256 for integrity check. |
| `encryption_key_id`| VARCHAR | Nullable | KMS Key ID used for field/file encryption. |
| `version` | INT | Default: 1 | |
| `is_latest` | BOOLEAN | Default: true | |
| `previous_version`| UUID | Nullable | Self-referencing link for document history. |
| `description` | TEXT | Nullable | |
| `recorded_date` | DATE | Not Null | |

### Table: `vital_signs` (IoT / Wearables)
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `patient_id` | UUID | Indexed | App-Level Ref: Patient Service (`patients.id`). |
| `heart_rate` | INT | Nullable | BPM |
| `blood_sugar` | DECIMAL | Nullable | mg/dL |
| `recorded_at` | TIMESTAMP | Not Null | Exact time metric was synced. |

---

## 7. Search Service (PostgreSQL + PostGIS)
**Purpose:** Fast, read-heavy querying for finding doctors. (Denormalized Data)

### Table: `search_index_doctors`
*Note: Data here is continuously synced from the Doctor Service via Kafka events (`DoctorProfileUpdated`).*
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `doctor_id` | UUID | Primary Key | |
| `full_name` | VARCHAR | Indexed (Full-text)| |
| `specialization` | VARCHAR | Indexed | |
| `location` | GEOMETRY(Point)| GIST Indexed | PostGIS spatial data type for "Nearby" queries. |
| `consultation_fee` | DECIMAL | Indexed | For sorting by price. |
| `average_rating` | DECIMAL | Indexed | Cached average rating. |

---

## 8. Messaging Service (Apache Cassandra)
**Purpose:** Extremely high write throughput and highly available storage for chat data. Cassandra is the FAANG standard (used by Discord, Apple) for messaging.

### Table: `chat_sessions`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `appointment_id` | UUID | Partition Key | Links chat to a specific appointment. |
| `patient_id` | UUID | | |
| `doctor_id` | UUID | | |
| `status` | TEXT | | `ACTIVE` or `CLOSED`. |
| `created_at` | TIMESTAMP | | |

### Table: `messages_by_session`
*Note: In Cassandra, data is modeled around queries. This table is optimized to instantly fetch the message history of a specific session, ordered by time.*
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `session_id` | UUID | Partition Key | Group all messages for one session together. |
| `message_id` | TIMEUUID | Clustering Key (DESC)| Sorts messages chronologically by default. |
| `sender_id` | UUID | | |
| `message_type` | TEXT | | `TEXT`, `IMAGE`, `DOCUMENT`. |
| `content` | TEXT | | |
| `translated_content`| TEXT | | |
| `attachments` | LIST<TEXT> | | URLs pointing to Storage Service. |
| `status` | TEXT | | `SENT`, `DELIVERED`, `SEEN`. |
| `is_deleted_for_all`| BOOLEAN | | "This message was deleted" flag. |
| `is_edited` | BOOLEAN | | Tracks if the message was modified. |
| `reactions` | MAP<UUID, TEXT>| | e.g., `{user_id: '👍'}` |
*Note on Typing Indicators: "Typing..." events are transient (temporary) and are managed in real-time via WebSockets (Redis Pub/Sub). They are NOT persisted in the Cassandra database.*

---

## 9. Admin & Analytics Service (PostgreSQL)
**Purpose:** Handles verifications and internal metrics.

### Table: `scheduled_jobs`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `job_name` | VARCHAR | Not Null, Unique | e.g., 'RebuildElasticSearchIndex', 'DailyPayouts' |
| `status` | ENUM | Not Null | `IDLE`, `RUNNING`, `FAILED` |
| `cron_expression` | VARCHAR | Not Null | e.g., '0 0 * * *' |
| `last_run` | TIMESTAMP | Nullable | |
| `next_run` | TIMESTAMP | Nullable | |
| `retry_count` | INT | Default: 0 | |

### Table: `doctor_verifications`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `doctor_id` | UUID | Indexed | App-Level Ref: Doctor Service (`doctors.id`). |
| `registration_id`| VARCHAR | Not Null | Medical Council ID. |
| `aadhaar_number` | VARCHAR | Not Null, Unique | |
| `status` | ENUM | Not Null | `PENDING`, `APPROVED`, `REJECTED`. |
| `verified_by_admin_id`| UUID | Nullable | ID of admin who reviewed. |
| `api_response_log`| JSONB | Nullable | Logs from 3rd-party KYC API (Setu/Zoop). |

---

## 10. Common Enterprise Patterns

### Table: `outbox_events` (Transactional Outbox Pattern)
*Note: This table exists in **every** PostgreSQL database that publishes events (e.g., Auth Service, Appointment Service). It guarantees that writing business data and publishing an event to Kafka happens atomically.*
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | Unique event ID. |
| `aggregate_type` | VARCHAR | Not Null | e.g., 'Appointment', 'User'. |
| `aggregate_id` | UUID | Not Null | The ID of the record that changed. |
| `event_type` | VARCHAR | Not Null | e.g., 'AppointmentCreated', 'UserRegistered'. |
| `payload` | JSONB | Not Null | The actual message data to be sent to Kafka. |
| `status` | ENUM | Default: 'PENDING' | `PENDING`, `PUBLISHED`, `FAILED`. |
| `retry_count` | INT | Default: 0 | Routes to DLQ if count > max_retries. |
| `created_at` | TIMESTAMP | Not Null | |
| `processed_at` | TIMESTAMP | Nullable | Time when Kafka acknowledged the publish. |


### Table: `processed_events` (Idempotent Consumer / Inbox Pattern)
*Note: This table exists in **every** PostgreSQL database that consumes events. It prevents duplicate processing per consumer if Kafka delivers the same message twice due to network retries.*
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `event_id` | UUID | Primary Key (Composite) | The exact ID of the event from Kafka. |
| `consumer_name` | VARCHAR | Primary Key (Composite) | e.g., 'NotificationService', 'SearchSync'. |
| `event_type` | VARCHAR | Not Null | e.g., 'AppointmentCreated'. |
| `processed_at` | TIMESTAMP | Not Null | Time when the event was successfully handled. |

### Table: `saga_state` (Distributed Transaction Tracking)
*Note: Tracks the progress of multi-service transactions (e.g., Booking -> Payment -> Notification) for safe rollbacks or retries.*
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `saga_id` | UUID | Primary Key | |
| `aggregate_id` | UUID | Not Null | e.g., Appointment ID. |
| `current_step` | VARCHAR | Not Null | e.g., 'PAYMENT_PENDING'. |
| `status` | ENUM | Not Null | `STARTED`, `COMPLETED`, `COMPENSATING`, `FAILED`. |
| `payload` | JSONB | Nullable | State data needed to resume or rollback. |
| `retry_count` | INT | Default: 0 | |
| `started_at` | TIMESTAMP | Not Null | |
| `completed_at` | TIMESTAMP | Nullable | |

---

## 11. Audit Service (PostgreSQL / Append-Only)
**Purpose:** Strict HIPAA compliance. Every action (Read/Write/Download) on a patient's data is logged here immutably via Kafka events. No `UPDATE` or `DELETE` queries are ever allowed on this database.

### Table: `audit_logs` (Immutable Design)
*Note: This database strictly enforces INSERT ONLY. UPDATE and DELETE queries are blocked at the database role level.*
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | Unique audit log ID. |
| `actor_id` | UUID | Not Null, Indexed | App-Level Ref: Who performed the action (User/Doctor ID). |
| `actor_role` | VARCHAR | Not Null | e.g., 'DOCTOR', 'ADMIN', 'PATIENT'. |
| `action_type` | VARCHAR | Not Null | e.g., 'VIEW_PRESCRIPTION', 'DOWNLOAD_REPORT'. |
| `resource_id` | UUID | Not Null | App-Level Ref: The ID of the accessed resource (e.g., Prescription ID). |
| `patient_id` | UUID | Not Null, Indexed | App-Level Ref: The patient whose data was accessed. |
| `ip_address` | VARCHAR | Nullable | For security tracking. |
| `user_agent` | VARCHAR | Nullable | Browser/Device details. |
| `timestamp` | TIMESTAMP | Not Null | Exact time of the event. |

---

## 12. Notification Service (PostgreSQL)
**Purpose:** Completely decoupled service for fanning out messages (Email, SMS, WhatsApp, Push). Listens to system-wide Kafka events (e.g., `AppointmentBooked`) and acts on them. It uses the `inbox_events` table (Idempotency) to avoid sending duplicate SMS/Emails.

### Table: `notification_logs`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | |
| `recipient_id` | UUID | Not Null, Indexed | App-Level Ref: The Patient/Doctor receiving it. |
| `channel` | ENUM | Not Null | `EMAIL`, `SMS`, `WHATSAPP`, `PUSH`. |
| `message_type` | VARCHAR | Not Null | e.g., 'APPOINTMENT_REMINDER', 'OTP'. |
| `content` | TEXT | Not Null | The actual message body. |
| `status` | ENUM | Not Null | `SENT`, `FAILED`, `DELIVERED`. |
| `provider_response`| JSONB | Nullable | Logs from Twilio/SendGrid/Firebase. |
| `sent_at` | TIMESTAMP | Not Null | |
