# Arogyam Messaging Service — Implementation Plan

## Overview
Real-time Doctor-Patient chat using WebSockets. Messages stored in Cassandra
(already running). Redis Pub/Sub for horizontal scaling across multiple instances.

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | Node.js 20 |
| Protocol | WebSocket (Socket.io) |
| Message Store | Apache Cassandra (already in Docker) |
| Pub/Sub | Redis (already in Docker) |
| Auth | JWT validation (inline, no gRPC needed) |
| Port | **8010** (HTTP) + **8011** (WebSocket) |

## Cassandra Schema

```cql
CREATE KEYSPACE arogyam_messaging
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE messages (
  conversation_id UUID,
  message_id      TIMEUUID,
  sender_id       TEXT,
  receiver_id     TEXT,
  content         TEXT,
  message_type    TEXT,  -- TEXT | IMAGE | FILE
  is_read         BOOLEAN,
  sent_at         TIMESTAMP,
  PRIMARY KEY (conversation_id, message_id)
) WITH CLUSTERING ORDER BY (message_id DESC);

CREATE TABLE conversations (
  conversation_id   UUID PRIMARY KEY,
  patient_id        TEXT,
  doctor_id         TEXT,
  appointment_id    TEXT,
  last_message      TEXT,
  last_message_at   TIMESTAMP,
  unread_count      INT
);
```

## WebSocket Events

### Client → Server
```javascript
'message:send'     { conversationId, content, type }
'message:read'     { conversationId, messageId }
'typing:start'     { conversationId }
'typing:stop'      { conversationId }
```

### Server → Client
```javascript
'message:received'  { message }
'message:read'      { messageId, readAt }
'typing:status'     { userId, isTyping }
'user:online'       { userId }
'user:offline'      { userId }
```

## API Endpoints (REST)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/conversations` | List my conversations |
| `GET` | `/api/v1/conversations/{id}/messages` | Message history (cursor pagination) |
| `POST` | `/api/v1/conversations` | Start new conversation |
| `GET` | `/health` | Health check |

## Scaling with Redis Pub/Sub

```
User A (Server Instance 1) sends message
         │
         ▼
Redis Pub/Sub channel: "conversation:{id}"
         │
         ▼
User B (Server Instance 2) receives via subscription
```

## Kafka Events Published
```
chat.message.sent.v1  → Notification Service
                         (push if receiver is offline)
```

## docker-compose.yml Addition
```yaml
messaging-service:
  build: ./arogyam-messaging-service
  container_name: arogyam-messaging-service
  ports:
    - "8010:8010"
  environment:
    - CASSANDRA_HOST=cassandra-db
    - CASSANDRA_PORT=9042
    - CASSANDRA_KEYSPACE=arogyam_messaging
    - REDIS_HOST=redis-cache
    - REDIS_PORT=6379
    - REDIS_PASSWORD=redis_secure_pass_2026
    - KAFKA_BROKERS=kafka:9092
    - JWT_SECRET=your_jwt_secret
  depends_on:
    - cassandra-db
    - redis-cache
    - kafka
  networks:
    - arogyam-net
```
