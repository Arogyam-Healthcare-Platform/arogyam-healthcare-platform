# আরোগ্যম হেলথকেয়ার প্ল্যাটফর্ম এন্টারপ্রাইজ আর্কিটেকচার (FAANG-Scale)

এই ডকুমেন্টটিতে আরোগ্যম (Arogyam) হেলথকেয়ার প্ল্যাটফর্মের এন্টারপ্রাইজ-গ্রেড আর্কিটেকচার এবং প্রজেক্ট স্ট্রাকচার তুলে ধরা হয়েছে। গুগল এবং মাইক্রোসফটের মতো টেক জায়ান্টদের স্কেলে কাজ করার নীতি অনুসরণে তৈরি এই আর্কিটেকচারে হাই অ্যাভেইল্যাবিলিটি, জিরো-ট্রাস্ট সিকিউরিটি, ট্র্যাকিং/অবজারভেবিলিটি এবং রেজিলিয়েন্ট মাইক্রোসার্ভিসেস নিশ্চিত করা হয়েছে।

---

## ১. ডোমেন-ড্রাইভেন মাইক্রোসার্ভিসেস আর্কিটেকচার (Domain-Driven Microservices)

গ্লোবাল স্কেলিং এবং প্রতিটি মডিউলের স্বাধীন পরিচালনা নিশ্চিত করতে সিস্টেমটিকে ডিকাপল্ড ও স্বাধীনভাবে ডিপ্লয়যোগ্য মাইক্রোসার্ভিসে বিভক্ত করা হয়েছে।

### 🔹 মূল ডোমেন সার্ভিসেস (Core Domain Services)
1. **Identity & Auth Service:** সেন্ট্রালাইজড IAM, OAuth2/OIDC, JWT জেনারেশন এবং Role-Based Access Control (RBAC)।
2. **Patient Service:** রোগীদের প্রোফাইল এবং ফ্যামিলি মেম্বারদের ডিপেন্ডেন্ট একাউন্ট পরিচালনা করে।
3. **Doctor Service:** ডাক্তারের প্রোফাইল, চেম্বার শিডিউলিং এবং জিও-লোকেশন টার্গেটিং হ্যান্ডেল করে।
4. **Appointment Service (CQRS প্রয়োগকৃত):** বুকিংয়ের জটিল স্টেট মেশিন পরিচালনা করে (ইন-পার্সন ভিজিট ও ভিডিও কল)। রাইট অপারেশন বুকিং লজিক হ্যান্ডেল করে; রিড রেপ্লিকা ভারী ড্যাশবোর্ড ক্যোয়ারি সামলায়।
5. **Health Record Service:** মেডিকেল হিস্ট্রির জন্য নিরাপদ ও ইমিউটেবল রেকর্ড (ব্লকচেইন হুক সহ), পরিধানযোগ্য ডিভাইসের (IoT Sync) তথ্য সমন্বয় করে।
6. **Pharmacy Service:** ডিজিটাল ই-প্রেসক্রিপশন তৈরি, ডিজিটাল সাইনিং এবং ডেলিভারি রাউটিং হ্যান্ডেল করে।

