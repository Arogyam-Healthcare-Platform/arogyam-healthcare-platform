# 📜 Arogyam Healthcare Platform - প্রজেক্ট এক্সিকিউশন ও ওয়ার্কফ্লো লগ

এই ডকুমেন্টে **Arogyam Healthcare Platform**-এর সমস্ত আর্কিটেকচারাল সিদ্ধান্ত, প্রজেক্টের ফোল্ডার স্ট্রাকচার, ডকার ইনফ্রাস্ট্রাকচার ডেসক্রিপশন, পর্যায়ক্রমিক অগ্রগতি (Step-by-Step Milestones), এবং প্রতিটি আপডেটের পুঙ্খানুপুঙ্খ রেকর্ড বাংলা ভাষায় সংরক্ষণ করা হয়েছে।

---

## 📌 ১. প্রজেক্ট ওভারভিউ ও আর্কিটেকচারাল ব্লুপ্রিন্ট (Project Overview)

* **Architecture Style:** Domain-Driven Event-Driven Microservices Architecture (FAANG Standard)
* **Microservices Count:** ১৮টি স্বাধীন ও ডিকাপল্ড মাইক্রোসার্ভিস
* **Primary Tech Stack:** Python (FastAPI), Java (Spring Boot), Go, Node.js, React (TypeScript + Vite)
* **Databases (Polyglot Persistence):** PostgreSQL 16 (৭টি আইসোলেটেড DB), Apache Cassandra, Elasticsearch + PostGIS, ClickHouse, Redis Cluster
* **Event Backbone:** Apache Kafka Cluster + Schema Registry
* **Edge Proxy:** Kong API Gateway (JWT Auth, Rate Limiting, OpenTelemetry Tracing)

---

## 📑 ২. সেন্ট্রাল ডকুমেন্টেশন সূচী (Documentation Index)

| ফাইল | লোকেশন | বিবরণ |
| :--- | :--- | :--- |
| **HLD Architecture** | [`docs/HLD_System_Architecture.md`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/docs/HLD_System_Architecture.md) | হাই-লেভেল আর্কিটেকচার স্পেসিফিকেশন ও কম্পোনেন্ট ফ্লো |
| **LLD Database Schemas** | [`docs/LLD_Database_Schemas.md`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/docs/LLD_Database_Schemas.md) | লো-লেভেল ডাটাবেস স্কিমা, টেবিল স্ট্রাকচার ও ইনডেক্সিং |
| **Interview Master Notes** | [`docs/Notes.md`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/docs/Notes.md) | ৩২টি সিস্টেম ডিজাইন কনসেপ্ট (কী, কেন, কোথায়, কীভাবে, উদাহরণ, Q&A) |
| **HLD Visual Diagram** | [`docs/HLD_diagram.png`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/docs/HLD_diagram.png) | FAANG-Grade ভিজ্যুয়াল আর্কিটেকচার ডায়াগ্রাম |

---

## 📂 ৩. পূর্ণাঙ্গ প্রজেক্ট ফোল্ডার স্ট্রাকচার (Directory Tree)

আমাদের প্রজেক্টের রুট ডিরেক্টরি `arogyam-healthcare-platform`-এর স্ট্রাকচার নিচে দেওয়া হলো:

