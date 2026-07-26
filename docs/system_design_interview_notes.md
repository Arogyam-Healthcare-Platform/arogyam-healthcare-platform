# Arogyam Project — System Design Interview Notes
## Complete Topic-by-Topic Guide with Interview Scripts

> **How to use this:** প্রতিটা topic এ "Say in Interview" section টা মুখস্থ করো।
> তারপর নিজের মতো করে বলো — exactly copy করতে হবে না।

---

# 🟢 LEVEL 1 — BEGINNER TOPICS

---

## Topic 1: Microservices Architecture

### What is it?
Instead of building one big application (Monolith), you split it into many small,
independent services. Each service does ONE thing and does it well.

**Monolith:**
```
One giant app → Patient + Doctor + Appointment + Auth + Search all together
→ One server, one database, one codebase
```

**Microservices:**
```
Auth Service    → only handles login/logout/tokens
Patient Service → only handles patient profiles
Doctor Service  → only handles doctor profiles
Appointment Service → only handles bookings
Search Service  → only handles search queries
```

### Where we used it in Arogyam
Every service is a separate application:
- `arogyam-auth-service` (Python FastAPI) → Port 8005
- `arogyam-patient-service` (Java Spring Boot) → Port 8002
- `arogyam-doctor-service` (Java Spring Boot) → Port 8003
- `arogyam-appointment-service` (Python FastAPI) → Port 8004
- `arogyam-search-service` (Go + Gin) → Port 8006

### Why we used it
1. **Different scaling needs** — Search gets 100x more requests than Admin.
   With microservices, we scale only Search. With monolith, we'd scale everything.
2. **Different tech needs** — Search needs Go (speed), Auth needs Python (fast dev),
   Patient/Doctor needs Java (strong typing, enterprise). Monolith = one language only.
3. **Independent deployment** — Fixing a bug in Doctor Service doesn't require
   redeploying Patient Service.
4. **Fault isolation** — If Search Service crashes, Patient registration still works.

### What would have happened WITHOUT microservices
- One bug in Search code could crash the entire platform including login
- We couldn't use Go for Search (for high performance) and Java for Patient (for reliability)
- Scaling would waste money — we'd scale everything even if only Search is slow
- 10 developers working on same codebase = merge conflicts every day

### Problem solved
- Search Service can handle 10,000 requests/sec independently
- Auth Service can be updated without touching Doctor Service
- Each team can own their service independently

### 💬 Say in Interview (Easy English)

*"In Arogyam, we use microservices architecture. We have 6 independent services —
Auth, Patient, Doctor, Appointment, Search, and API Gateway — each running as a
separate application with its own database and codebase.*

*The main reason was different scaling and technology requirements. Our Search Service
gets 100 times more traffic than the Admin functions, so we needed to scale it
independently. Also, Search works best in Go for high performance, while Patient
and Doctor services needed Java Spring Boot for enterprise-grade data consistency.*

*If we had used a monolith, one bug in the search code could crash the entire
platform including user login. With microservices, each service fails independently
— if Search goes down, patients can still register and book appointments."*

---

## Topic 2: REST API Design

### What is it?
A standard way to design APIs using HTTP methods and URLs that represent resources.

**HTTP Methods:**
- `GET` → Read data (no side effects)
- `POST` → Create new resource
- `PUT` → Replace entire resource
- `PATCH` → Update partial resource
- `DELETE` → Remove resource (soft delete in our case)

**Status Codes:**
- `200 OK` → Success
- `201 Created` → Resource created
- `400 Bad Request` → Client sent wrong data
- `401 Unauthorized` → Not logged in
- `403 Forbidden` → Logged in but no permission
- `404 Not Found` → Resource doesn't exist
- `409 Conflict` → Duplicate (e.g., email already exists)
- `429 Too Many Requests` → Rate limited
- `500 Internal Server Error` → Server bug

### Where we used it in Arogyam
```
Patient Service:
GET    /api/v1/patients/{id}       → Get patient profile
POST   /api/v1/patients            → Create patient
PATCH  /api/v1/patients/{id}       → Update partial profile
DELETE /api/v1/patients/{id}       → Soft delete (sets is_deleted=true)

Doctor Service:
GET    /api/v1/doctors             → List all doctors
GET    /api/v1/doctors/{id}        → Single doctor
POST   /api/v1/doctors             → Register doctor
PATCH  /api/v1/doctors/{id}        → Update doctor profile

Auth Service:
POST   /api/v1/auth/register       → Register user
POST   /api/v1/auth/login          → Login, get JWT
POST   /api/v1/auth/refresh        → Refresh token
POST   /api/v1/auth/logout         → Logout

Search Service:
GET    /api/v1/search/doctors      → Search doctors
GET    /api/v1/search/specialties  → List specialties
```

### Why we used it
- REST is the industry standard — every frontend developer knows it
- Stateless — each request contains all information needed
- Easy to test with Postman, curl
- Clear resource-based URLs make the API self-documenting

### What would have happened WITHOUT proper REST design
- Inconsistent URLs like `/getDoctor`, `/fetchPatient`, `/deleteUser` — confusing
- Mixing responsibilities — one endpoint doing too many things
- Frontend team would be confused about what response to expect