### 🔹 সাপোর্টিং ও এজ সার্ভিসেস (Supporting & Edge Services)
7. **API Gateway (Kubernetes Ingress Flow):** ফ্লো: `Gateway` → `Ingress Controller` → `Service` → `Pods`। মিডলওয়্যার চেইন: `Authentication` → `Authorization` → `Rate Limiting` → `Validation` → `Logging` → `Tracing` → `Forward`।
8. **Search Service (CQRS):** ১ মিলিসেকেন্ডের কম সময়ে রেজাল্ট পাওয়ার জন্য ইলাস্টিকসার্চ ক্লাস্টার। *CQRS ফ্লো:* `Command (Doctor Update)` → `Kafka` → `Projection (Sync Consumer)` → `Read DB (Elasticsearch)`।
9. **AI Recommendation Service:** `RecommendationEngine` ইন্টারফেসের মাধ্যমে কাজ করে। সার্ভিস কন্ট্রাক্ট না বদলেই লজিককে `RuleBased`, `MLBased` বা `LLMBased` মডেলে সোয়াপ করা যায়।
10. **Notification Service (Strategy Pattern):** কাফকা-চালিত কনসিউমার। Open/Closed Principle (OCP) মেনে `NotificationProvider` ইন্টারফেসের মাধ্যমে ডাইনামিকালি `EmailProvider`, `SMSProvider`, `WhatsAppProvider`, বা `PushProvider`-এ মেসেজ রাউট করে।
11. **Messaging Service:** লাইভ চ্যাটের জন্য Redis Pub/Sub দ্বারা পরিচালিত WebSocket ক্লাস্টার।
12. **Video Call Signaling Service:** পিয়ার-টু-পিয়ার (P2P) মিডিয়া রাউটিংয়ের জন্য STUN/TURN সার্ভার ও Signaling Server সহ WebRTC প্রোটোকল।
13. **Queue Management Service:** Redis ব্যবহার করে লাইভ অপেক্ষার সময় হিসাব করে।
14. **Admin Service (RBAC):** ভেরিফিকেশন পরিচালনা করে। পারমিশন মডেল: `Super Admin`, `Doctor Admin`, `Hospital Admin`, `Support`, `Auditor`।
15. **Storage Service & CDN:** `AWS S3/Azure Blob` পরিচালনা করে। গ্লোবাল রিড স্পিড বাড়াতে `CloudFront/Cloudflare CDN` ব্যবহৃত হয় (যেমন: রিমোট ডাক্তারদের জন্য দ্রুত MRI ডাউনলোড)।
16. **Audit Service (Immutable):** কঠোর HIPAA আইন মেনে চলে। প্রতিটি কাজ অপরিবর্তনীয়ভাবে জমা থাকে (INSERT ONLY)। ডাটাবেস লেভেলে UPDATE এবং DELETE সম্পূর্ণ বন্ধ।
17. **Analytics Service (OLAP):** ClickHouse বা BigQuery ব্যবহার করে (OLTP PostgreSQL নয়)। উচ্চগতির ডাটা এনালাইসিসের জন্য ফ্লো: `Kafka` → `ClickHouse` → `Grafana/Looker Dashboard`।
18. **Background Job Scheduler:** `Scheduler Service (Quartz/Celery)` → সময়ভিত্তিক ইভেন্ট ট্রিগার করে (যেমন: `Prescription Expiry`, `Appointment Reminder`)।

---

## ২. আর্কিটেকচার প্রযুক্তি স্ট্যাক (Architecture Tech Stack)

