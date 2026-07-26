# Arogyam Healthcare Platform Enterprise Architecture (FAANG-Scale)

This document outlines the enterprise-grade architecture and project structure for the Arogyam healthcare platform. Designed with principles used at scale by companies like Google and Microsoft, this architecture emphasizes high availability, zero-trust security, strict observability, and resilient microservices.

## User Review Required

> [!IMPORTANT]
> The implementation plan has been upgraded to an Enterprise/FAANG-level architecture. Please review the advanced infrastructure, resiliency patterns, and domain structures below. If you are satisfied with this structure, let me know to proceed!

## 1. Domain-Driven Microservices Architecture

To support global scale and strict boundaries, the system is decomposed into highly decoupled, independently deployable microservices.

### Core Domain Services
1.  **Identity & Auth Service:** Centralized IAM, OAuth2/OIDC, JWT generation, and RBAC.
2.  **Patient Service:** Manages patient profiles and dependent (Family) accounts.
3.  **Doctor Service:** Manages doctor profiles, scheduling, and geolocation targeting.
4.  **Appointment Service (CQRS Applied):** Handles complex state machines for booking (clinic visit, video call). Write operations handle booking logic; Read replicas serve heavy dashboard queries.
5.  **Health Record Service:** Secure, immutable ledger (with Blockchain hooks) for medical history, integrating Wearable & IoT sync.
6.  **Pharmacy Service:** Handles E-Prescription generation, digital signing, and fulfillment routing.

### Supporting & Edge Services
7.  **API Gateway (Kubernetes Ingress Flow):** Flow: `Gateway` → `Ingress Controller` → `Service` → `Pods`. Enforces the middleware chain: `Authentication` → `Authorization` → `Rate Limiter` → `Validation` → `Logging` → `Tracing` → `Forward`.
8.  **Search Service (CQRS):** Elasticsearch cluster for sub-millisecond queries. *CQRS Flow:* `Command (Doctor Update)` → `Kafka` → `Projection (Sync Consumer)` → `Read DB (Elasticsearch)`.
9.  **AI Recommendation Service:** Interfaces with a `RecommendationEngine`. The implementation can hot-swap between `RuleBased`, `MLBased`, or `LLMBased` models without changing the service contract.
10. **Notification Service (Strategy Pattern):** Kafka-driven consumer. Uses a `NotificationProvider` interface to dynamically route to `EmailProvider`, `SMSProvider`, `WhatsAppProvider`, or `PushProvider`, strictly adhering to the Open/Closed Principle (OCP).
11. **Messaging Service:** WebSocket cluster backed by Redis Pub/Sub for real-time chat.
12. **Video Call Signaling Service:** WebRTC protocol using `TURN/STUN` servers and a Signaling Server for P2P routing.
13. **Queue Management Service:** Real-time wait-time calculation using Redis.
14. **Admin Service (RBAC):** Manages verifications. Strict Permission Model: `Super Admin`, `Doctor Admin`, `Hospital Admin`, `Support`, `Auditor`.
15. **Storage Service & CDN:** Manages `AWS S3/Azure Blob`. Global reads are accelerated via `CloudFront/Cloudflare CDN` (e.g., fast MRI downloads for remote doctors).
16. **Audit Service (Immutable):** Strict HIPAA compliance. Every action is logged immutably (INSERT ONLY). UPDATE and DELETE are fundamentally disabled at the database level.
17. **Analytics Service (OLAP):** Uses ClickHouse or BigQuery (Not OLTP PostgreSQL). `Kafka` → `ClickHouse` → `Grafana/Looker Dashboard` for high-speed aggregations.
18. **Background Job Scheduler:** `Scheduler Service (Quartz/Celery)` → Triggers Time-based Events (e.g., `Prescription Expiry`, `Appointment Reminder`).