### Problem solved
- Clean, predictable API that frontend can use without reading documentation
- Swagger/OpenAPI auto-generated from Spring annotations

### 💬 Say in Interview (Easy English)

*"All our services expose RESTful APIs following standard conventions.
For example, in the Patient Service, GET /api/v1/patients/{id} returns a patient,
POST /api/v1/patients creates one, and PATCH /api/v1/patients/{id} updates specific fields.*

*One important decision was using PATCH instead of PUT for updates, because doctors
often update just their availability or fee — not the entire profile. PUT would
require sending the entire doctor object every time, which is wasteful.*

*We also follow proper HTTP status codes — 401 for unauthenticated, 403 for
unauthorized, 429 when rate limit is hit. This makes error handling on the frontend
much cleaner."*

---

## Topic 3: Database Selection — SQL vs NoSQL

### What is it?
Choosing the right database for the right use case.

**SQL (Relational):** Structured data, ACID transactions, joins
**NoSQL:** Flexible schema, horizontal scale, specific use cases

### Where we used it in Arogyam

| Database | Type | Used For | Why |
|----------|------|----------|-----|
| PostgreSQL | SQL | Users, Patients, Doctors, Appointments, Billing | Structured data, ACID needed, complex queries |
| Redis | NoSQL (Key-Value) | Session cache, JWT blacklist, queue position, rate limiting | Ultra-fast in-memory, TTL support |
| Elasticsearch | NoSQL (Search Engine) | Doctor search, specialty search | Full-text search, geospatial queries, sub-millisecond response |
| Cassandra | NoSQL (Wide-Column) | Chat messages | High write throughput, time-series data, never deletes |

### Why we used each

**PostgreSQL for core data:**
- Appointments need transactions: "Book slot AND charge payment" must be atomic
- Patient medical history has complex relationships
- ACID guarantees: no partial writes

**Redis for cache:**
- Doctor profile fetched 1000 times/minute → store in Redis, DB gets 1 request
- JWT tokens need to be invalidated on logout → store blacklist in Redis with TTL
- Rate limiting counter needs atomic increment → Redis INCR command

**Elasticsearch for search:**
- "Find cardiologist within 5km of my location" → PostgreSQL can't do geospatial efficiently
- "Search doctor by name or specialty" → Full-text search with ranking
- PostgreSQL LIKE query: O(n) scan — slow at scale
- Elasticsearch: inverted index — O(1) lookup

**Cassandra for chat:**
- Chat messages: millions of writes per day
- Never needs complex joins — just "give me last 50 messages in conversation X"
- Cassandra partitioned by conversation_id → all messages of a chat on same node
- Never deletes data (append-only) — perfect for audit trail

### What would have happened WITHOUT proper DB selection
- Using PostgreSQL for search: 10x slower, can't do geospatial
- Using PostgreSQL for chat: too much load, writes become bottleneck
- Using only one DB for everything: can't optimize for specific access patterns

### Problem solved
- Search returns results in < 100ms because Elasticsearch has inverted index
- Chat can handle 10,000 messages/second because Cassandra is optimized for writes
- Appointment booking is reliable because PostgreSQL gives ACID guarantees

### 💬 Say in Interview (Easy English)

*"In Arogyam, we use a polyglot persistence approach — different databases for
different use cases.*

*PostgreSQL is our primary database for structured data like patients, doctors,
and appointments — where we need ACID transactions. For example, when a patient
books an appointment, we need to atomically reserve the slot AND create the billing
record. If either fails, both roll back.*

*Redis handles our caching layer. A doctor profile might be requested thousands of
times per minute, so we cache it in Redis. We also use Redis for JWT blacklisting —
when a user logs out, we store their token in Redis with a TTL equal to the
token's expiry time.*

*Elasticsearch powers our search. PostgreSQL cannot efficiently do 'find all
cardiologists within 5km of this GPS coordinate' — that requires geospatial indexing.
Elasticsearch handles this in sub-millisecond.*

*And Cassandra stores chat messages. It's a wide-column store optimized for
time-series writes — perfect for millions of messages per day."*

---

## Topic 4: Caching Strategies (Redis)

### What is it?
Storing frequently accessed data in fast memory (Redis) so you don't hit the
slow database every time.

**Three main patterns:**

**Cache-Aside (Lazy Loading):**
```
App checks Redis → HIT? Return data
               → MISS? Fetch from DB → Store in Redis → Return data
Update DB → Delete from Redis (invalidate) → Next read rebuilds cache
```

**Write-Through:**
```
Write to DB AND Redis simultaneously
Reads always find data in cache
Drawback: writes are slightly slower
```

**Read-Through:**
```
App only talks to cache
Cache automatically fetches from DB on miss
App never directly queries DB
```

### Where we used it in Arogyam