| লেয়ার / লেভেল | ব্যবহৃত প্রযুক্তি | এন্টারপ্রাইজ / FAANG যৌক্তিকতা |
| :--- | :--- | :--- |
| **Edge & API** | Kong Gateway, Cloudflare CDN | গ্লোবাল CDN ভারী অ্যাসেট (MRI) ক্যাশ করে। এপিআই গেটওয়ে ট্রাফিক সিকিউর করে। |
| **Compute & Network**| Kubernetes (EKS/GKE) | `Service Discovery` ডাইনামিক Pod IP সমাধান করে। ডিপ্লয়মেন্টে `Blue-Green` বা `Canary` ব্যবহৃত হয়। CPU/Memory এবং **Kafka Lag**-এর ওপর নির্ভর করে `Horizontal Pod Autoscaler (HPA)` স্কেল করে। |
| **Sync Comm.** | gRPC (Protobuf), REST (OpenAPI) | অভ্যন্তরীণ যোগাযোগের জন্য gRPC। বহিরাগত রিকোয়েস্টে strictly `Contract First` (Swagger/OpenAPI) ডিজাইন সহ REST। |
| **Async Comm.** | Kafka Cluster (RF=3) + Schema Registry | `Producer` → `Avro` → `Schema Registry` → `Kafka`। কঠোর ইভেন্ট স্কিমা এনফোর্স করে। ভারী কাজের জন্য অ্যাসিঙ্ক প্রসেসিং। |
| **Primary DBs** | PostgreSQL (OLTP) + Flyway | রিড স্কেলেবিলিটির জন্য Primary → Replica আর্কিটেকচার। স্কিমা মাইগ্রেশনের জন্য `Flyway/Liquibase`। |
| **Analytics DBs** | ClickHouse / BigQuery (OLAP)| কলামনার স্টোরেজ, যা শত কোটি রো এবং ভারী এগ্রিগেশনের জন্য ডিজাইন করা। |
| **NoSQL / Cache** | Redis Cluster, Cassandra | হাই অ্যাভেইল্যাবিলিটির জন্য `Redis Cluster/Sentinel`। চ্যাট স্টোরেজের জন্য Cassandra। |
| **Observability** | OpenTelemetry, Prometheus, Grafana | ট্র্যাকিং ফ্লো: `OTel` → `Jaeger` → `Grafana`। দ্রুত ইনডেক্সিংয়ের জন্য **Structured JSON Logs** ব্যবহৃত হয়। |
| **Security & Config**| HashiCorp Vault, Spring Cloud Config| সার্ভিসগুলোর মাঝে `mTLS` এনক্রিপশন। `JWT/Key Rotation`, `OWASP` কম্প্লায়েন্স। সেন্ট্রালাইজড কনফিগারেশন সার্ভিস হার্ডকোডেড URL প্রতিরোধ করে। PII ফিল্ড-লেভেল এনক্রিপশন। |
| **Frontend** | React (Vite), TypeScript | কম্পোনেন্ট-ড্রাইভেন, স্ট্রংলি টাইপড, CDN-এর মাধ্যমে গ্লোবালি ডিপ্লয়কৃত। |

---

## ৩. ক্যাশিং স্ট্র্যাটেজি (Redis Caching Strategies)

পারফর্ম্যান্স ও ডাটা সামঞ্জস্য বজায় রাখতে ৪ ধরনের ক্যাশিং স্ট্র্যাটেজি ব্যবহার করা হয়েছে:
- **Cache-Aside & Invalidation:** প্রোফাইলের জন্য। ফ্লো: `App আগে Cache দেখে` → `Cache Miss? DB থেকে এনে Cache আপডেট করে`। প্রোফাইল আপডেট হলে: `DB আপডেট` → `Cache ডিলিট` → `পরবর্তী রিড DB থেকে এনে ক্যাশ রিবিল্ড করে`।
- **Write-Through:** **অ্যাপয়েন্টমেন্ট স্লট ও টোকেনের জন্য**। একই সাথে PostgreSQL এবং Redis-এ ডাটা রাইট করা হয়। ডাবল বুকিং রেস কন্ডিশন ঠেকানোর জন্য বুকিংয়ের সময় **Redis Distributed Lock** ব্যবহার করা হয়।
- **Read-Through:** **সার্চ রেজাল্টের জন্য**। অ্যাপ সরাসরি ক্যাশ ক্যোয়ারি করে, ক্যাশ প্রয়োজন অনুযায়ী ইলাস্টিকসার্চ থেকে ডাটা এনে দেয়।
- **Write-Behind (Write-Back):** **এনালাইটিক্স ও ভিউ কাউন্টের জন্য**। রাইটগুলো আগে Redis-এ জমানো হয় এবং পরে ব্যাচ আকারে ClickHouse ডাটাবেসে সেভ করা হয়।

---

## ৪. CQRS প্যাটার্ন (Command Query Responsibility Segregation)