| Layer | Technology Choice | FAANG Rationale |
| :--- | :--- | :--- |
| **Edge & API** | Kong Gateway, Cloudflare CDN | Global CDN caches heavy assets (MRIs). API Gateway routes traffic securely. |
| **Compute & Networking**| Kubernetes (EKS/GKE) | `Service Discovery` (e.g., K8s DNS/Eureka) resolves dynamic Pod IPs. Deployments use `Blue-Green` or `Canary (5% → 20% → 100%)`. Scaling uses `Horizontal Pod Autoscaler (HPA)` based on CPU/Memory and **Kafka Lag**. |
| **Sync Comm.** | gRPC (Protobuf), REST (OpenAPI) | Internal: gRPC. External: REST with strictly enforced `Contract First` (Swagger/OpenAPI) design. |
| **Async Comm.** | Kafka Cluster (RF=3) + Schema Registry | `Producer` → `Avro` → `Schema Registry` → `Kafka`. Enforces strict event schemas. Async processing for heavy tasks (AI Analysis). |
| **Primary DBs** | PostgreSQL (OLTP) + Flyway | Primary → Replica architecture for read scalability. `Flyway/Liquibase` for schema migrations. |
| **Analytics DBs** | ClickHouse / BigQuery (OLAP)| Columnar storage designed for billions of rows and heavy aggregations. |
| **NoSQL / Cache** | Redis Cluster, Cassandra | `Redis Cluster/Sentinel` for high availability. Cassandra for chat storage. |
| **Observability** | OpenTelemetry, Jaeger, Prometheus, Grafana | Tracing flow: `OTel` → `Jaeger` → `Grafana`. Uses **Structured JSON Logs** for fast indexing. |
| **Security & Config**| HashiCorp Vault, Spring Cloud Config| `mTLS` between services. `JWT/Key Rotation`, `OWASP` compliance. Centralized `Configuration Service` prevents hardcoded DB/Kafka URLs. PII Field-Level Encryption. |
| **Frontend** | React (Vite), TypeScript | Component-driven, strictly typed, deployed globally via CDN. |
## 3. Caching Strategies (Redis)
In high-scale applications, choosing the right caching pattern per entity is critical for performance and consistency:
- **Cache-Aside & Invalidation:** For Profiles. Flow: `App checks Cache` → `Miss? Query DB & Update Cache`. On Update: `Update DB` → `Delete Cache` → `Next Read queries DB & rebuilds Cache`.
- **Write-Through:** Used for **Appointment Slots & Auth Tokens**. Writes happen to PostgreSQL and Redis simultaneously. Uses **Redis Distributed Locks** during booking to strictly prevent double-booking race conditions.
- **Read-Through:** Used for **Search Results**. The app queries the Cache directly, which transparently fetches from Elasticsearch if missing.
- **Write-Behind (Write-Back):** Used for **Analytics & View Counts**. Writes happen to Redis first and are asynchronously flushed to ClickHouse in batches to handle extreme write velocity.

## 4. CQRS (Command Query Responsibility Segregation) Pattern
In a high-scale healthcare platform, querying complex relationships (like Geospatial Doctor Search) on the primary transactional database (PostgreSQL) is a massive bottleneck. We solve this using **CQRS**:
- **Command (Write Model):** When a doctor updates their profile, the write happens on the **Doctor Service** (PostgreSQL). It then fires a `DoctorProfileUpdated` event to Kafka.
- **Query (Read Model):** A background consumer listens to this event and updates **Elasticsearch** (Search Service). All user searches (Read queries) hit Elasticsearch directly, never touching the primary PostgreSQL database.

**Real-World Analogy:**
Imagine a Restaurant. The Kitchen (PostgreSQL) is where the heavy work of cooking (Writing) happens. The Menu Board (Elasticsearch) is what the customers read (Searching). 
When the Chef adds a new dish (Command/Write), they don't invite 100 customers into the busy kitchen to see what's available. Instead, they tell the Waiter (Kafka), who simply updates the Menu Board (Read Model). Now, 10,000 customers can search and read the Menu Board instantly without ever disturbing the Kitchen!