```
Cache-Aside → Doctor/Patient profiles
  Why: Profile changes rarely, read very frequently
  Flow: GET /doctors/123 → check Redis → miss → query PostgreSQL
        → store in Redis for 10 minutes → return

Write-Through → Appointment slots + Auth tokens
  Why: Slots must be 100% consistent. Two patients cannot book same slot.
  Flow: Mark slot as TAKEN in PostgreSQL AND Redis simultaneously
        → Redis Distributed Lock prevents race condition

Read-Through → Search results from Elasticsearch
  Why: Search queries are expensive, same queries repeated often
  Flow: Search "cardiologist kolkata" → check Redis → miss
        → query Elasticsearch → cache for 5 minutes → return
```

### Why we used it
- Doctor profiles are read 100x more than written
- Without cache: every request hits PostgreSQL → slow + expensive
- With Redis cache: 99% of requests served from memory in < 1ms

### What would have happened WITHOUT caching
- PostgreSQL gets 10,000 hits/minute for doctor profiles
- Database becomes bottleneck, all requests slow down
- Double-booking: two patients book same slot if check-then-book is not atomic

### Problem solved
- 99% cache hit rate for doctor profiles → PostgreSQL load reduced 100x
- Zero double-bookings using Redis distributed lock during appointment booking

### 💬 Say in Interview (Easy English)

*"We use Redis for three different caching patterns in Arogyam.*

*For doctor and patient profiles, we use Cache-Aside. The profile is fetched from
PostgreSQL on the first request and cached in Redis for 10 minutes.
When a doctor updates their profile, we invalidate the cache so the next
read rebuilds it fresh.*

*For appointment slot booking, we use Write-Through with Redis Distributed Locks.
When a patient books a slot, we lock that slot in Redis before writing to the
database. This prevents race conditions where two patients could book the same
slot simultaneously — a critical healthcare use case.*

*For search results, we cache Elasticsearch responses in Redis. The same search
query 'cardiologist in Kolkata' gets cached for 5 minutes. This reduces
Elasticsearch load by 90% since the same popular searches repeat frequently."*

---

## Topic 5: JWT Authentication

### What is it?
A way to prove who you are to a server without the server storing session data.

```
User logs in → Server creates JWT (signed token) → Sends to client
Client stores JWT in memory/storage
Every request: Client sends JWT in header → Server verifies signature → Grants access
```

**JWT Structure:**
```
Header.Payload.Signature

Header:  {"alg": "HS256", "typ": "JWT"}
Payload: {"user_id": "123", "role": "PATIENT", "exp": 1234567890}
Signature: HMAC(header + payload, secret_key)
```

### Where we used it in Arogyam

```
Auth Service:
  POST /api/v1/auth/login
  → Validates email + password
  → Creates JWT with: user_id, email, role, exp (30 min)
  → Creates Refresh Token (7 days) stored in Redis
  → Returns both tokens

Patient Service (every protected endpoint):
  → Reads Authorization: Bearer <token> header
  → Calls Auth Service via gRPC: ValidateToken(token)
  → Auth Service returns: {valid: true, user_id: "123", role: "PATIENT"}
  → Patient Service proceeds with user_id

JWT Blacklist (logout):
  POST /api/v1/auth/logout
  → Stores token in Redis with TTL = remaining validity time
  → Every validation checks Redis blacklist first
```

### Why we used it
- **Stateless** — Auth Service doesn't store sessions. Any server can validate any token.
- **Self-contained** — Token carries user_id and role. Services don't need DB lookup.
- **Secure** — Signature ensures token wasn't tampered with.

### What would have happened WITHOUT JWT
- Session-based auth: Auth Service must store every user's session in DB
- Every request = DB query to check if session is valid → bottleneck
- Horizontal scaling is hard — all servers must access same session DB

### Problem solved
- Any service can validate JWT without calling Auth Service (signature verification)
- But we chose gRPC validation for centralized token revocation on logout
- Refresh tokens allow staying logged in without re-entering password

### 💬 Say in Interview (Easy English)

*"In Arogyam, we use JWT-based stateless authentication. When a user logs in,
the Auth Service creates a JWT containing their user ID, role (PATIENT, DOCTOR, ADMIN),
and expiry time. This token is signed with a secret key using HS256.*

*Every protected endpoint in Patient, Doctor, and Appointment services validates
this token by calling the Auth Service via gRPC. We chose gRPC over REST for
this because it's 5-10x faster and happens on every single API request.*

*For logout, we maintain a JWT blacklist in Redis. When a user logs out, their
token is stored in Redis with a TTL matching the token's remaining validity.
This way, even if someone steals the token after logout, it's rejected.*

*We also have Refresh Tokens — long-lived tokens (7 days) that allow getting
new Access Tokens (30 minutes) without re-login. This balances security
and user experience."*

---

# 🟡 LEVEL 2 — INTERMEDIATE TOPICS

---

## Topic 6: API Gateway (Kong)

### What is it?
A single entry point for all client requests. Clients talk to ONE URL,
the gateway routes to the correct microservice.

```
Client → Kong Gateway (:8000)
              │
    ┌─────────┼─────────┐
    ▼         ▼         ▼
Patient    Doctor    Search
Service    Service   Service
(:8002)   (:8003)   (:8006)
```