মূল ট্রানজ্যাকশনাল ডাটাবেসে (PostgreSQL) ভৌগোলিক ডাক্তার সার্চের মতো জটিল ক্যোয়ারি করলে ডাটাবেস স্লো হয়ে যায়। আমরা **CQRS** দিয়ে এটি সমাধান করেছি:
- **Command (Write Model):** ডাক্তার প্রোফাইল আপডেট করলে তা **Doctor Service (PostgreSQL)**-এ সেভ হয় এবং কাফকা-তে `DoctorProfileUpdated` ইভেন্ট ফায়ার করে।
- **Query (Read Model):** ব্যাকগ্রাউন্ড কনসিউমার এই ইভেন্ট শুনে **Elasticsearch** আপডেট করে। ইউজারের সব সার্চ সরাসরি Elasticsearch থেকে হয়, মূল PostgreSQL ডাটাবেসকে স্পর্শও করে না।

> 🍳 **বাস্তব জীবনের উদাহরণ:** 
> রেস্টুরেন্টের কথা চিন্তা করুন। রান্নাঘর (PostgreSQL) হলো যেখানে রান্নার ভারী কাজ (Writing) হয়। আর দেয়ালের মেনু বোর্ড (Elasticsearch) দেখে কাস্টমাররা খাবার খোঁজে (Searching)। 
> শেফ নতুন খাবার তৈরি করলে (Command/Write) ১০০ জন কাস্টমারকে কিচেনে ডেকে দেখান না। তিনি পিয়নকে (Kafka) বলেন, যে দেয়ালের মেনু বোর্ড (Read Model) আপডেট করে দেয়। এখন ১০,০০০ কাস্টমার কিচেনে ঝামেলা না করেই মেনু বোর্ড দেখে খাবার অর্ডার দিতে পারে!

---

## ৫. রেজিলিয়েন্সি ও রিলায়াবিলিটি প্যাটার্নস (Resiliency Patterns)

- **Circuit Breakers & Bulkhead Pattern:** `Resilience4j` থ্রেড পুল আইসোলেট করে যাতে ১ লাখ SMS পাঠাতে গিয়ে অ্যাপয়েন্টমেন্ট সার্ভিসের CPU ক্র্যাশ না করে। ফেইলিয়ার ফ্লো: `Retry` → `Circuit Breaker` → `Fallback` → `DLQ`।
- **Retry Policy (Exponential Backoff):** নেটওয়ার্ক কলগুলোতে প্রোগ্রেসিভ ডিলে দেওয়া হয়: `1s` → `2s` → `4s` → `8s`।
- **Transactional Outbox & Inbox Patterns:** `Unit Of Work` এর মাধ্যমে রিকোয়েস্টের এক্সাক্টলি-ওয়ান্স (Exactly-Once) প্রসেসিং নিশ্চিত করে।
- **Idempotent Consumer:** `processed_events` টেবিল ব্যবহার করে। লজিক: `if processed_event_id exists: ignore`।
- **Dead Letter Queues (DLQ):** কাফকা কনসিউমার বার বার ব্যর্থ হলে ইভেন্টটি হারিয়ে না গিয়ে DLQ-তে জমা হয়।
- **Graceful Shutdown:** `SIGTERM` সিগন্যালে কনসিউমাররা নতুন রিকোয়েস্ট নেওয়া বন্ধ করে প্রসেসিং শেষ করে নিরাপদে শাটডাউন হয়।

### ডিস্ট্রিবিউটেড ট্রানজ্যাকশন: Saga Pattern
মাইক্রোসার্ভিসে কেন্দ্রীয় ডাটাবেস ACID ট্রানজ্যাকশন থাকে না। ডিস্ট্রিবিউটেড ট্রানজ্যাকশন ও রোলব্যাক (Compensating Transactions) সামলাতে আমরা **Saga Pattern** ব্যবহার করি। আমরা Amazon ও Uber-এর মতো **Choreography (Event-Driven via Kafka)** পদ্ধতি ব্যবহার করি।