This strictly separates Write workloads from Read workloads, ensuring maximum performance.

## 5. Resiliency & Reliability Patterns

- **Circuit Breakers & Bulkhead Pattern:** `Resilience4j` isolates thread pools (Bulkhead) so a 100k SMS blast doesn't crash the Appointment Service CPU. Fault flow: `Retry` → `Circuit Breaker` → `Fallback` → `DLQ`.
- **Retry Policy (Exponential Backoff):** Network calls use progressive delays: `1s` → `2s` → `4s` → `8s`.
- **Transactional Outbox & Inbox Patterns:** Guarantees exactly-once processing via `Unit Of Work` or Transaction Manager.
- **Idempotent Consumer:** Uses `processed_events` table. Logic: `if processed_event_id exists: ignore`.
- **Dead Letter Queues (DLQ):** If a Kafka consumer fails endlessly, the event is routed to DLQ instead of being lost.
- **Graceful Shutdown:** On `SIGTERM`, consumers stop polling → finish processing → commit offset → shutdown safely.

### Distributed Transactions: Saga Pattern
In a microservices architecture, there are no central database transactions (ACID). We use the **Saga Pattern** to handle distributed transactions and rollbacks (Compensating Transactions). We will primarily use **Choreography** (Event-driven via Kafka) as used by Amazon and Uber.

**Example Scenario (Booking Flow Rollback):**
1. **Appointment Service** creates a "Pending" appointment and publishes `AppointmentCreated`.
2. **Payment Service** listens, tries to process payment, but it **Fails**. It publishes `PaymentFailed`.
3. **Appointment Service** listens to `PaymentFailed` and executes a rollback: changes status to `CANCELLED`.
4. **Calendar Service** & **Video Room Service** listen and delete the reserved slots/rooms.
5. **Notification Service** sends an SMS to the user: "Booking failed due to payment issue."

This ensures the system remains eventually consistent across all independent services without using strict database locks.

## 6. Software Engineering & SOLID Principles

### API Gateway & Edge Protection
- **Rate Limiting (Redis):** The API Gateway enforces strict limits (e.g., 100 req/min) per user IP to protect against DDoS attacks.
- **Idempotency-Key (Stripe Pattern):** Critical `POST` APIs (like `/appointments`) require an `Idempotency-Key` header. If a network retry occurs, the API Gateway/Service recognizes the key and prevents duplicate operations (e.g., creating two appointments).

### Observability & Monitoring
- **Distributed Tracing (OpenTelemetry):** Full Trace Propagation: `Gateway (Generates TraceID)` → `HTTP Header` → `Service` → `Kafka Header` → `Consumer` → `Database/Response`. If a request is slow, the exact bottleneck (e.g., Kafka lag or slow SQL) is instantly visible.
- **Metrics (Prometheus & Grafana):** Every service exports metrics. Grafana dashboards monitor CPU, Memory, API Latency, Kafka Lag, DB Connections, and Error Rates in real-time.

### Code-Level Design (SOLID)
- **Single Responsibility Principle (SRP):** Each microservice has exactly one domain boundary.
- **Open/Closed Principle (OCP):** External integrations use Interfaces (e.g., `NotificationProvider`).
- **Interface Segregation Principle (ISP):** Separate `IAppointmentReadRepository` and `IAppointmentWriteRepository`.
- **Dependency Inversion Principle (DIP) & Repository Pattern:** High-level business logic (Services) must never depend directly on low-level databases (e.g., PostgreSQL). 
  - **Right Flow:** `Controller` → `Application Service` → `Domain Service` → `IAppointmentRepository` ← `PostgresRepository`

### Domain-Driven Design (DDD) & Clean Architecture
- **Aggregate Roots:** The system is modeled around Aggregates (e.g., `Appointment` is the root containing `Prescription` and `FollowUp`).
- **Value Objects:** Primitives (like `string email`) are wrapped in Value Objects (e.g., `EmailAddress`, `PhoneNumber`) to centralize validation.
- **Domain Events:** Instead of firing Kafka events directly, the service yields `Domain Events` which are intercepted by the `Unit Of Work` and written to the `Outbox` table.