**Kong Gateway responsibilities:**
1. **Routing** — /api/v1/patients → Patient Service
2. **Authentication** — Validate JWT before forwarding
3. **Rate Limiting** — 100 requests/minute per IP
4. **Load Balancing** — Distribute across multiple instances
5. **Logging** — Log all requests centrally
6. **SSL Termination** — Handle HTTPS, forward HTTP internally

### Where we used it in Arogyam

```yaml
# kong.yml (declarative config)
services:
  - name: patient-service
    url: http://patient-service:8002
    routes:
      - paths: ["/api/v1/patients"]

  - name: doctor-service
    url: http://doctor-service:8003
    routes:
      - paths: ["/api/v1/doctors"]

  - name: search-service
    url: http://search-service:8006
    routes:
      - paths: ["/api/v1/search"]
```

**All traffic flows through port 8000:**
```
GET  http://localhost:8000/api/v1/patients   → Patient Service
GET  http://localhost:8000/api/v1/doctors    → Doctor Service
GET  http://localhost:8000/api/v1/search/... → Search Service
POST http://localhost:8000/api/v1/auth/login → Auth Service
```

### Why we used it
- Without gateway: frontend needs to know 6 different URLs and ports
- With gateway: frontend only knows ONE URL — `http://api.arogyam.com`
- Centralized rate limiting — no need to implement in every service
- Centralized logging — one place to see all request logs

### What would have happened WITHOUT API Gateway
- Frontend: hardcode `localhost:8002`, `localhost:8003`, `localhost:8006` — nightmare
- Rate limiting code duplicated in every service
- CORS handling in every service
- If Doctor Service URL changes, update all frontends

### Problem solved
- Single URL for all services → frontend simplicity
- Rate limiting stops DDoS: 100 req/min per IP, returns 429 if exceeded
- Idempotency Key support: prevents duplicate appointment bookings on network retry

### 💬 Say in Interview (Easy English)

*"We use Kong as our API Gateway — it's the single entry point for all client requests.*

*Kong runs on port 8000 and routes requests based on path prefixes.
/api/v1/patients goes to Patient Service, /api/v1/doctors goes to Doctor Service,
and so on. The frontend only knows one URL and Kong handles all the routing.*

*Kong also enforces rate limiting at 100 requests per minute per IP address
to protect against abuse. If someone exceeds this, they get a 429 response.*

*Another benefit is centralized logging — every request across all services is
logged in one place. Without a gateway, we'd need to implement logging,
rate limiting, and CORS in every single service separately — a lot of
duplication and inconsistency."*

---

## Topic 7: Apache Kafka (Event-Driven Architecture)

### What is it?
A message queue where services publish events and other services consume them
asynchronously. Services are decoupled — they don't call each other directly.

```
Without Kafka (tight coupling):
Appointment Service → directly calls → Notification Service
                   → directly calls → Billing Service
                   → directly calls → Audit Service
(If any of these fail, the appointment booking fails!)

With Kafka (loose coupling):
Appointment Service → publishes → "appointment.created.v1" event to Kafka
                                              │
                          ┌───────────────────┼───────────────────┐
                          ▼                   ▼                   ▼
              Notification Service    Billing Service      Audit Service
              (consumes, sends push)  (consumes, creates   (consumes, logs
                                       invoice)             action)
```

### Where we used it in Arogyam

**Topics:**
```
appointment.created.v1
appointment.cancelled.v1
appointment.updated.v1
auth.user.registered.v1
doctor.profile.updated.v1
payment.success.v1
payment.failed.v1
```

**Published by:**
- Appointment Service → appointment.* events
- Auth Service → auth.user.registered.v1
- Billing Service → payment.* events

**Consumed by:**
- Notification Service → sends push notifications
- Billing Service → creates invoices
- Audit Service → logs all actions
- Search Service → updates Elasticsearch when doctor profile changes (CQRS)

### Why we used it

**Reliability:** If Notification Service is down, Kafka stores the event.
When Notification Service comes back up, it processes all missed events.
Without Kafka: appointment created but notification never sent.

**Decoupling:** Appointment Service doesn't know or care about Notification Service.
New services can be added without changing Appointment Service.

**Scale:** Multiple consumers can process events in parallel.
1 appointment created → processed by 3 different services simultaneously.

### What would have happened WITHOUT Kafka
- Appointment Service must directly call Notification + Billing + Audit
- If Notification Service is slow, appointment booking becomes slow
- If Notification Service crashes, appointment booking fails
- Adding new consumer requires changing Appointment Service code

### Problem solved
- Appointment booking is fast — publishes to Kafka (async) and returns success
- Even if Notification Service is down for 1 hour, all events are queued and
  processed when it comes back up — zero notification loss
- Adding Analytics Service later: just subscribe to existing topics, no other changes

### 💬 Say in Interview (Easy English)

*"We use Apache Kafka for asynchronous, event-driven communication between services.*

*When a patient books an appointment, the Appointment Service publishes an
'appointment.created.v1' event to Kafka and immediately returns a 200 response
to the user. Three consumers process this event independently:
Notification Service sends a push notification, Billing Service creates an invoice,
and Audit Service logs the action.*

