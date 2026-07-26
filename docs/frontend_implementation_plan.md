# Arogyam Frontend Applications — Implementation Plan

## Overview
Three React (Vite + TypeScript) applications deployed via CDN.
Communicates with backend through Kong API Gateway only.

---

## 1. Patient Portal (`arogyam-patient-portal`)

### Tech Stack
| Layer | Technology |
|-------|-----------|
| Framework | React 18 + Vite + TypeScript |
| State | Zustand (global) + React Query (server state) |
| Styling | Tailwind CSS + shadcn/ui |
| Routing | React Router v6 |
| Push | Firebase SDK (FCM web push) |
| Charts | Recharts |
| Port | **3000** (dev) |

### Pages & Routes
```
/                          Landing Page
/login                     Login (Email + OTP toggle)
/register                  Multi-step registration
/patient/dashboard         Dashboard (stats, appointments, quick actions)
/patient/appointments      Appointment list + calendar toggle
/patient/appointments/:id  Appointment detail + queue tracker
/patient/find-doctors      AI search + filter + doctor cards
/patient/health-records    Medical records list
/patient/prescriptions     Prescription list + PDF download
/patient/vitals            Vitals history + trend charts
/patient/chat/:doctorId    Real-time chat
/patient/video/:apptId     Video consultation room
/patient/profile           Profile settings
```

### Key Features
- **FCM Push Notifications** — register service worker, receive push
- **AI Doctor Search** — symptom input → AI recommendation → doctor cards
- **Real-time Queue** — WebSocket queue position updates
- **Video Call** — WebRTC in-browser video consultation
- **Offline Support** — PWA + service worker cache

---

## 2. Doctor Portal (`arogyam-doctor-portal`)

### Pages & Routes
```
/                          Landing (redirect to login)
/login                     Doctor login
/doctor/dashboard          Dashboard (appointments, earnings, stats)
/doctor/appointments       Today's schedule + calendar
/doctor/appointments/:id   Appointment + write prescription
/doctor/patients           Patient list
/doctor/patients/:id       Patient medical history
/doctor/prescriptions      Issued prescriptions
/doctor/chat/:patientId    Real-time chat
/doctor/video/:apptId      Video consultation room
/doctor/profile            Profile + availability settings
/doctor/earnings           Billing history
```

### Key Features
- **Prescription Writer** — medicine form + digital signature
- **Patient Medical History** — full timeline view
- **Availability Calendar** — set available slots
- **Earnings Dashboard** — revenue charts

---

## 3. Admin Portal (`arogyam-admin-portal`)

### Pages & Routes
```
/admin/login               Admin login (separate)
/admin/dashboard           Overview metrics + alerts
/admin/verifications       Pending doctor verifications
/admin/verifications/:id   Doctor detail + verify/reject
/admin/users               All users table + search
/admin/users/:id           User detail + ban/unban
/admin/audit-logs          Immutable audit log viewer
/admin/analytics           Platform analytics charts
```

### Key Features
- **Doctor KYC Verification** — registration ID + Aadhaar check
- **One-click Verify/Reject** — with reason modal
- **Audit Log Viewer** — filterable, read-only
- **Platform Analytics** — user growth, appointments, revenue

---

## Shared Design System

```
Design Tokens:
  Primary:    #0d4f4f (Deep Teal)
  Secondary:  #1a7a5e (Emerald)
  Accent:     #22d3a5 (Mint)
  Background: #0a1628 (Dark Navy)
  Surface:    #111f35
  Text:       #e2e8f0

Typography: Inter (Google Fonts)

Components:
  Button, Input, Modal, Card, Badge, Toast
  DataTable, Chart, Calendar, Avatar
  NotificationBell, QueueTracker, VideoRoom
```

## API Communication
```
All API calls → http://localhost:8000 (Kong Gateway)
WebSocket    → ws://localhost:8010 (Messaging)
Video Signal → ws://localhost:8012 (Video Call)
```

## Docker Setup
```yaml
patient-portal:
  build: ./arogyam-patient-portal
  container_name: arogyam-patient-portal
  ports:
    - "3000:3000"

doctor-portal:
  build: ./arogyam-doctor-portal
  container_name: arogyam-doctor-portal
  ports:
    - "3001:3001"

admin-portal:
  build: ./arogyam-admin-portal
  container_name: arogyam-admin-portal
  ports:
    - "3002:3002"
```