```text
arogyam-healthcare-platform/
│
├── .env                                # গ্লোবাল ডকার ও সার্ভিস এনভায়রনমেন্ট ভেরিয়েবল
├── docker-compose.yml                  # লোকাল ইনফ্রাস্ট্রাকচার কন্টেইনার সার্ভিসসমূহ
│
├── docs/                               # সমস্ত ডক্যুমেন্টেশন ও ডায়াগ্ৰাম ইমেজ
│   ├── HLD_System_Architecture.md      # High-Level Architecture Spec
│   ├── LLD_Database_Schemas.md         # Low-Level DB Schemas (Postgres, Cassandra, ES)
│   ├── Notes.md                        # Master System Design Notes (32 Concepts)
│   ├── HLD_diagram.png                 # FAANG Architecture Diagram
│   └── Project_Execution_Log.md        # এই সেন্ট্রাল এক্সিকিউশন ও ওয়ার্কফ্লো লগ
│
├── resumes/                            # সমস্ত রেজুমে ডক্যুমেন্ট
│   ├── Soumyajit Pan Future Resume.docx
│   └── Soumyajit Pan Maang.docx
│
├── scripts/                            # ডাটাবেস স্কিপ্টসমূহ
│   └── init-databases.sql              # ৭টি আইসোলেটেড PostgreSQL DB তৈরির স্কিপ্ট
│
└── [Microservices Subfolders]          # (পরবর্তী ধাপে প্রতিটি স্বাধীন রিপোজিটরি হিসেবে যোগ হবে)
    ├── arogyam-auth-service/           # Python FastAPI + gRPC (Identity & Auth)
    ├── arogyam-patient-service/        # Java Spring Boot + gRPC (Patient Profiles)
    ├── arogyam-doctor-service/         # Java Spring Boot + gRPC (Doctor Schedules)
    ├── arogyam-appointment-service/    # Python FastAPI + gRPC (CQRS Write Model)
    ├── arogyam-search-service/         # Go + Elasticsearch + PostGIS (Geospatial Search)
    ├── arogyam-messaging-service/      # Node.js / Go + WebSockets + Cassandra (Live Chat)
    ├── arogyam-notification-service/   # Node.js + Kafka Consumer (Email, SMS, Push)
    ├── arogyam-patient-portal/         # React + Vite (Patient Web App)
    ├── arogyam-doctor-portal/          # React + Vite (Doctor Web App)
    └── arogyam-admin-portal/           # React + Vite (Admin Portal)
```

---

## 🐳 ৪. ডকার ইনফ্রাস্ট্রাকচার কন্টেইনারসমূহ (Docker Infrastructure Services)

আমাদের `docker-compose.yml`-এ সংজ্ঞায়িত ৭টি মূল ইনফ্রাস্ট্রাকচার কন্টেইনারের বিবরণ:

1. **`postgres-db` (PostgreSQL 16 - Port `5432`):**
   - **ভূমিকা:** ট্রানজাকশনাল Relational DB।
   - **ইনিশিয়ালাইজেশন:** `scripts/init-databases.sql` ফাইল দিয়ে অটোমেটিক ৭টি আইসোলেটেড ডাটাবেস তৈরি হয় (`arogyam_identity`, `arogyam_patient`, `arogyam_doctor`, `arogyam_appointment`, `arogyam_pharmacy`, `arogyam_health_record`, `arogyam_audit`)।
2. **`redis-cache` (Redis 7 - Port `6379`):**
   - **ভূমিকা:** ইন-মেমোরি ডাটা স্টোর।
   - **ব্যবহার:** প্রোফাইল ক্যাশিং, অ্যাপয়েন্টমেন্ট স্লটের Distributed Locking (Redlock) এবং API Gateway Rate Limiting।
3. **`zookeeper` (Port `2181`) & `kafka` (Apache Kafka - Ports `9092` / `29092`):**
   - **ভূমিকা:** সেন্ট্রাল ইভেন্ট স্ট্রিম ব্যাকবোন।
   - **ব্যবহার:** মাইক্রোসার্ভিসগুলোর মধ্যে অসিনক্রোনাস মেসেজিং, Saga Choreography এবং Transactional Outbox ইভেন্ট রুট করা।
4. **`kong-gateway` (Kong API Gateway - Ports `8000` / `8001`):**
   - **ভূমিকা:** এজ রিভার্স প্রক্সি।
   - **ব্যবহার:** JWT টোকেন ভ্যালিডেশন, RBAC অডিটিং, রিকোয়েস্ট রেট লিমিটিং এবং ইন্টারনাল Pod-এ রাউটিং।
5. **`elasticsearch` (Elasticsearch 8 - Port `9200`):**
   - **ভূমিকা:** CQRS Read Model & Geospatial Search Store।
   - **ব্যবহার:** <১৫ms ল্যাটেন্সিতে ডাক্তারের নাম, স্পেশালিটি ও PostGIS লোকেশন দিয়ে দ্রুত খুঁজে বের করা।
6. **`cassandra-db` (Apache Cassandra 4.1 - Port `9042`):**
   - **ভূমিকা:** NoSQL Column-Family Database।
   - **ব্যবহার:** রিয়েল-টাইম চ্যাট মেসেজ সংরক্ষণ করা (`session_id` Partition Key দিয়ে)।