*The key benefit is reliability and decoupling. If the Notification Service is
down for an hour, Kafka stores all events. When it comes back up, it processes
everything in order — zero notification loss.*

*Without Kafka, the Appointment Service would need to synchronously call all
three services. If any one of them is slow or down, the patient's booking request
would fail or timeout — very bad user experience for a healthcare app."*

---

## Topic 8: gRPC (Internal Service Communication)

### What is it?
A high-performance RPC (Remote Procedure Call) framework.
Uses Protocol Buffers (binary format) instead of JSON.
Much faster than REST for internal service-to-service calls.

**REST vs gRPC:**
```
REST:  JSON (text) → serialize → HTTP → deserialize → JSON
gRPC:  Protobuf (binary) → serialize → HTTP/2 → deserialize → object
       → 5-10x smaller payload, 3-5x faster
```

### Where we used it in Arogyam

**auth.proto:**
```protobuf
service AuthService {
  rpc ValidateToken(ValidateTokenRequest) returns (ValidateTokenResponse);
  rpc GetUserInfo(GetUserInfoRequest) returns (UserInfoResponse);
}

message ValidateTokenRequest {
  string token = 1;
}

message ValidateTokenResponse {
  bool is_valid = 1;
  string user_id = 2;
  string role = 3;
  string email = 4;
}
```

**Flow:**
```
Patient makes API call with JWT token
→ Patient Service receives request
→ Patient Service calls Auth Service via gRPC:
    AuthServiceStub.ValidateToken(token)
→ Auth Service validates token
→ Returns: {is_valid: true, user_id: "123", role: "PATIENT"}
→ Patient Service proceeds with the request
```

**Why gRPC on port 50051 (Auth) and 50054 (Appointment):**
- Auth Service gRPC: Port 50051 (validates tokens for all services)
- Appointment Service gRPC: Port 50054 (checks doctor availability)

### Why we used it (instead of REST internally)
- Token validation happens on EVERY request — must be as fast as possible
- gRPC is 3-5x faster than REST → significant latency improvement
- Strict schema via .proto files → compile-time type safety
- Auto-generated client code in Java, Python, Go

### What would have happened WITHOUT gRPC
- REST call for token validation: ~20-50ms per request
- gRPC call for token validation: ~5-10ms per request
- On high traffic (1000 req/sec), this difference matters enormously
- No contract enforcement — REST allows sending any JSON structure

### Problem solved
- Token validation adds only ~5ms overhead (vs ~30ms with REST)
- .proto files serve as API contracts — if Auth Service changes, all clients
  fail at compile time, not at runtime

### 💬 Say in Interview (Easy English)

*"For internal service-to-service communication, we use gRPC instead of REST.*

*The main use case is token validation. Every API request to Patient, Doctor,
or Appointment Service needs to validate the JWT token by calling the Auth Service.
This happens thousands of times per minute.*

*With gRPC, this validation takes about 5 milliseconds. With REST, it would be
20-30 milliseconds. When you multiply that by thousands of requests per minute,
gRPC saves significant latency.*

*We defined the contract in auth.proto — a schema file that defines the
ValidateToken RPC method. The Java client in Patient Service and the Python
client in Appointment Service are both auto-generated from this same .proto file.
This means if the Auth Service API changes, all clients fail at compile time,
not in production — which is exactly what you want in a healthcare platform
where reliability is critical."*

---

## Topic 9: CQRS Pattern

### What is it?
Command Query Responsibility Segregation — using different models for
reading and writing data.

```
Command (Write): Patient Service writes doctor profile → PostgreSQL
Query (Read):   User searches doctors → Elasticsearch

CQRS Flow:
Doctor updates profile (Command)
    → Write to PostgreSQL (source of truth)
    → Publish "doctor.updated.v1" to Kafka
    → Search Service consumes event
    → Updates Elasticsearch (read model)

Patient searches doctors (Query)
    → Query Elasticsearch only
    → Never touches PostgreSQL
```

### Where we used it in Arogyam

**Without CQRS (bad):**
```
Patient searches "cardiologist in Kolkata"
→ PostgreSQL query with LIKE '%cardiologist%' + geospatial join
→ Full table scan on 100,000 doctors
→ Slow (2-5 seconds), kills database
```

**With CQRS (good):**
```
Doctor Service writes to PostgreSQL (Command)
    → Publishes Kafka event
    → Search Service syncs to Elasticsearch

Patient searches (Query)
    → Elasticsearch: inverted index lookup
    → Returns in < 100ms
    → PostgreSQL is untouched
```

### Why we used it
- PostgreSQL is great for writes (ACID) but bad for complex searches
- Elasticsearch is great for searches but bad for transactions
- CQRS lets us use the right tool for each job
- Write workloads and read workloads scaled independently

### What would have happened WITHOUT CQRS
- Search queries would hammer PostgreSQL
- Complex LIKE queries + geospatial = seconds of response time
- As data grows, search gets slower and slower
- High read load would starve write operations (appointment booking)