**উদাহরণ দৃশ্যপট (বুকিং রোলব্যাক ফ্লো):**
1. **Appointment Service** একটি "Pending" অ্যাপয়েন্টমেন্ট তৈরি করে `AppointmentCreated` ইভেন্ট পাঠায়।
2. **Payment Service** ইভেন্ট শুনে পেমেন্ট প্রসেস করতে গিয়ে **ব্যর্থ (Fail)** হয় এবং `PaymentFailed` পাঠায়।
3. **Appointment Service** এই `PaymentFailed` শুনে রোলব্যাক চালায়: স্ট্যাটাস পাল্টে `CANCELLED` করে দেয়।
4. **Calendar Service** ও **Video Room Service** বুক করা স্লট ও রুম ডিলিট করে দেয়।
5. **Notification Service** ইউজারকে SMS পাঠায়: "পেমেন্ট সমস্যার কারণে বুকিং ক্যানসেল হয়েছে।"

---

## ৬. সফটওয়্যার ইঞ্জিনিয়ারিং ও SOLID প্রিন্সিপালস

### এপিআই গেটওয়ে ও এজ প্রোটেকশন (API Gateway Protection)
- **Rate Limiting (Redis):** DDoS হামলা ঠেকাতে এপিআই গেটওয়ে প্রতি ইউজারের IP ধরে কঠোর সীমা (যেমন: ১০০ রিকোয়েস্ট/মিনিট) এনফোর্স করে।
- **Idempotency-Key (Stripe Pattern):** গুরুত্বপূর্ণ `POST` এপিআই-তে (`/appointments`) `Idempotency-Key` হেডার লাগে। নেটওয়ার্ক রিট্রাই হলেও এটি ডুপ্লিকেট অপারেশন প্রতিরোধ করে।

### ট্র্যাকিং ও মনিটরিং (Observability)
- **Distributed Tracing (OpenTelemetry):** পূর্ণাঙ্গ ট্র্যাকিং ফ্লো: `Gateway (TraceID তৈরি করে)` → `HTTP Header` → `Service` → `Kafka Header` → `Consumer` → `Database/Response`। কোনো রিকোয়েস্ট স্লো হলে ল্যাগ সাথে সাথে দৃশ্যমান হয়।
- **Metrics (Prometheus & Grafana):** প্রতিটি সার্ভিস মেট্রিক্স এক্সপোর্ট করে। গ্রাফানা ড্যাশবোর্ড রিয়াল-টাইমে CPU, Memory, Latency, DB Connections মনিটর করে।

### কোড-লেভেল ডিজাইন (SOLID Principles)
- **Single Responsibility Principle (SRP):** প্রতিটি মাইক্রোসার্ভিসের একটি সুনির্দিষ্ট ডোমেন সীমানা রয়েছে।
- **Open/Closed Principle (OCP):** এক্সটার্নাল ইন্টিগ্রেশনে Interface ব্যবহৃত হয় (যেমন: `NotificationProvider`)।
- **Interface Segregation Principle (ISP):** আলাদা `IAppointmentReadRepository` এবং `IAppointmentWriteRepository` ব্যবহার।
- **Dependency Inversion Principle (DIP):** বিজনেস লজিক সরাসরি ডাটাবেসের ওপর নির্ভর করে না। 
  - *সঠিক ফ্লো:* `Controller` → `Application Service` → `Domain Service` → `IAppointmentRepository` ← `PostgresRepository`

### ডোমেন-ড্রাইভেন ডিজাইন (DDD) ও ক্লিন আর্কিটেকচার
- **Aggregate Roots:** সিস্টেমটি এগ্রিগেটের চারপাশে মডেল করা (যেমন: `Appointment` হলো রুট, যার ভেতর `Prescription` ও `FollowUp` থাকে)।
- **Value Objects:** বেসিক টাইপগুলোকে (যেমন `string email`) Value Object (`EmailAddress`, `PhoneNumber`) দিয়ে র‍্যাপ করা হয়।
- **Domain Events:** সরাসরি কাফকা ইভেন্ট ফায়ার না করে সার্ভিস `Domain Events` তৈরি করে যা `Outbox` টেবিলে সেভ হয়।