---



### 💡 ডকার কনসেপ্ট ও মূল উদ্দেশ্য (Docker Core Concepts & Rationale)

1. **আমাদের মূল উদ্দেশ্য (Why Docker?):**
   - Arogyam প্রজেক্টের ব্যাকএন্ডে ৭টি আলাদা সার্ভার ও ডাটাবেস দরকার (PostgreSQL, Redis, Kafka, Zookeeper, Kong, Elasticsearch, Cassandra)।
   - পিসিতে ম্যানুয়ালি ইনস্টল না করে আমরা `docker-compose.yml` দিয়ে ১ ক্লিকে ৭টি কন্টেইনার ব্যাকগ্রাউন্ডে চালু করছি। এতে আপনার অপারেটিং সিস্টেম পরিষ্কার থাকে ও পোর্ট কনফ্লিক্ট হয় না।

2. **Virtual Machine vs Docker Container (কেন আলাদা Ubuntu OS লাগে না?):**
   - **Virtual Machine (পুরনো ভারী নিয়ম):** Windows ➔ VirtualBox ➔ ১.৫ জিবি-র ভারী Ubuntu OS ➔ PostgreSQL।
   - **Docker Container (আধুনিক ফাস্ট নিয়ম):** Windows ➔ Docker Engine (WSL2 Shared Linux Kernel) ➔ Isolated PostgreSQL Container (মাত্র ৩৫ MB!)।
   - অর্থাৎ, ডকারের ভেতরে আলাদা করে কোনো ভারী Ubuntu OS ইনস্টল হয় না। প্রতিটি সার্ভিস নিজস্ব লাইটওয়েট আলপাইন প্যাকেজ (Alpine Linux) নিয়ে সরাসরি হোস্টের Shared Kernel-এ চলে।

3. **Image vs Container (বাস্তব উদাহরণ):**
   - **Docker Image (রেসিপি বই / `.exe` ইনস্টলার):** সফটওয়্যারটির ফাইল প্যাকেজ ও ব্লুপ্রিন্ট (যেমন: `postgres:16-alpine`)।
   - **Docker Container (রানিং অ্যাপ / খাবার):** ইমেজের ওপর ভিত্তি করে পিসির মেমোরিতে চালু হওয়া একটি স্বাধীন রানিং প্রসেস (যেমন: `arogyam-postgres-db`)।
   - **Docker Engine (ফুড কোর্ট ম্যানেজার):** যে সবকটি কন্টেইনারকে এক ছাদের নিচে স্বাধীনভাবে পরিচালনা করে।

---

## 🚦 ৫. এক্সিকিউশন রোডম্যাপ ও স্ট্যাটাস ট্র্যাকার (Roadmap & Status)

- [x] **Step 1:** High-Level Architecture & Design Verification (HLD & Diagram Approved)
- [x] **Step 2:** System Design Interview Master Notes (32 Topics in `Notes.md`)
- [x] **Step 3:** Local Infrastructure Setup (IaC via `docker-compose.yml`, `.env`, `init-databases.sql`)
- [ ] **Step 4:** Identity & Auth Microservice (`arogyam-auth-service`)
- [ ] **Step 5:** Patient & Doctor Microservices
- [ ] **Step 6:** Appointment Microservice (CQRS + Saga Choreography)
- [ ] **Step 7:** Real-Time Messaging & Video Telehealth Services
- [ ] **Step 8:** Frontend Portals (Patient, Doctor, Admin) & End-to-End Testing

---

## 📝 ৬. পর্যায়ক্রমিক ইতিহাস ও মাইলস্টোন লগ (Milestones Log)

