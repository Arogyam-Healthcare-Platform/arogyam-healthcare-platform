# 🚀 Arogyam Healthcare Platform (Enterprise FAANG-Scale Microservices Architecture)

> **Arogyam** (আরোগ্যম) is a multi-tenant, enterprise-grade digital healthcare platform built with a **Polyglot Microservices Architecture** (Java Spring Boot 3, Python FastAPI, Go, Node.js, and React).
> 
> Designed to handle high-concurrency patient consultation booking, AI-assisted symptom diagnosis, WebRTC telemedicine video calls, digital prescriptions, and immutable HIPAA-compliant audit logging.

---

## 🏗️ System Architecture & Service Registry

The platform consists of **17 independent repositories** under the [Arogyam Healthcare Platform GitHub Organization](https://github.com/Arogyam-Healthcare-Platform):

```
                               ┌────────────────────────────────────────┐
                               │     Kong API Gateway (Port 8000)       │
                               │  - Auth Interceptor & JWT Validation   │
                               │  - Rate Limiting (100 req/min per IP)  │
                               └──────────────────┬─────────────────────┘
                                                  │
         ┌────────────────────────────────────────┼────────────────────────────────────────┐
         │                                        │                                        │
┌────────▼─────────┐                   ┌──────────▼────────┐                   ┌──────────▼────────┐
│  Patient Portal  │                   │   Doctor Portal   │                   │    Admin Portal   │
│   (React :3000)  │                   │   (React :3001)   │                   │   (React :3002)   │
└──────────────────┘                   └───────────────────┘                   └───────────────────┘
         │                                        │                                        │
         └────────────────────────────────────────┼────────────────────────────────────────┘
                                                  │
 ┌──────────────────┬──────────────────┬──────────┴───────┬──────────────────┬──────────────────┐
 │                  │                  │                  │                  │                  │
┌▼──────────────┐  ┌▼──────────────┐  ┌▼──────────────┐  ┌▼──────────────┐  ┌▼──────────────┐  ┌▼──────────────┐
│  Auth Service │  │Patient Service│  │Doctor Service │  │ Appointment   │  │  Search DB   │  │  AI Service   │
│(FastAPI :8005)│  │ (Spring :8002)│  │ (Spring :8003)│  │ (FastAPI:8004)│  │  (Go :8006)   │  │(FastAPI :8014)│
└───────────────┘  └───────────────┘  └───────────────┘  └───────────────┘  └───────────────┘  └───────────────┘
```

---

## 📚 Complete Microservice Registry & Explanation (For Beginners)

### 🌐 Frontend Portals
| Portal Name | Tech Stack | Port | GitHub Repository | Description (সহজ বাংলায়) |
|---|---|---|---|---|
| **Patient Portal** | React 18 + Vite + Tailwind | `:3000` | [arogyam-patient-portal](https://github.com/Arogyam-Healthcare-Platform/arogyam-patient-portal) | রোগীদের জন্য বুকিং, AI ডাক্তার সার্চ, মেডিকেল রিপোর্ট ও WebRTC ভিডিও কল পোর্টাল। |
| **Doctor Portal** | React 18 + Vite + Tailwind | `:3001` | [arogyam-doctor-portal](https://github.com/Arogyam-Healthcare-Platform/arogyam-doctor-portal) | ডাক্তারদের জন্য লাইভ OPD কিউ, ডিজিটাল প্রেসক্রিপশন এবং উপার্জন দেখার পোর্টাল। |
| **Admin Portal** | React 18 + Vite + Tailwind | `:3002` | [arogyam-admin-portal](https://github.com/Arogyam-Healthcare-Platform/arogyam-admin-portal) | প্ল্যাটফর্ম এডমিনদের জন্য ডাক্তারদের লাইসেন্স (KYC) ভেরিফিকেশন ও অডিট ভিউয়ার। |

---

### ⚙️ Core Backend Microservices
| Microservice Name | Language / Framework | Port | Primary DB / Storage | GitHub Repository | Description (সহজ বাংলায়) |
|---|---|---|---|---|---|
| **API Gateway** | Kong Gateway | `:8000` | Redis Cache | [arogyam-api-gateway](https://github.com/Arogyam-Healthcare-Platform/arogyam-api-gateway) | সব বাইরের রিকোয়েস্টের সেন্ট্রাল এন্ট্রি পয়েন্ট। Auth, CORS ও Rate Limiting হ্যান্ডেল করে। |
| **Auth Service** | Python FastAPI | `:8005` | PostgreSQL | [arogyam-auth-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-auth-service) | ইউজার সাইনআপ, লগইন, JWT Access/Refresh Token ইস্যু এবং gRPC ভ্যালিডেশন করে। |
| **Patient Service** | Java Spring Boot 3 | `:8002` | PostgreSQL | [arogyam-patient-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-patient-service) | রোগী প্রোফাইল ও ফ্যামিলি ডিপেন্ডেন্ট একাউন্ট ম্যানেজ করে। |
| **Doctor Service** | Java Spring Boot 3 | `:8003` | PostgreSQL | [arogyam-doctor-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-doctor-service) | ডাক্তার প্রোফাইল, ফি, অভিজ্ঞতা ও চেম্বার শিডিউলিং সেভ করে। |
| **Appointment Service** | Python FastAPI | `:8004` | PostgreSQL + Redis Lock | [arogyam-appointment-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-appointment-service) | রেস-কন্ডিশন মুক্ত অ্যাপয়েন্টমেন্ট বুকিং ও Saga Orchestration পরিচালনা করে। |
| **Search Service** | Go (Gin) | `:8006` | Elasticsearch | [arogyam-search-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-search-service) | CQRS রিড মডেল ব্যবহার করে ১ms-এর নিচে দ্রুত ডাক্তার সার্চ করে। |
| **Health Record Service** | Java Spring Boot 3 | `:8008` | PostgreSQL | [arogyam-health-record-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-health-record-service) | ডিজিটাল প্রেসক্রিপশন, ল্যাব রিপোর্ট ও মেডিকেল রেকর্ড সেভ করে। |
| **Billing Service** | Java Spring Boot 3 | `:8009` | PostgreSQL | [arogyam-billing-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-billing-service) | অ্যাপয়েন্টমেন্ট ইনভয়েস ও পেমেন্ট হিস্ট্রি ম্যানেজ করে। |
| **Messaging Service** | Node.js (Express) | `:8010` | Cassandra DB | [arogyam-messaging-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-messaging-service) | রোগী-ডাক্তার লাইভ চ্যাটের জন্য ক্যাসান্ড্রা ডাটাবেস ও ওয়েবসংকেত ব্যবহার করে। |
| **Admin Service** | Python FastAPI | `:8011` | PostgreSQL | [arogyam-admin-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-admin-service) | ডাক্তার ভেরিফিকেশন (KYC) অনুমোদন বা রিজেক্টের ব্যাকএন্ড লজিক চালায়। |
| **Video Call Service** | Node.js (Express) | `:8012` | Redis | [arogyam-video-call-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-video-call-service) | WebRTC Telemedicine-এর জন্য STUN/TURN ও Signaling WebSocket চালায়। |
| **Audit Service** | Go (Gin) | `:8013` | PostgreSQL Partitioned | [arogyam-audit-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-audit-service) | HIPAA আইন মেনে অপরিবর্তনীয় (INSERT-ONLY) অডিট ট্রেইল সেভ করে। |
| **AI Analysis Service** | Python FastAPI | `:8014` | Elasticsearch | [arogyam-ai-analysis-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-ai-analysis-service) | সাধারণ ভাষায় লেখা উপসর্গ এনালাইসিস করে ডাক্তারের পরামর্শ দেয়। |
| **Notification Service** | Node.js | `:8007` | Kafka Consumer | [arogyam-notification-service](https://github.com/Arogyam-Healthcare-Platform/arogyam-notification-service) | কাফকা ইভেন্ট শুনে ইউজারকে SMS, Email ও Push Notification পাঠায়। |

---

## 🔄 End-to-End Request Flow (How the Platform Works)

### 1. Patient Signs Up & Logs In
- Patient opens `http://localhost:3000/login`.
- Input credentials sent to `http://localhost:8000/api/v1/auth/login`.
- **Kong Gateway** forwards request to `arogyam-auth-service`.
- `auth-service` verifies credentials and returns `{ access_token, refresh_token }`.

### 2. Patient Uses AI Symptom Search
- Patient enters `"severe headache and blurry vision"` in `/find-doctors`.
- Request routed to `arogyam-ai-analysis-service` (`:8014`).
- AI classifies urgency as `HIGH` and maps specialty to `Neurology`.
- `arogyam-search-service` queries **Elasticsearch** in <1ms and returns matching doctors.

### 3. Patient Books Appointment (Preventing Double Booking)
- Request sent to `arogyam-appointment-service` (`:8004`).
- Service acquires **Redis Distributed Lock (`SETNX`)** on the doctor slot ID.
- First request succeeds and writes to **PostgreSQL** (`appointments` table with `version` optimistic locking).
- Emits `appointment.created.v1` event to **Apache Kafka**.

### 4. Background Asynchronous Processing via Kafka
- `arogyam-billing-service` consumes Kafka event -> Creates Invoice.
- `arogyam-notification-service` consumes Kafka event -> Sends SMS alert to patient & doctor.
- `arogyam-audit-service` consumes Kafka event -> Logs immutable event into PostgreSQL.

### 5. Telemedicine WebRTC Video Consultation
- Patient opens `http://localhost:3000/video-call?appointment=xyz`.
- Doctor opens `http://localhost:3001/video-call?appointment=xyz`.
- Both fetch STUN/TURN ICE configs from `arogyam-video-call-service` (`:8012`).
- WebSocket signaling exchanges SDP Offer/Answer -> Direct Peer-to-Peer encrypted video call established!

---

## 🚀 How to Run the Entire Platform Locally

### Prerequisites
- [Docker Desktop](https://www.docker.com/) installed with WSL2 backend.
- Minimum 8 GB RAM available.

### One-Command Setup
```bash
# 1. Clone main repo
git clone https://github.com/Arogyam-Healthcare-Platform/arogyam-healthcare-platform.git
cd arogyam-healthcare-platform

# 2. Build and start all 23 containers (14 microservices + 3 portals + Kafka, Redis, Postgres, ES, Cassandra)
docker compose up -d --build

# 3. Verify running containers
docker ps
```

### Access Points
- **Patient Portal**: `http://localhost:3000`
- **Doctor Portal**: `http://localhost:3001`
- **Admin Portal**: `http://localhost:3002`
- **API Gateway**: `http://localhost:8000/api/v1`

---

## 📘 System Design & Interview Preparation Docs

Detailed architecture notes and interview scripts are available in the [`docs/`](./docs) folder:
- [HLD System Architecture (English)](./docs/HLD_System_Architecture.md)
- [HLD System Architecture (বাংলা ভার্সন)](./docs/HLD_System_Architecture_BN.md)
- [System Design Master Interview Notes](./docs/Notes.md)
- [Master System Design Prep Guide](./docs/system_design_interview_prep.md)

---

## 📜 License & Author

Developed with ❤️ for enterprise-scale healthcare engineering.
