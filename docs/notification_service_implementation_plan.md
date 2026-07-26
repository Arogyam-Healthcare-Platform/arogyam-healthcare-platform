# Arogyam Notification Service — Implementation Plan (Push-First)

## Strategy: Push Notification Primary

FCM (Firebase Cloud Messaging) হবে **primary channel** — 90%+ notification push দিয়েই হবে।
Email শুধু account-critical কাজে, SMS শুধু OTP তে।

## Channel Allocation

| Channel | কখন use হবে | % |
|---------|------------|---|
| **🔔 Push (FCM)** | Appointments, Reminders, Queue, Chat, Prescriptions, Lab Results | ~90% |
| **📧 Email** | Welcome, Password Reset, Monthly Health Report | ~8% |
| **📱 SMS** | শুধু OTP verification | ~2% |

## Push Notification — সব Use Cases

```
appointment.created     → "✅ Appointment confirmed with Dr. X on July 28"
appointment.cancelled   → "❌ Appointment cancelled. Reschedule now."
appointment.reminder    → "⏰ Appointment in 1 hour with Dr. X"
appointment.updated     → "📋 Appointment status changed: CONFIRMED"
queue.position          → "🔔 You are #3 in queue. ~15 min wait."
queue.next              → "🚨 You are next! Please proceed to Room 2."
chat.message            → "💬 Dr. X: Please share your latest report."
prescription.ready      → "💊 New prescription from Dr. X is ready."
lab.result              → "🧪 Your blood test report is now available."
video.call.starting     → "📹 Video consultation starting now. Join!"
doctor.verified         → "✅ Your doctor profile has been verified!"
login.new_device        → "⚠️ New login from Chrome, Delhi."
```

## Architecture

```
Kafka Events
     │
     ▼
 KafkaConsumer
     │
     ▼
 EventRouter
     │
     ├──► AppointmentHandler  ──► FCM Push (primary)
     │                             └── Email fallback (only if no FCM token)
     │
     ├──► QueueHandler        ──► FCM Push
     │
     ├──► ChatHandler         ──► FCM Push
     │
     ├──► LabHandler          ──► FCM Push
     │
     └──► AuthHandler         ──► Email (welcome/reset only)
                                  SMS (OTP only)
```

## FCM Token Flow

```
User installs App/PWA
        │
        ▼
Browser/App requests FCM token from Firebase
        │
        ▼
Frontend sends token → POST /api/v1/auth/fcm-token
        │
        ▼
Auth Service stores token in users table (fcm_token column)
        │
        ▼
Notification Service fetches token via gRPC → sends FCM push
```

## Folder Structure

```
arogyam-notification-service/
├── src/
│   ├── config/
│   │   └── config.js                  # Firebase, Kafka, SMTP config
│   ├── providers/
│   │   ├── BaseProvider.js            # Abstract Strategy interface
│   │   ├── FCMProvider.js             # Firebase Admin SDK ← PRIMARY
│   │   ├── EmailProvider.js           # Nodemailer (welcome/reset only)
│   │   └── SMSProvider.js             # Mock (OTP only, Twilio later)
│   ├── consumers/
│   │   └── KafkaConsumer.js           # kafkajs + graceful shutdown
│   ├── handlers/
│   │   ├── AppointmentHandler.js      # appointment.* events → FCM
│   │   ├── QueueHandler.js            # queue.* events → FCM
│   │   ├── ChatHandler.js             # chat.message.* → FCM
│   │   ├── LabHandler.js              # lab.result.* → FCM
│   │   └── AuthHandler.js             # welcome → Email, OTP → SMS
│   ├── templates/
│   │   ├── push/                      # FCM title + body templates
│   │   │   ├── appointment.js
│   │   │   ├── queue.js
│   │   │   ├── chat.js
│   │   │   └── lab.js
│   │   └── email/                     # HTML email templates
│   │       ├── welcome.js
│   │       └── password_reset.js
│   ├── services/
│   │   └── NotificationService.js     # Strategy selector
│   └── server.js                      # Express health/status (:8007)
├── Dockerfile
├── .env.example
├── .gitignore
├── package.json
└── README.md
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 20 (LTS) |
| **Push** | **firebase-admin (FCM)** ← PRIMARY |
| Kafka Client | `kafkajs` |
| Email | `nodemailer` + Mailtrap (dev) |
| SMS | Mock console log (Twilio later) |
| HTTP | `express` (health check :8007) |

## Firebase Setup (Free)

1. [console.firebase.google.com](https://console.firebase.google.com) → New Project
2. Project Settings → Service Accounts → Generate Private Key → `firebase-service-account.json`
3. এই JSON file টা `.env` এ path দেবো (`.gitignore` এ থাকবে)

## Kafka Topics (Consumed)

```
appointment.created.v1
appointment.cancelled.v1
appointment.updated.v1
appointment.reminder.v1
queue.position.updated.v1
chat.message.sent.v1
lab.result.uploaded.v1
prescription.created.v1
auth.user.registered.v1
auth.password.reset.v1
```

## docker-compose.yml Changes

```yaml
notification-service:
  build: ./arogyam-notification-service
  container_name: arogyam-notification-service
  ports:
    - "8007:8007"
  environment:
    - KAFKA_BROKERS=kafka:9092
    - FIREBASE_SERVICE_ACCOUNT_PATH=/app/secrets/firebase.json
  depends_on:
    kafka:
      condition: service_healthy
  networks:
    - arogyam-net
```

## Verification Plan

1. `docker compose logs notification-service` — consumer started দেখাবে
2. Mock Kafka event publish করে FCM log verify
3. `GET http://localhost:8007/health` → `{"status":"ok","kafka":"connected"}`

> [!IMPORTANT]
> **Firebase Project লাগবে** — free, 2 মিনিটে তৈরি হয়।
> firebase.google.com এ project বানিয়ে Service Account JSON download করতে পারবে।
> নাকি আপাতত **mock mode** এ build করবো (FCM call console.log করবে)?