### 🔵 মাইলস্টোন ১: আর্কিটেকচার ও রেজুমে রেডিসাইন
* **তারিখ:** 2026-07-24
* **সম্পাদিত কাজ:**
  1. `Soumyajit Pan Future Resume.docx` ফাইলে FAANG-level কনসেপ্টগুলো (CQRS, Saga, Redlock, Outbox/Inbox, Cassandra, PostGIS) সুন্দরভাবে উপস্থাপন করা হয়েছে।
  2. বুলেট পয়েন্টগুলোর Indent ডানে সরিয়ে **`27pt` (0.375 in)** করা হয়েছে।
  3. সেকশন হেডারগুলোতে Navy Blue (`#1B365D`) কাস্টম বটম বর্ডার যুক্ত করা হয়েছে।
  4. তারিখগুলো রাইট মার্জিনে Right Tab Stop দিয়ে সাজানো হয়েছে।

### 🔵 মাইলস্টোন ২: HLD ও ডায়াগ্ৰাম ভ্যালিডেশন
* **তারিখ:** 2026-07-24
* **সম্পাদিত কাজ:**
  1. `HLD_diagram.png` ডায়াগ্রামের সাথে `HLD_System_Architecture.md` মিলিয়ে দেখা হয়েছে।
  2. API Gateway, 18টি মাইক্রোসার্ভিস, Database-per-Service, Kafka Stream এবং Observability Stack-এর ১০০% ভ্যালিডিটি নিশ্চিত করা হয়েছে।

### 🔵 মাইলস্টোন ৩: সিস্টেম ডিজাইন মাস্টার নোটস
* **তারিখ:** 2026-07-24
* **সম্পাদিত কাজ:**
  1. 7টি ক্যাটাগরিতে ৩২টি সিস্টেম ডিজাইন কনসেপ্ট নিয়ে তৈরি করা হয়েছে [`docs/Notes.md`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/docs/Notes.md)।
  2. প্রতিটি কনসেপ্টের **কী**, **কেন**, **কোথায়**, **কীভাবে**, **বাস্তব উদাহরণ (Analogy)** এবং **ইন্টারভিউ Q&A** যুক্ত করা হয়েছে।

### 🔵 মাইলস্টোন ৪: লোকাল ইনফ্রাস্ট্রাকচার সেটআপ (Step 3 IaC)
* **তারিখ:** 2026-07-24
* **সম্পাদিত কাজ:**
  1. 7টি ইনফ্রাস্ট্রাকচার কন্টেইনার সহ তৈরি করা হয়েছে [`docker-compose.yml`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/docker-compose.yml)।
  2. গ্লোবাল এনভায়রনমেন্ট ভেরিয়েবলের জন্য [`.env`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/.env) ফাইল তৈরি করা হয়েছে।
  3. ৭টি আলাদা PostgreSQL ডাটাবেস তৈরির জন্য [`scripts/init-databases.sql`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/scripts/init-databases.sql) ফাইল তৈরি করা হয়েছে।
  4. `docker compose config --services` দিয়ে Syntax ভ্যালিডেশন নিশ্চিত করা হয়েছে।

### 🔵 মাইলস্টোন ৫: ডক্যুমেন্টেশন সাজানো ও সেন্ট্রাল লগ তৈরি
* **তারিখ:** 2026-07-24
* **সম্পাদিত কাজ:**
  1. সমস্ত Markdown ফাইল এবং Diagram ইমেজ **`docs/`** ফোল্ডারে সরিয়ে প্রজেক্ট রুট পরিষ্কার করা হয়েছে।
  2. প্রজেক্টের একক সত্যের উৎস (Single Source of Truth) হিসেবে এই [`docs/Project_Execution_Log.md`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/docs/Project_Execution_Log.md) তৈরি করা হয়েছে।

---


### 🔵 মাইলস্টোন ৬: ডকার স্টোরেজ ডি ড্রাইভ লিংক, স্থায়ী পারফরম্যান্স ফিক্স ও README.md তৈরি
* **তারিখ:** 2026-07-24
* **সম্পাদিত কাজ:**
  1. ডকার ইনস্টলেশন সরাসরি **D Drive-এ (`D:\Docker\Docker`)** ইনস্টল ও কনফিগার করা হয়েছে।
  2. Windows Kernel Directory Junction (`mklink /J "C:\Users\USER\AppData\Local\Docker\wsl" "D:\Docker\wsl"`) এবং `%TEMP%` ➔ `D:\Temp` মাইগ্রেশনের মাধ্যমে C Drive-এর মেমোরি ফ্রী ও স্থায়ী সুরক্ষা করা হয়েছে (C Drive-এ **18.17 GB** এবং D Drive-এ **21.60 GB** ফ্রী স্পেস)।
  3. ৭টি ইনফ্রাস্ট্রাকচার কন্টেইনার সার্ভিস (`postgres`, `redis`, `kafka`, `zookeeper`, `kong`, `elasticsearch`, `cassandra`) সফলভাবে স্পন করা হয়েছে।
  4. প্রজেক্ট রুটে আর্কিটেকচার ডায়াগ্রাম, সার্ভিস মেট্রিক্স ও ডকার গাইড সহ তৈরি করা হয়েছে প্রফেশনাল [`README.md`](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/README.md)।