### Clean Architecture: Event-Driven Layering
- **Wrong Flow:** Kafka → `AppointmentService`
- **Right Flow:** Kafka → `AppointmentConsumer` (Transport Layer) → `AppointmentService` (Business Logic) → `IAppointmentRepository` (Data Access).

### Microservices Best Practices
- **Feature Flags:** Uses `LaunchDarkly/Unleash` to toggle features instantly in production without redeployments.
- **Pagination Standard:** All list APIs use **Cursor Pagination** (`cursor`, `limit`) instead of `page`/`limit` (Uber/Meta standard).
- **Soft Delete:** Never use `DELETE` queries. Use `deleted_at` and `is_deleted` flags to retain data.
- **Optimistic Locking:** Critical tables (`appointments`) use a `version` field (`UPDATE ... WHERE version=X`) to prevent race conditions.
- **Health Checks:** Every service exposes `/health`, `/readiness`, and `/liveness` endpoints for Kubernetes probes.

### Kafka Best Practices
- **Topic Naming Convention:** Domain-driven naming: `appointment.created.v1`, `doctor.updated.v1`.
- **Event Versioning:** Events evolve without breaking consumers (e.g., `AppointmentCreatedV1` → `AppointmentCreatedV2` with a `version` field in the payload).
- **Partition Keys:** Maintain strict Event Ordering using Aggregate IDs (e.g., `appointment_id` or `patient_id` as the Partition Key).


## 7. Proposed Project Structure (Multi-repo GitOps Approach)

At this scale, code is managed via strict Multi-repo structures, with CI/CD driven by GitOps (e.g., ArgoCD).

```
# Infrastructure (GitOps Repo)
arogyam-infra/                  
├── terraform/                  # IaC for AWS/GCP (VPC, EKS, RDS)
├── kubernetes/                 # Helm charts, Istio configs, ArgoCD manifests

# Core Microservices (Independent Repositories)
arogyam-api-gateway/            # Kong custom plugins
arogyam-auth-service/           # Python FastAPI + gRPC
arogyam-patient-service/        # Java Spring Boot + gRPC
arogyam-doctor-service/         # Java Spring Boot + gRPC
arogyam-appointment-service/    # Python FastAPI + gRPC
arogyam-billing-service/        # Java Spring Boot
arogyam-search-service/         # Go + gRPC
arogyam-health-record-service/  # Java Spring Boot
arogyam-pharmacy-service/       # Node.js
arogyam-admin-service/          # Python FastAPI
arogyam-storage-service/        # Go
arogyam-audit-service/          # Go + Kafka Consumer

# Async / Edge Services
arogyam-notification-service/   # Node.js (Kafka Consumer)
arogyam-messaging-service/      # Node.js / Go (WebSockets)
arogyam-video-call-service/     # Node.js (Socket.io)
arogyam-ai-analysis-service/    # Python (GPU workloads)

# Shared Libraries
arogyam-proto-registry/         # Central repository for all .proto (gRPC) definitions

# Frontend Applications (Deployed to CDN)
arogyam-patient-portal/         # ReactJS (Vite)
arogyam-doctor-portal/          # ReactJS (Vite)
arogyam-admin-portal/           # ReactJS (Vite)
```

## 5. Frontend Features & UI Layout

*(Deployed globally via CDN. State management via Redux/Zustand. Communicates with backend via BFF/API Gateway.)*

### Global Navigation (`Navbar.tsx`)
- **Left Side**: Application Logo and Brand Name.
- **Right Side (Desktop)**: Navigation Links and User Dropdown Menus.
- **Mobile Layout**: Hamburger icon on the right, which opens a vertically stacked list of all navigation items.
- **Patient Role**: Dashboard, Appointments, Find Doctors | Medical Records, Health Reports, Prescriptions | My Profile, Sign Out.
- **Doctor Role**: Dashboard, Profile, Prescriptions | My Profile, Sign Out.

