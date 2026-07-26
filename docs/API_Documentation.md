# 🌐 Arogyam Healthcare Platform — Master API Reference & Use Cases

[![API Gateway](https://img.shields.io/badge/Gateway-Kong%20API%20Gateway%20:8000-blue.svg)](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/docker-compose.yml)
[![Architecture](https://img.shields.io/badge/Architecture-Event--Driven%20Microservices-green.svg)](file:///d:/Code%20Files/My%20Projects/In%20Progress/arogyam-healthcare-platform/docs/HLD_System_Architecture.md)

এই ডকুমেন্টে **Arogyam Healthcare Platform**-এর সমস্ত মাইক্রোসার্ভিসের প্রয়োজনীয় API এন্ডপয়েন্টসমূহ, এইচটিটিপি মেথড (HTTP Methods), সিকিউরিটি লেভেল (Security Roles), রিকোয়েস্ট/রেসপন্স স্ট্রাকচার এবং বাংলায় তাদের বাস্তব **ইউজ কেস (Use Cases)** বিস্তারিত উল্লেখ করা হয়েছে।

---

## 🧭 API Gateway & Routing Overview

সমস্ত ক্লায়েন্ট রিকোয়েস্ট (React Portals, Mobile Apps) **Kong API Gateway (`http://localhost:8000`)**-এর মাধ্যমে নিরাপদভাবে প্রতিটি মাইক্রোসার্ভিসে রাউট হয়।

| Microservice | Internal Port | Base API Path |
| :--- | :--- | :--- |
| **Auth & Identity Service** | `:8005` | `/api/v1/auth` |
| **Patient Service** | `:8002` | `/api/v1/patients` |
| **Doctor Service** | `:8003` | `/api/v1/doctors` |
| **Appointment Service (CQRS Write)** | `:8004` | `/api/v1/appointments` |
| **Doctor Search Service (CQRS Read)** | `:8006` | `/api/v1/search` |
| **Medical Record & E-Prescription** | `:8007` | `/api/v1/records` |
| **Real-time Messaging & Chat** | `:8008` | `/api/v1/chat` |
| **Video Telehealth Service** | `:8009` | `/api/v1/telehealth` |
| **Notification Service** | `:8010` | `/api/v1/notifications` |

---

## 1. 🔐 Identity & Auth Microservice (`arogyam-auth-service`)

### 1.1 User Registration (`POST /api/v1/auth/register`)
- **HTTP Method:** `POST`
- **Security:** Public (No Token required)
- **Request Body:**
  ```json
  {
    "email": "dr.soumyajit@arogyam.com",
    "password": "SuperSecurePassword123!",
    "first_name": "Soumyajit",
    "last_name": "Pan",
    "phone_number": "+919876543210",
    "role": "DOCTOR"
  }
  ```
- **Response (`201 Created`):**
  ```json
  {
    "id": "usr_16f77a8d6c6a",
    "email": "dr.soumyajit@arogyam.com",
    "first_name": "Soumyajit",
    "last_name": "Pan",
    "phone_number": "+919876543210",
    "role": "DOCTOR",
    "status": "ACTIVE"
  }
  ```
- **বাংলায় ইউজ কেস (Use Case):** 
  নতুন রোগী (Patient) বা ডাক্তার (Doctor) যখন প্ল্যাটফর্মে প্রথম অ্যাকাউন্ট তৈরি করবেন, তখন এই API ব্যবহৃত হয়। এটি পাসওয়ার্ড সুরক্ষিতভাবে Bcrypt দিয়ে হ্যাশ করে PostgreSQL ডাটাবেসে সেভ করে।

---

### 1.2 User Login (`POST /api/v1/auth/login`)
- **HTTP Method:** `POST`
- **Security:** Public
- **Request Body:**
  ```json
  {
    "email": "dr.soumyajit@arogyam.com",
    "password": "SuperSecurePassword123!"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "expires_in": 1800
  }
  ```
- **বাংলায় ইউজ কেস (Use Case):** 
  ইউজার ইমেইল ও পাসওয়ার্ড দিয়ে সাইন-ইন করলে এই API তাকে ৩০ মিনিট মেয়াদী JWT Access Token এবং ৭ দিন মেয়াদী Refresh Token প্রদান করে।

---

### 1.3 Get Current Logged-in Profile (`GET /api/v1/auth/me`)
- **HTTP Method:** `GET`
- **Security:** `Bearer JWT Token` Required
- **Response (`200 OK`):**
  ```json
  {
    "id": "usr_16f77a8d6c6a",
    "email": "dr.soumyajit@arogyam.com",
    "first_name": "Soumyajit",
    "last_name": "Pan",
    "role": "DOCTOR",
    "status": "ACTIVE"
  }
  ```
- **বাংলায় ইউজ কেস (Use Case):** 
  ইউজার পোর্টালে ড্যাশবোর্ডে প্রবেশের সময় বা পেজ রিফ্রেশ করলে তার প্রোফাইল তথ্য ও রোল (DOCTOR/PATIENT) ভ্যালিডেট করার জন্য ব্যবহৃত হয়।

---

### 1.4 Update User Profile (`PUT /api/v1/auth/me`)
- **HTTP Method:** `PUT`
- **Security:** `Bearer JWT Token` Required
- **Request Body:**
  ```json
  {
    "first_name": "Soumyajit",
    "last_name": "Pan",
    "phone_number": "+919876543210"
  }
  ```
- **Response (`200 OK`):** Updated UserResponse DTO
- **বাংলায় ইউজ কেস (Use Case):** 
  লগইন থাকা ইউজার নিজের নাম বা ফোন নম্বর পরিবর্তন করতে চাইলে এই API ব্যবহার করে প্রোফাইল আপডেট করেন।

---

### 1.5 Deactivate Own Account (`DELETE /api/v1/auth/me`)
- **HTTP Method:** `DELETE`
- **Security:** `Bearer JWT Token` Required
- **Response (`200 OK`):**
  ```json
  {
    "status": "success",
    "message": "User account 'usr_16f77a8d6c6a' has been deactivated successfully"
  }
  ```
- **বাংলায় ইউজ কেস (Use Case):** 
  ইউজার যদি নিজে তার অ্যাকাউন্টটি বন্ধ (Soft Delete / Deactivate) করতে চায়। স্বাস্থ্যসেবার নিয়মানুযায়ী (HIPAA/GDPR) ডাটাবেসের অডিট রেকর্ড ঠিক রেখে ইউজারের স্টেটাস `INACTIVE` করে দেওয়া হয়।

---

### 1.6 Delete User by Admin (`DELETE /api/v1/auth/users/{user_id}`)
- **HTTP Method:** `DELETE`
- **Security:** `Bearer JWT Token` (Role: `ADMIN`)
- **Query Parameter:** `hard_delete=false` (Soft Delete) or `hard_delete=true` (Hard Delete)
- **Response (`200 OK`):**
  ```json
  {
    "status": "success",
    "message": "User 'usr_16f77a8d6c6a' has been permanently deleted"
  }
  ```
- **বাংলায় ইউজ কেস (Use Case):** 
  সিস্টেম অ্যাডমিনিস্ট্রেটর কোনো ভুয়া বা ক্ষতিকারক ইউজারকে সাময়িক ডিএক্টিভেট (Soft Delete) বা ডাটাবেস থেকে স্থায়ীভাবে রিমুভ (Hard Delete) করতে এই API ব্যবহার করেন।

---

### 1.7 Token Refresh (`POST /api/v1/auth/refresh`)
- **HTTP Method:** `POST`
- **Security:** Public
- **Request Body:** `{"refresh_token": "eyJhbGciOi..."}`
- **বাংলায় ইউজ কেস (Use Case):** 
  Access Token মেয়াদ শেষ হলে ইউজারকে বারবার সাইন-ইন না করিয়ে নতুন Access Token ই ইস্যু করার জন্য ব্যাকগ্রাউন্ডে ব্যবহৃত হয়।

---

## 2. 👨‍⚕️ Doctor Search Microservice — CQRS Read Path (`arogyam-search-service`)

### 2.1 Geospatial Doctor Availability Search (`GET /api/v1/search/doctors`)
- **HTTP Method:** `GET`
- **Security:** Public / Patient
- **Query Parameters:** `specialty=Cardiology&lat=22.5726&lng=88.3639&radius_km=10`
- **Response (`200 OK`):**
  ```json
  {
    "total": 1,
    "doctors": [
      {
        "doctor_id": "doc_99812",
        "name": "Dr. Soumyajit Pan",
        "specialty": "Cardiology",
        "experience_years": 8,
        "consultation_fee": 500,
        "distance_km": 2.4,
        "rating": 4.9,
        "available_slots": ["2026-07-25T10:00:00Z", "2026-07-25T11:00:00Z"]
      }
    ]
  }
  ```
- **বাংলায় ইউজ কেস (Use Case):** 
  রোগী যখন তার আসেপাশের ১০ কিলোমিটারের মধ্যে হার্টের ডাক্তার খুঁজবে, তখন Elasticsearch 8 এবং PostGIS দিয়ে **১৫ মিলি-সেকেন্ডের কম সময়ে (<15ms)** রিয়েল-টাইম ফিল্টারিং ফলাফল দেখায়।

---

## 3. 📅 Appointment Scheduling Microservice — CQRS Write Path (`arogyam-appointment-service`)

### 3.1 Book Appointment (`POST /api/v1/appointments/book`)
- **HTTP Method:** `POST`
- **Security:** `Bearer JWT Token` (Role: `PATIENT`)
- **Request Body:**
  ```json
  {
    "doctor_id": "doc_99812",
    "slot_timestamp": "2026-07-25T10:00:00Z",
    "symptoms_description": "Chest pain and hypertension history"
  }
  ```
- **Response (`201 Created`):**
  ```json
  {
    "appointment_id": "apt_771823",
    "status": "PENDING_PAYMENT",
    "doctor_id": "doc_99812",
    "slot_timestamp": "2026-07-25T10:00:00Z"
  }
  ```
- **বাংলায় ইউজ কেস (Use Case):** 
  রোগী ডাক্তার চয়ন করে নির্দিষ্ট সময়ে অ্যাপয়েন্টমেন্ট বুক করলে এটি চালু হয়। ডাবল-বুকিং ঠেকাতে এটি **Redis Redlock (Distributed Locking)** দিয়ে টাইম-স্লট লক করে এবং Saga Choreography ট্রিগার করে।

---

### 3.2 Doctor Appointment Schedule Approval (`PATCH /api/v1/appointments/{id}/status`)
- **HTTP Method:** `PATCH`
- **Security:** `Bearer JWT Token` (Role: `DOCTOR`)
- **Request Body:** `{"status": "CONFIRMED"}`
- **বাংলায় ইউজ কেস (Use Case):** 
  ডাক্তার তার পোর্টালে ঢুকলে যে অ্যাপয়েন্টমেন্ট রিকোয়েস্ট দেখেন, তা এক্সেপ্ট (CONFIRMED) বা ক্যান্সেল করার জন্য ব্যবহার করেন।

---

## 4. 📄 E-Prescription & Health Record Service (`arogyam-record-service`)

### 4.1 Create Digital Prescription (`POST /api/v1/records/prescriptions`)
- **HTTP Method:** `POST`
- **Security:** `Bearer JWT Token` (Role: `DOCTOR`)
- **Request Body:**
  ```json
  {
    "appointment_id": "apt_771823",
    "patient_id": "usr_patient_88",
    "diagnosis": "Acute Hypertension",
    "medicines": [
      {"name": "Amlodipine", "dosage": "5mg", "frequency": "1-0-1", "days": 15}
    ]
  }
  ```
- **Response (`201 Created`):** `{"prescription_id": "rx_001", "pdf_url": "https://s3.arogyam.com/rx_001.pdf"}`
- **বাংলায় ইউজ কেস (Use Case):** 
  অনলাইন ভিডিও কনসাল্টেশন শেষে ডাক্তার রোগীকে ডিজিটাল প্রেসক্রিপশন লিখে দিলে এই API ইনস্ট্যান্ট PDF জেনারেট করে সেশন শেষ করে।

---

## 5. 💬 Real-Time Messaging & Chat Service (`arogyam-messaging-service`)

### 5.1 Send Chat Message (`POST /api/v1/chat/send`)
- **HTTP Method:** `POST`
- **Security:** `Bearer JWT Token` (Patient / Doctor)
- **Request Body:**
  ```json
  {
    "receiver_id": "doc_99812",
    "message_text": "Doctor, should I take medicine before lunch?",
    "attachment_type": "NONE"
  }
  ```
- **Response (`200 OK`):** `{"message_id": "msg_9912", "timestamp": "2026-07-25T10:05:00Z"}`
- **বাংলায় ইউজ কেস (Use Case):** 
  রোগী ও ডাক্তারের মধ্যে লাইভ চ্যাটের সময় এই API চ্যাট মেসেজগুলো **Apache Cassandra NoSQL** ডাটাবেসে সেভ করে এবং WebSockets দিয়ে লাইভ রিসিভারের কাছে পাঠায়।

---

## 6. 📹 Video Telehealth Service (`arogyam-telehealth-service`)

### 7.1 Create Video Call Room (`POST /api/v1/telehealth/rooms/create`)
- **HTTP Method:** `POST`
- **Security:** `Bearer JWT Token`
- **Request Body:** `{"appointment_id": "apt_771823"}`
- **Response (`200 OK`):**
  ```json
  {
    "room_id": "room_tele_771823",
    "webrtc_token": "webrtc_token_secure_991",
    "turn_servers": ["turn:turn.arogyam.com:3478"]
  }
  ```
- **বাংলায় ইউজ কেস (Use Case):** 
  অ্যাপয়েন্টমেন্টের সময় হলে রোগী ও ডাক্তার সুরক্ষিত ভিডিও কনসাল্টেশনে যুক্ত হওয়ার জন্য এনক্রিপ্টেড WebRTC রুম তৈরি করতে এই API ব্যবহৃত হয়।

---

## 7. 🔔 Notification Service (`arogyam-notification-service`)

### 7.1 Dispatch Push Notification (`POST /api/v1/notifications/send`)
- **HTTP Method:** `POST` (Internal Microservice Call / Kafka Trigger)
- **Request Body:**
  ```json
  {
    "user_id": "usr_patient_88",
    "channel": "SMS_AND_EMAIL",
    "title": "Appointment Confirmed",
    "body": "Your appointment with Dr. Soumyajit Pan is scheduled for 10:00 AM."
  }
  ```
- **বাংলায় ইউজ কেস (Use Case):** 
  Kafka Event Topic (`appointment.confirmed`) থেকে ব্যাকগ্রাউন্ডে মোট মেসেজ রিড করে রোগীকে তাৎক্ষণিক SMS, Email এবং Mobile Push Notification পাঠানোর জন্য কাজ করে।

---

## 📊 Summary Matrix for Front-End Developers

| API Endpoint | HTTP | Microservice Target | Primary Use Case (বাংলা) |
| :--- | :--- | :--- | :--- |
| `/api/v1/auth/register` | `POST` | Auth Service (`:8005`) | নতুন একাউন্ট খোলার সময় |
| `/api/v1/auth/login` | `POST` | Auth Service (`:8005`) | ইমেইল ও পাসওয়ার্ড দিয়ে সাইন-ইন |
| `/api/v1/auth/me` | `GET` | Auth Service (`:8005`) | বর্তমান ইউজারের প্রোফাইল ও ভূমিকা দেখা |
| `/api/v1/auth/me` | `PUT` | Auth Service (`:8005`) | নিজের নাম ও ফোন নম্বর আপডেট করা |
| `/api/v1/auth/me` | `DELETE` | Auth Service (`:8005`) | ইউজার নিজে নিজের অ্যাকাউন্ট ডিএক্টিভেট করা |
| `/api/v1/auth/users/{id}` | `DELETE` | Auth Service (`:8005`) | অ্যাডমিন কর্তৃক ইউজার ডিএক্টিভেট বা রিমুভ করা |
| `/api/v1/search/doctors` | `GET` | Doctor Search (`:8006`) | অবস্থান ও বিষয় অনুযায়ী রিয়েল-টাইম ডাক্তার খোঁজা (<15ms) |
| `/api/v1/appointments/book` | `POST` | Appointment (`:8004`) | অ্যাপয়েন্টমেন্ট বুকিং করা (Redlock Lock সহ) |
| `/api/v1/records/prescriptions`| `POST` | Health Records (`:8007`) | ডাক্তারের ডিজিটাল প্রেসক্রিপশন প্রদান |
| `/api/v1/chat/send` | `POST` | Messaging (`:8008`) | লাইভ রোগী-ডাক্তার চ্যাট মেসেজ সংরক্ষণ (Cassandra) |
| `/api/v1/telehealth/rooms/create`| `POST` | Telehealth (`:8009`) | সুরক্ষিত WebRTC ভিডিও কল রুম জেনারেশন |