### Problem solved
- Doctor search returns in < 100ms even with 1 million doctors
- PostgreSQL is freed from search load — can focus on transactional writes
- Elasticsearch automatically ranks results by relevance (rating, distance, availability)

### 💬 Say in Interview (Easy English)

*"We apply CQRS in our Search architecture. The write model lives in PostgreSQL —
when a doctor updates their profile, it writes to PostgreSQL.*

*But when a patient searches for 'cardiologist within 5km of Kolkata with
rating above 4', that query hits Elasticsearch, not PostgreSQL.*

*The synchronization happens via Kafka. When a doctor profile is updated,
the Doctor Service publishes a 'doctor.updated.v1' event to Kafka.
The Search Service consumes this event and updates Elasticsearch.*

*Without CQRS, we'd run complex geospatial + full-text searches directly on
PostgreSQL — this would be 10-50x slower and would put enormous load on the
primary database, affecting booking and registration performance.*

*CQRS lets us optimize each model independently — PostgreSQL for reliable
writes, Elasticsearch for fast reads."*

---

## Topic 10: CAP Theorem

### What is it?
In a distributed system, you can only guarantee 2 out of 3:
- **C**onsistency — all nodes see the same data at the same time
- **A**vailability — system always responds (never returns error)
- **P**artition Tolerance — system works even if network between nodes fails

Network partitions ALWAYS happen eventually → you MUST choose P.
So real choice is: **CP** (Consistency + Partition) or **AP** (Availability + Partition)

### Where we used it in Arogyam

| Database | Choice | Reason |
|----------|--------|--------|
| PostgreSQL | **CP** | Appointment bookings must be consistent. Cannot show "slot available" to two patients simultaneously. |
| Redis | **CP** | JWT tokens and cache must be consistent. |
| Elasticsearch | **AP** | Search results can be slightly stale (1-2 seconds behind). Patient can still search. |
| Cassandra | **AP** | Chat messages must always be readable, even if some nodes fail. Slightly stale is okay. |

### Why this matters for Arogyam
**Appointment booking → Must be CP:**
- Two patients CANNOT see the same slot as available
- One must get the booking, one must see "slot taken"
- Consistency > Availability for financial/healthcare transactions

**Chat messages → Can be AP:**
- If a network partition happens, doctor should still be able to read past messages
- Slightly stale data (missing 1-2 latest messages) is acceptable
- Availability > Consistency for chat

### 💬 Say in Interview (Easy English)

*"We made conscious CAP theorem trade-offs for different components of Arogyam.*

*For appointment booking, we chose CP — Consistency over Availability.
If two patients try to book the same slot simultaneously, the system must ensure
only one succeeds. We cannot allow both to see the slot as available — that would
be a double-booking, which is unacceptable in a healthcare context.*

*For our chat system using Cassandra, we chose AP — Availability over Consistency.
Even if some Cassandra nodes fail due to a network partition, the chat should still
work with whatever nodes are available. A doctor seeing a slightly stale chat history
is acceptable — but the chat being completely unavailable is not.*

*For Search using Elasticsearch, we also chose AP — search results can be 1-2 seconds
behind the latest doctor profile update. This is fine — the user can still search
and find doctors even during partial failures."*

---

# 🔴 LEVEL 3 — ADVANCED TOPICS

---

## Topic 11: Saga Pattern (Distributed Transactions)

### What is it?
In microservices, you can't use traditional database transactions (ACID)
across multiple services. Saga Pattern solves this with a sequence of local
transactions and compensating transactions (rollbacks).

**Two types:**
1. **Choreography** (Event-driven) — services react to events from Kafka
2. **Orchestration** — a central coordinator tells each service what to do

### Where we used it in Arogyam

**Appointment Booking Saga (Choreography via Kafka):**

**Happy Path:**
```
1. Patient clicks "Book" → Appointment Service creates PENDING appointment
2. Publishes: appointment.created.v1
3. Billing Service consumes → creates PENDING invoice
4. Patient pays → Billing Service publishes: payment.success.v1
5. Appointment Service consumes → updates appointment to CONFIRMED
6. Notification Service publishes: push "Appointment Confirmed!"
```

**Failure Path (payment fails):**
```
1-3. Same as above
4. Patient's payment fails → Billing publishes: payment.failed.v1
5. Appointment Service consumes payment.failed.v1
   → Compensating transaction: appointment status → CANCELLED
6. Notification: push "Booking failed — payment unsuccessful"
7. Calendar/slot freed up again
```

### Why we used it
- Cannot do a single DB transaction across Appointment + Billing databases
- They're separate services with separate databases
- Saga ensures eventual consistency across all services

### What would have happened WITHOUT Saga
- Appointment created but payment never confirmed → appointment stays PENDING forever
- Patient charged but appointment not created → angry patient
- No rollback mechanism = data inconsistency across services

### Problem solved
- System remains consistent even across 3+ services
- Each failure triggers automatic compensating actions
- Patient always gets clear feedback — success or failure with reason

### 💬 Say in Interview (Easy English)

*"For the appointment booking flow, we implement the Saga pattern using
Kafka choreography.*