### Auth Pages (`/login` & `/register`)
- **Login Page (`/login`)**:
  - Two horizontal toggle buttons: "Email Login" and "OTP Login".
  - **Email Login View**: Email field, Password field (with toggleable Eye icon), "Forgot your password?" link, "Sign In" button.
  - **OTP Login View**: Phone Number field, "Send OTP" button, OTP input field (6 digits), "Verify OTP & Sign In" button.
- **Register Page (`/register`)**:
  - Multi-step form with continuous progress bar and Step Indicator ("Personal", "Address", "Identity", "Security").
  - **Patient Fields**: Title, Full Name, DOB, Gender, Email, Country, Phone, Address, City, State, PIN, National ID Type, National ID Number, Password.
  - **Doctor Fields**: Patient fields + Medical Registration ID, Specialties, Clinic Name, Years of Experience, Clinic Address, Consultation Fee.
  - **Summary Box**: Displays collected data for final review before submission.

### Landing Page (`/`)
- **Hero Section**: Main title, subtitle, context-aware CTA buttons.
- **Features Grid**: 4-column layout for "Easy Appointment Booking", "AI Search", "Secure Records", "Real-Time Tracking".
- **Stats Row**: 4-column banner for key metrics.
- **Testimonials Section**: 3-column grid of review cards.
- **Bottom CTA**: "Register as Patient" / "Register as Doctor" cards and platform guarantees.

### Dashboards (`/patient/dashboard` & `/doctor/dashboard`)
1. **Welcome Section (Top Full-Width)**: Date, greeting, verification badges.
2. **Statistics Overview**: 4-column horizontal row of data cards (Value + Trend).
3. **Main Body Split**:
    - **Left Column (2/3 Width - Recent Activity)**: Recent Appointments (Status, Time, Queue Position) and Recent Health Reports (Patients only).
    - **Right Column (1/3 Width - Quick Actions)**: Vertical list of large action buttons and Health Tips.

### Other Page Layouts
- **Appointments (`/appointments`)**: List/Calendar view toggles, Upcoming/Past tabs, Appointment Cards with quick actions (Video Call, Prescription), and Queue Tracker sidebar.
- **Video Call Interface (`/video-call`)**: Main remote video feed, PiP local feed, bottom control bar. Right sidebar with "Chat" and "Info" tabs.
- **Find Doctors (`/find-doctors`)**: AI Assistant symptom input at top. Filter bar (Search, Specialty, Location). Results grid of Doctor cards.
- **Health Reports (`/health-reports`)**: Full-width trend chart. Filter bar. Grid of test results with Normal/Critical badges.
- **Medical Records (`/medical-records`)**: Filter bar with Results Summary. List view of historical records and attached files.
- **Prescriptions (`/prescriptions`)**: Creation form (Doctors only). Filter bar. List cards with "Download PDF" capability.
- **Profile Page (`/profile`)**: Left sidebar (Avatar, Contact info, Quick Actions). Right main content (Personal Info, Professional Details, KYC fields).

### Admin Dashboard Planning & Future Scope (`/admin/dashboard`)
- **Layout**: "Dashboard", "Verifications", "Users" in Navbar. Top Overview metric cards. Main list/table of unverified doctors.
- **Doctor Verification Component**: Displays Name, Registration ID, Aadhaar. Features a "Verify via API" action button.
- **Future Scope (Production)**: "Verify via API" will integrate with Third-Party KYC services (Setu/Zoop) for automated government database validation.

## 8. Execution Plan (MAANG Step-by-Step)

### Infrastructure Setup
- Define all `.proto` files in the central registry for gRPC contracts.
- Scaffold independent repositories with CI pipelines to enforce unit tests and linting.

### Application Verification
- Conduct load testing (e.g., k6/JMeter) on the API Gateway.
- Simulate service failures (Chaos Engineering) to verify Circuit Breakers and DLQ routing.