---


### 🔵 মাইলস্টোন ৭: Step 4 Auth Microservice (TDD & Clean Architecture) ১০০% সফল
* **তারিখ:** 2026-07-24
* **সম্পাদিত কাজ:**
  1. **Clean Architecture (Hexagonal Layout)** অনুযায়ী `arogyam-auth-service` ফোল্ডার তৈরি করা হয়েছে (Domain Entities, Repositories Interfaces, Application Use Cases, Infrastructure DB Models, REST Controllers)।
  2. **TDD Workflow (Red ➔ Green ➔ Refactor):** `pytest` দিয়ে Domain Security, User Entity, Register & Login Use Case-এর ৯টি ইউনিট টেস্ট পাস করানো হয়েছে।
  3. **PostgreSQL Integration:** Docker PostgreSQL container-এর `arogyam_identity` ডাটাবেসের `users` টেবিলে `app_user` / `arogyam_admin` স্কিমা কানেক্ট করা হয়েছে (Port 5433)।
  4. **Live API Endpoints Tested:** FastAPI লাইভ সার্ভারে (`http://localhost:8005`) ইউজার রেজিস্ট্রেশন (`/api/v1/auth/register`) এবং JWT টোকেন জেনারেশনসহ লগইন (`/api/v1/auth/login`) সম্পূর্ণ সফলভাবে ভ্যালিডেট করা হয়েছে।

---

## 🏛️ ৭. আর্কিটেকচারাল ডিশিসন রেকর্ডস (ADR Log)

### ADR 001: Database-per-Service Pattern
* **স্ট্যাটাস:** Approved
* **প্রেক্ষিত:** শেয়ার্ড ডাটাবেস ব্যবহারে সার্ভিসগুলোর স্বাধীনতা নষ্ট হয় এবং স্লো SQL JOIN-এ পুরো সিস্টেম লক হওয়ার ভয় থাকে।
* **সিদ্ধান্ত:** প্রতিটি মাইক্রোসার্ভিসের জন্য আলাদা PostgreSQL ডাটাবেস থাকবে। সার্ভিসগুলো একে অপরের সাথে শুধু gRPC বা Kafka দিয়ে যোগাযোগ করবে।

### ADR 002: Multi-Repo Subfolder Structure
* **স্ট্যাটাস:** Approved
* **প্রেক্ষিত:** বিভিন্ন ভাষার (Python, Java, Go, Node, React) মাইক্রোসার্ভিসের স্বাধীন বিল্ড ও ডিপ্লয়মেন্ট প্রয়োজন।
* **সিদ্ধান্ত:** রুট ফোল্ডারে শেয়ার্ড ইনফ্রাস্ট্রাকচার (`docker-compose.yml`) এবং প্রতিটি মাইক্রোসার্ভিসের জন্য আলাদা আলাদা সাব-ফোল্ডার থাকবে।

---

## 🛠️ ৮. ডকার চালু ও ভেরিফিকেশন নির্দেশিকা (Execution Commands)

### ১. সমস্ত ডকার কন্টেইনার ব্যাকগ্রাউন্ডে চালু করতে:
```bash
docker compose up -d
```

### ২. কন্টেইনারগুলোর রানিং স্টেটাস ও হেলথ চেক দেখতে:
```bash
docker compose ps
```

### ৩. কোনো নির্দিষ্ট কন্টেইনারের লগ দেখতে:
```bash
docker compose logs -f postgres-db
docker compose logs -f kafka
```

---

*সর্বশেষ আপডেট: 2026-07-24 | Arogyam Engineering Team*