*When a patient books an appointment, the Appointment Service creates a PENDING
appointment and publishes an 'appointment.created.v1' event. The Billing Service
listens, creates a pending invoice, and the patient pays. On successful payment,
a 'payment.success.v1' event is published, and the Appointment Service updates
the booking to CONFIRMED.*

*The interesting part is the failure path. If payment fails, the Billing Service
publishes 'payment.failed.v1'. The Appointment Service consumes this and runs
a compensating transaction — cancelling the appointment and freeing the slot.
A push notification informs the patient.*

*Without the Saga pattern, we'd have no way to ensure consistency across three
independent services — Appointment, Billing, and Notification — each with their
own databases. This could lead to patients being charged without a confirmed
appointment, which is unacceptable."*

---

## Topic 12: Circuit Breaker Pattern

### What is it?
Prevents a cascading failure when a downstream service is unavailable.
Like an electrical circuit breaker that trips to protect from overload.

**States:**
```
CLOSED (normal) → requests flow through
    ↓ (failures exceed threshold, e.g. 5 failures in 10 seconds)
OPEN (broken) → immediately reject requests, don't even try
    ↓ (after timeout, e.g. 30 seconds)
HALF-OPEN → allow 1 test request
    ↓ success → CLOSED
    ↓ failure → OPEN again
```

### Where we used it in Arogyam

**Scenario: Auth Service is down**

**Without circuit breaker:**
```
1000 requests/second come to Patient Service
Each waits 30 seconds for Auth Service timeout
→ 30,000 pending requests pile up
→ Patient Service memory/threads exhausted
→ Patient Service crashes too
→ Doctor Service calls Patient Service → also crashes
→ Entire platform down (cascading failure)
```

**With circuit breaker:**
```
Auth Service goes down
First 5 requests fail → Circuit OPENS
Next requests: immediately return "Auth service unavailable" (no wait)
After 30 seconds: Circuit HALF-OPEN → test 1 request
If Auth is back: Circuit CLOSES → normal operation resumes
```

### Why we used it
- Protects healthy services from being dragged down by unhealthy ones
- Fail fast instead of timeout — better user experience
- Automatic recovery when downstream service heals

### What would have happened WITHOUT circuit breaker
- One service going down could take down the entire platform
- Users wait 30 seconds for timeout instead of immediate error
- Thread pool exhaustion leads to cascading failures

### 💬 Say in Interview (Easy English)

*"We implement the Circuit Breaker pattern for calls between services,
particularly for the gRPC calls to the Auth Service.*

*If the Auth Service starts failing — say, due to a database overload —
the circuit breaker detects 5 consecutive failures and trips to OPEN state.
In this state, all subsequent requests to Auth Service are immediately rejected
with a fallback response, without even attempting the connection.*

*This is critical because without it, every incoming request to Patient Service
would wait 30 seconds for the Auth Service timeout. With 1000 requests per second,
that's 30,000 pending requests piling up — Patient Service would exhaust its
thread pool and crash, then Doctor Service calling Patient Service would also
crash — a full cascading failure.*

*After 30 seconds, the circuit enters HALF-OPEN state and allows one test request.
If Auth Service has recovered, the circuit CLOSES and normal operation resumes
automatically."*

---

## Topic 13: Rate Limiting

### What is it?
Limiting how many requests a client can make in a time window.
Protects your API from abuse, DDoS, and bot attacks.

**Algorithms:**
- **Fixed Window:** 100 requests per minute. Counter resets at :00 every minute.
  Problem: 100 at :59, 100 at :01 = 200 in 2 seconds
- **Sliding Window:** Tracks last 60 seconds continuously. More accurate.
- **Token Bucket:** Bucket fills at rate R, each request consumes 1 token.
  Allows bursts up to bucket size.
- **Leaky Bucket:** Requests drip out at constant rate, excess overflow.

### Where we used it in Arogyam

**Kong Gateway rate limiting:**
```
Plugin: rate-limiting
config:
  minute: 100        → 100 requests per minute per IP
  policy: redis      → store counters in Redis
  error_code: 429    → return 429 when exceeded
  error_message: "Rate limit exceeded. Try again in 60 seconds."
```

**Special limits (planned):**
```
/api/v1/auth/login → 5 attempts per minute (prevent brute force)
/api/v1/auth/register → 3 registrations per hour per IP
/api/v1/search → 30 requests per minute (Elasticsearch protection)
```

**Idempotency Key (Stripe Pattern):**
```
POST /api/v1/appointments
Headers: Idempotency-Key: "uuid-abc-123"
→ First call: creates appointment, stores result with key in Redis (24hr TTL)
→ Retry call (same key): returns cached result, does NOT create duplicate
```

### Why we used it
- Without rate limiting: one bad actor sends 10,000 requests/second → server crashes
- Login endpoint especially dangerous: bots try millions of passwords (brute force)
- Idempotency prevents duplicate bookings when network causes retries

### 💬 Say in Interview (Easy English)

*"Rate limiting is enforced at the Kong Gateway level in Arogyam.*

*We limit each IP to 100 requests per minute across all endpoints.
For sensitive endpoints like login, the limit is stricter — 5 attempts per minute —
to prevent brute force password attacks. The counters are stored in Redis,
which allows the limit to work correctly even if we scale to multiple Kong instances.*