### মাইক্রোসার্ভিস বেস্ট প্র্যাকটিসেস
- **Feature Flags:** কোড ডিপ্লয় না করেই প্রোডাকশনে ফিচার অন/অফ করতে `Unleash/LaunchDarkly` ব্যবহার করা হয়।
- **Pagination Standard:** সব লিস্ট এপিআই-তে `page`/`limit`-এর বদলে **Cursor Pagination** (`cursor`, `limit`) ব্যবহৃত হয় (Uber/Meta স্ট্যান্ডার্ড)।
- **Soft Delete:** ডাটা কখনো ডিলিট করা হয় না, `deleted_at` ও `is_deleted` ফ্ল্যাগ ব্যবহৃত হয়।
- **Optimistic Locking:** টেবিলগুলোতে `version` কলাম (`UPDATE ... WHERE version=X`) দিয়ে রেস কন্ডিশন ঠেকানো হয়।
- **Health Checks:** Kubernetes Probe-এর জন্য প্রতিটি সার্ভিস `/health`, `/readiness`, এবং `/liveness` এন্ডপয়েন্ট এক্সপোজ করে।

---

## ৭. প্রজেক্ট ফোল্ডার স্ট্রাকচার (Multi-Repo GitOps Approach)

```
# Infrastructure (GitOps Repo)
arogyam-infra/                  # Terraform (AWS/GCP VPC, EKS) & Kubernetes Helm Charts

# Core Microservices (Independent Repositories)
arogyam-api-gateway/            # Kong Gateway Config
arogyam-auth-service/           # Python FastAPI + gRPC
arogyam-patient-service/        # Java Spring Boot + gRPC
arogyam-doctor-service/         # Java Spring Boot + gRPC
arogyam-appointment-service/    # Python FastAPI + gRPC
arogyam-billing-service/        # Java Spring Boot
arogyam-search-service/         # Go + gRPC + Elasticsearch
arogyam-health-record-service/  # Java Spring Boot
arogyam-pharmacy-service/       # Node.js
arogyam-admin-service/          # Python FastAPI
arogyam-storage-service/        # Go
arogyam-audit-service/          # Go + Kafka Consumer

# Async / Edge Services
arogyam-notification-service/   # Node.js (Kafka Consumer)
arogyam-messaging-service/      # Node.js / Go (WebSockets)
arogyam-video-call-service/     # Node.js (Socket.io WebRTC)
arogyam-ai-analysis-service/    # Python (AI Workloads)

# Shared Proto Registry
arogyam-proto-registry/         # Central repo for all .proto (gRPC) definitions

# Frontend Applications
arogyam-patient-portal/         # ReactJS (Vite)
arogyam-doctor-portal/          # ReactJS (Vite)
arogyam-admin-portal/           # ReactJS (Vite)
```

---

## ৮. ফ্রন্টএন্ড লেআউট ও ইউজার ইন্টারফেস (Frontend UI & Layout)

- **Landing Page (`/`):** Hero section, 4-column Features Grid, Stats Banner, Testimonials, CTA Buttons.
- **Auth Pages (`/login` & `/register`):** Email + Password এবং OTP Login toggle. Multi-step Register form.
- **Patient Dashboard (`/patient/dashboard`):** তারিখ, গ্রিটিং, স্ট্যাটাস কার্ড, আপকামিং অ্যাপয়েন্টমেন্ট ও ভিডিও কল বোতাম।
- **Doctor Dashboard (`/doctor/dashboard`):** লাইভ OPD কিউ, ডিজিটাল প্রেসক্রিপশন রাইটার এবং আর্নিংস সামারি।
- **Video Call Interface (`/video-call`):** WebRTC ফুল-স্ক্রিন ডার্ক রুম ইন্টারফেস (Mute, Camera, Screen Share, Call Timer)।
- **Admin Dashboard (`/admin/dashboard`):** Doctor KYC Verifications queue, Approve/Reject workflow, System Health Checks.
