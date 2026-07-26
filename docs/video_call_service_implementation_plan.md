# Arogyam Video Call Service — Implementation Plan

## Overview
WebRTC-based telemedicine video consultation between Doctor and Patient.
Signaling server for peer-to-peer connection setup. TURN/STUN for NAT traversal.

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | Node.js 20 |
| Signaling | Socket.io (WebSocket) |
| Protocol | WebRTC (browser-native) |
| STUN Server | Google STUN (free): stun.l.google.com:19302 |
| TURN Server | Coturn (self-hosted) / Twilio TURN (dev) |
| Room State | Redis |
| Auth | JWT validation |
| Port | **8012** |

## WebRTC Flow

```
Doctor opens video page
        │
        ▼
Frontend → POST /api/v1/video/rooms/{appointmentId}/join
        │
        ▼
Server creates room in Redis (roomId, participants, status)
        │
        ▼
Socket.io Signaling:
  Patient joins → 'offer' sent to Doctor
  Doctor responds → 'answer' sent to Patient
  Both exchange → 'ice-candidate'
        │
        ▼
P2P WebRTC connection established (direct, no server relay)
        │
        ▼
Video/Audio flows directly between browsers
```

## Room States
```
WAITING    → Doctor created room, patient not joined
ACTIVE     → Both connected
ENDED      → Call finished
MISSED     → Patient didn't join within timeout
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/video/rooms/{appointmentId}` | Create video room |
| `POST` | `/api/v1/video/rooms/{appointmentId}/join` | Join room, get ICE config |
| `POST` | `/api/v1/video/rooms/{appointmentId}/end` | End call |
| `GET` | `/api/v1/video/rooms/{appointmentId}/status` | Room status |
| `GET` | `/api/v1/video/ice-config` | STUN/TURN server config |
| `GET` | `/health` | Health check |

## Socket.io Signaling Events

### Client → Server
```javascript
'join-room'        { roomId, userId, role: "DOCTOR"|"PATIENT" }
'offer'            { roomId, sdp }
'answer'           { roomId, sdp }
'ice-candidate'    { roomId, candidate }
'leave-room'       { roomId }
```

### Server → Client
```javascript
'peer-joined'      { userId, role }
'offer'            { sdp }
'answer'           { sdp }
'ice-candidate'    { candidate }
'peer-left'        { userId }
'room-ended'       {}
```

## ICE Server Config (Returned to Frontend)
```json
{
  "iceServers": [
    { "urls": "stun:stun.l.google.com:19302" },
    {
      "urls": "turn:your-turn-server:3478",
      "username": "generated-username",
      "credential": "generated-password"
    }
  ]
}
```

## Kafka Events Published
```
video.call.started.v1   → Analytics
video.call.ended.v1     → Appointment Service (update status → COMPLETED)
video.call.missed.v1    → Notification Service (push: "Patient missed call")
```

## Security
- Room access validates appointmentId ownership via JWT
- Temporary TURN credentials (time-limited HMAC tokens)
- Room auto-expires after appointment end time + 30 min

## docker-compose.yml Addition
```yaml
video-call-service:
  build: ./arogyam-video-call-service
  container_name: arogyam-video-call-service
  ports:
    - "8012:8012"
  environment:
    - REDIS_HOST=redis-cache
    - REDIS_PORT=6379
    - REDIS_PASSWORD=redis_secure_pass_2026
    - JWT_SECRET=your_jwt_secret
    - TURN_SERVER_URL=turn:localhost:3478
    - TURN_SECRET=your_turn_secret
    - KAFKA_BROKERS=kafka:9092
  depends_on:
    - redis-cache
    - kafka
  networks:
    - arogyam-net
```