*We also implement the Idempotency Key pattern for appointment creation,
inspired by Stripe's API design. The client sends a unique Idempotency-Key header
with each POST /appointments request. If the network fails and the client retries,
Kong checks if this key was already processed. If yes, it returns the cached result
without creating a duplicate appointment.*

*This is especially important in healthcare — imagine a patient clicking
'Book Appointment' twice due to a slow connection and getting charged twice.
Idempotency prevents exactly this."*

---

## Topic 14: WebSockets & Real-Time Communication

### What is it?
HTTP is request-response — client asks, server responds.
WebSocket is a persistent, bidirectional connection.
Server can PUSH data to client without client asking.

```
HTTP (polling):  Client asks "any new messages?" every 2 seconds
WebSocket:       Server pushes message instantly when it arrives
```

### Where we used it in Arogyam

**Messaging Service (Chat):**
```
Doctor and Patient connect via Socket.io WebSocket
Doctor types → 'message:send' event → Server → Cassandra
Server → 'message:received' event → Patient (instantly)
Patient sees message in < 100ms
```

**Queue Tracking:**
```
Patient waiting in doctor's queue
Server pushes 'queue.position' event every time position changes
Patient sees live: "You are #3 in queue. ~15 minutes wait"
No page refresh needed
```

**Video Call Signaling:**
```
Doctor opens video room
Patient joins → Socket.io 'join-room' event
Server sends Doctor's SDP 'offer' to Patient via WebSocket
Patient sends 'answer' back via WebSocket
They exchange ICE candidates via WebSocket
→ P2P WebRTC connection established
→ Video/audio flows directly P2P (no server relay)
```

### 💬 Say in Interview (Easy English)

*"We use WebSockets in two key places in Arogyam.*

*First, for real-time chat between doctors and patients in the Messaging Service.
Using Socket.io, we maintain persistent connections. When a doctor sends a message,
it goes to the server, gets stored in Cassandra, and is immediately pushed to
the patient's connection. The latency is under 100 milliseconds.*

*Second, for WebRTC video call signaling. WebRTC requires an exchange of
connection details (SDP offer/answer and ICE candidates) before establishing
a peer-to-peer connection. We use WebSocket as the signaling channel for this
exchange. Once the P2P connection is established, video and audio flow directly
between the doctor's and patient's browsers — our server is no longer in the
data path, which means zero server load for the video stream itself."*

---

## 🎯 MASTER LIST — Quick Reference

| Topic | Your Project Example | Key Phrase |
|-------|---------------------|------------|
| Microservices | 6 independent services, each with own DB | "Independent scaling and deployment" |
| REST API | GET/POST/PATCH on /api/v1/patients | "Resource-based URLs, proper status codes" |
| SQL vs NoSQL | PostgreSQL + Redis + Elasticsearch + Cassandra | "Right database for right use case" |
| Caching | Redis Cache-Aside for profiles, Write-Through for slots | "Cache-Aside with invalidation on update" |
| JWT Auth | Auth Service issues JWT, gRPC validates | "Stateless auth with Redis blacklist for logout" |
| API Gateway | Kong routing all traffic on port 8000 | "Single entry point, centralized rate limiting" |
| Kafka | appointment.created.v1 → Notification + Billing | "Async decoupling, zero message loss" |
| gRPC | Token validation on every request | "5-10x faster than REST, typed contracts" |
| CQRS | Write to PostgreSQL, Read from Elasticsearch | "Separate read/write models for performance" |
| CAP Theorem | PostgreSQL=CP, Cassandra=AP | "Chose CP for transactions, AP for chat" |
| Saga Pattern | Appointment+Billing+Notification flow | "Compensating transactions for rollback" |
| Circuit Breaker | Auth Service down → immediate reject | "Prevents cascading failures" |
| Rate Limiting | 100 req/min via Kong + Redis counter | "Kong + Redis, Idempotency for bookings" |
| WebSockets | Chat messages, queue updates, video signaling | "Real-time bidirectional push" |

---

## 📅 Study Plan (8 Weeks)

```
Week 1: Topics 1-5 (Level 1) — understand + practice saying aloud
Week 2: Topics 1-5 — mock interview with friend/mirror
Week 3: Topics 6-9 (Level 2) — understand + practice
Week 4: Topics 6-9 — mock interview
Week 5: Topics 10-14 (Level 3) — understand + practice
Week 6: Topics 10-14 — mock interview
Week 7: Full mock interviews (all topics)
Week 8: Review weak areas + read ByteByteGo / System Design Primer
```

## 📚 Resources

| Resource | Link | Use |
|----------|------|-----|
| System Design Primer | github.com/donnemartin/system-design-primer | Best free comprehensive resource |
| ByteByteGo | youtube.com/@ByteByteGo | Visual explanations (watch 2/day) |
| Grokking System Design | educative.io | Structured paid course |
| Martin Fowler | martinfowler.com | Patterns deep-dive |
| High Scalability | highscalability.com | Real-world case studies |
