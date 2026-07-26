# 🚀 Arogyam Healthcare Platform - System Design Master Interview Notes

এই ডকুমেন্টটি **Arogyam Healthcare Platform**-এর ৩২টি সিস্টেম ডিজাইন কনসেপ্টের একটি বিস্তারিত ও পূর্ণাঙ্গ গাইডলাইন। ইন্টারভিউতে যেকোনো ক্রস-কোশ্চেনের উত্তর দেওয়ার জন্য প্রতিটি টপিক **কী (What)**, **কেন (Why)**, **কোথায় (Where in Arogyam)**, **কীভাবে (How)**, **সহজ উদাহরণ (Analogy)** এবং **ইন্টারভিউ ক্রস-কোশ্চেন (Cross Question)** ফরম্যাটে সাজানো হয়েছে।

---

## 🏛️ ক্যাটাগরি ১: Macro Architecture & Data Storage

### 1. Microservices Architecture (Domain-Driven Design)
* **কী (What):** একটি বিশাল মনোলিথিক অ্যাপ্লিকেশনকে ব্যবসার ডোমেন বাউন্ডারি (Bounded Context) অনুযায়ী স্বাধীন ও আলাদা অ্যাপ্লিকেশনে বিভক্ত করা।
* **কেন (Why):** Monolith-এ একটি মডিউল (যেমন: হেলথ রিপোর্ট) ক্র্যাশ করলে পুরো সার্ভিস বন্ধ হয়ে যায় এবং স্কেল করা কঠিন হয়। Microservices-এ প্রতিটি সার্ভিস স্বাধীনভাবে ডেভলপ, ডিপ্লয় ও স্কেল করা যায়।
* **কোথায় (Where in Arogyam):** Arogyam-কে ১৮টি ডিকাপল্ড সার্ভিসে ভাগ করা হয়েছে (Core: Identity, Patient, Doctor, Appointment, Health Record, Pharmacy; Supporting: Search, Messaging, Video Call, Payment, Notification, Audit, Analytics ইত্যাদি)।
* **কীভাবে (How):** Domain-Driven Design (DDD) মেনে প্রতিটি সার্ভিস নিজস্ব ডোমেন লজিক চালায়। ইন্টার-সার্ভিস কমিউনিকেশন gRPC ও Apache Kafka দিয়ে হয়।
* **সহজ উদাহরণ (Analogy):** একটি বড় শপিং মল। যেখানে কাপড়, জুতো, এবং গ্রোসারি শপের আলাদা আলাদা ম্যানেজার ও ক্যাশ কাউন্টার থাকে। একটি দোকান বন্ধ হলেও অন্য দোকান খোলা থাকে।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Microservices-এর প্রধান অসুবিধা কী?* 
  - **উত্তর:** Network Latency, Data Consistency (ACID না থাকা) এবং Distributed Tracing/Debugging জটিলতা।

---

### 2. Database-per-Service Pattern
* **কী (What):** প্রতিটি মাইক্রোসার্ভিসের নিজস্ব আলাদা ডাটাবেস থাকবে, কোনো সার্ভিস অন্য সার্ভিসের ডাটাবেসে সরাসরি অ্যাক্সেস করতে পারবে না।
* **কেন (Why):** শেয়ার্ড ডাটাবেসে একাধিক সার্ভিস একই টেবিলে ক্যোয়ারি বা স্কিমা মাইগ্রেশন করলে টেবিল লক হয়ে অন্য সার্ভিস ধীরগতির বা ক্র্যাশ হয়ে যায়।
* **কোথায় (Where in Arogyam):** 
  - Identity Service ➔ `Identity DB` (PostgreSQL)
  - Doctor Service ➔ `Doctor DB` (PostgreSQL)
  - Patient Service ➔ `Patient DB` (PostgreSQL)
  - Appointment Service ➔ `Appointment DB` (PostgreSQL)
  - Messaging Service ➔ `Messaging DB` (Cassandra)
* **কীভাবে (How):** সার্ভিসগুলোর ডাটাবেসের মধ্যে সরাসরি Foreign Key রিলেশন থাকে না। সার্ভিসগুলো API বা Kafka Event-এর মাধ্যমে ডাটা আদান-প্রদান করে।
* **সহজ উদাহরণ (Analogy):** আলাদা ব্যাংক একাউন্ট। রামের ব্যাংক ব্যালেন্স দেখতে হলে শ্যাম সরাসরি রামের ওয়ালেটে হাত দেয় না, ব্যাংক অফিশিয়াল API/ব্যাংক স্টেটমেন্টের মাধ্যমে নেয়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *ডাটাবেস আলাদা হলে Join Query কীভাবে করবেন?*
  - **উত্তর:** Application Layer-এ API Composition করে অথবা CQRS Pattern ব্যবহার করে Read Database (Elasticsearch)-এ আগাম ডাটা সিঙ্ক করে রিড করা হয়।

---

### 3. Polyglot Persistence
* **কী (What):** অ্যাপ্লিকেশনের কাজের ধরন ও ডেটার বৈশিষ্ট্য অনুযায়ী আলাদা আলাদা ডাটাবেস ইঞ্জিন (Relational, NoSQL, Columnar, Search) ব্যবহার করা।
* **কেন (Why):** "One Size Fits All" ডাটাবেস বলে কিছু নেই। Relational DB ভালো ট্রানজাকশনে, Cassandra ভালো রাইটে, Elasticsearch ভালো ফাজি সার্চে।
* **কোথায় (Where in Arogyam):**
  - **PostgreSQL (OLTP):** Identity, Patient, Doctor, Appointment (ACID ট্রানজাকশনের জন্য)।
  - **Cassandra (NoSQL Columnar):** Messaging Service (সেকেন্ডে লাখ লাখ চ্যাট মেসেজ রাইটের জন্য)।
  - **Elasticsearch + PostGIS:** Search Service (লোকেশন সার্চ ও ফাজি সার্চের জন্য)।
  - **ClickHouse (OLAP Columnar):** Analytics Service (বিলিয়ন রো-এর দ্রুত রিপোর্টিংয়ের জন্য)।
  - **Redis Cluster:** ক্যাশিং ও ডিস্ট্রিবিউটেড লকিংয়ের জন্য।
* **কীভাবে (How):** প্রতিটি মাইক্রোসার্ভিস তার প্রয়োজনের উপযোগী ডাটাবেস ড্রাইভার দিয়ে যুক্ত থাকে।
* **সহজ উদাহরণ (Analogy):** গ্যারেজে গাড়ি, বাইক এবং ট্রাক রাখা। স্পিডের জন্য বাইক, মালামাল বহনের জন্য ট্রাক ব্যবহার করা।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Polyglot Persistence-এর চ্যালেঞ্জ কী?*
  - **উত্তর:** DevOps ও DB Admin-দের একাধিক ডাটাবেস মেইনটেইন করার ব্যাকআপ ও সিকিউরিটি ওভারহেড বেড়ে যায়।

---

### 4. Event-Driven Architecture (EDA)
* **কী (What):** সার্ভিসগুলোর মধ্যে সরাসরি সিঙ্ক্রোনাস কল না করে ইভেন্ট (Event) ফায়ার করে অসিনক্রোনাস কমিউনিকেশন করা।
* **কেন (Why):** Synchronous HTTP/REST কলে একটি সার্ভিস স্লো হলে পুরো চেইন আটকে যায় (Temporal Coupling)। EDA-তে সার্ভিসগুলো নন-ব্লকিংভাবে দ্রুত কাজ শেষ করতে পারে।
* **কোথায় (Where in Arogyam):** **Apache Kafka**-কে প্ল্যাটফর্মের ইভেন্ট ব্যাকবোন হিসেবে ব্যবহার করা হয়েছে।
* **কীভাবে (How):** পেশেন্ট অ্যাপয়েন্টমেন্ট বুক করলে `Appointment Service` Kafka-তে `AppointmentCreated` ইভেন্ট ফায়ার করে। ব্যাকগ্রাউন্ডে থাকা `Payment`, `Notification`, এবং `Audit Service` ইভেন্টটি প্রসেস করে।
* **সহজ উদাহরণ (Analogy):** রেস্তোরাঁয় বয় ওয়েটারকে অর্ডারের স্লিপ বোর্ডে আটকে দেওয়া। বাবুর্চি, কোল্ড ড্রিঙ্কস বয় এবং বিলিং কাউন্টার তাদের সুবিধা মতো বোর্ড দেখে কাজ করে নেয়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Event-Driven Architecture-এ Eventual Consistency কীভাবে সামলানো হয়?*
  - **উত্তর:** Saga Pattern এবং Outbox/Inbox Pattern ব্যবহার করে সিস্টেমের ডাটা সাময়িকভাবে হলেও দিনশেষে সামঞ্জস্যপূর্ণ রাখা হয়।

---

### 5. CQRS (Command Query Responsibility Segregation)
* **কী (What):** ডাটাবেসের ডাটা রাইট করার লজিক (Command) এবং ডাটা রিড করার লজিক (Query)-কে সম্পূর্ণ আলাদা ডাটাবেসে ভাগ করা।
* **কেন (Why):** ৫০,০০০ ডাক্তারের স্পেশালিটি, লোকেশন ও ফি দিয়ে সার্চ করার জটিল কোয়েরি যদি প্রাইমারি PostgreSQL-এ করা হয়, তবে বুকিং ট্রানজাকশন স্লো হয়ে যাবে।
* **কোথায় (Where in Arogyam):** `Doctor Service` (PostgreSQL - Command) এবং `Search Service` (Elasticsearch + PostGIS - Query)।
* **কীভাবে (How):** 
  1. ডাক্তার প্রোফাইল আপডেট করলে তা PostgreSQL-এ সেভ হয়।
  2. `DoctorProfileUpdated` ইভেন্ট ক্যফকাতে যায়।
  3. `Search Service` ক্যফকা থেকে ইভেন্ট শুনে Elasticsearch ডাটাবেস আপডেট করে দেয়। পেশেন্টদের সব সার্চ সরাসরি Elasticsearch-এ হয় (<১৫ms)।
* **সহজ উদাহরণ (Analogy):** রেস্তোরাঁর রান্নাঘর (PostgreSQL Write DB) এবং বাইরের নোটিশ মেনু বোর্ড (Elasticsearch Read DB)। কাস্টমাররা মেনু বোর্ড পড়ে অর্ডার দেয়, রান্নাঘরে ভিড় করে না।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Write DB থেকে Read DB-তে ডাটা সিঙ্ক হতে দেরি হলে (Lag) কী হবে?*
  - **উত্তর:** CQRS সিস্টেমে সাময়িক Eventual Consistency থাকে। ইউজারকে UI-তে Optimistic Response বা Loading Indicator দিয়ে হ্যান্ডেল করা হয়।

---

### 6. API Gateway Pattern (Kong/Custom)
* **কী (What):** ক্লায়েন্ট এবং মাইক্রোসার্ভিসগুলোর মাঝে একক এন্ট্রি পয়েন্ট হিসেবে কাজ করা রিভার্স প্রক্সি।
* **কেন (Why):** বাইরের অ্যাপকে সরাসরি ১৮টি মাইক্রোসার্ভিসের IP দিলে সিকিউরিটি ইস্যু হয় এবং প্রতিটি সার্ভিসে আলাদা করে Auth/Rate Limit লিখতে হয়।
* **কোথায় (Where in Arogyam):** ক্লায়েন্ট অ্যাপ (Patient Portal, Doctor Portal) এবং Kubernetes Cluster-এর ঠিক মাঝখানে।
* **কীভাবে (How):** মিডলওয়্যার চেইন সামলায়:
  1. **Authentication:** JWT টোকেন ভ্যালিডেশন।
  2. **Authorization:** RBAC পারমিশন চেক।
  3. **Rate Limiting:** Redis দিয়ে DDoS আটকানো।
  4. **Validation:** API Payload চেক।
  5. **Tracing:** OpenTelemetry TraceID জেনারেট।
  6. **Routing:** অভ্যন্তরীণ Pod-এ ফরোয়ার্ড।
* **সহজ উদাহরণ (Analogy):** অ্যাপার্টমেন্ট বিল্ডিংয়ের রিসিভশন বা সিকিউরিটি গার্ড। যে কাউকে ভেতরে না ঢুকতে দিয়ে আইডি চেক করে সঠিক ফ্লোরে পাঠিয়ে দেয়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *API Gateway নিজেই Single Point of Failure (SPOF) হলে কীভাবে আটকাবেন?*
  - **উত্তর:** API Gateway-কে একাধিক ইনস্ট্যান্সে স্কেল করে সামনে Cloudflare CDN / Layer-4 Load Balancer (NLB) ব্যবহার করা হয়।

---

## 🔄 ক্যাটাগরি ২: Distributed Data & Transaction Patterns

### 7. Saga Choreography Pattern
* **কী (What):** ডিস্ট্রিবিউটেড মাইক্রোসার্ভিসে সেন্ট্রাল ডাটাবেস ট্রানজাকশন ছাড়া অসিনক্রোনাস ইভেন্ট এবং Compensating Transaction দিয়ে ডাটা কনসিস্টেন্সি বজায় রাখা।
* **কেন (Why):** 2-Phase Commit (2PC) স্লো ও ব্লকিং। মাইক্রোসার্ভিসে সরাসরি SQL Rollback করা যায় না।
* **কোথায় (Where in Arogyam):** Appointment Booking ও Payment ফ্লোতে।
* **কীভাবে (How):** 
  1. `Appointment Service` অ্যাপয়েন্টমেন্ট `PENDING` করে `AppointmentCreated` ফায়ার করে।
  2. `Payment Service` পেমেন্ট ট্রাই করে ফেল করলে `PaymentFailed` ফায়ার করে।
  3. `Appointment Service` ক্ষতিপূরণমূলক কাজ (Compensating Action) হিসেবে স্টেটাস `CANCELLED` করে স্লট রিলিজ করে দেয়।
* **সহজ উদাহরণ (Analogy):** অনলাইন শপিং। পেমেন্ট ফেল হলে ওয়েবসাইট নিজে থেকেই অর্ডার ক্যানসেল করে এবং রিজার্ভ আইটেম স্টক ব্যাক করে দেয়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Choreography এবং Orchestration Saga-এর পার্থক্য কী?*
  - **উত্তর:** Choreography-তে কোনো কেন্দ্রীয় কন্ডাক্টর থাকে না (Kafka Event ভিত্তিক); Orchestration-এ একটি Orchestrator Service (যেমন: Temporal) সিদ্ধান্ত নেয় কার পর কে কাজ করবে।

---

### 8. Transactional Outbox Pattern
* **কী (What):** ডাটাবেস আপডেট এবং Kafka Event পাঠানো—এই দুটি কাজকে স্থানীয় DB Transaction-এর মাধ্যমে একটিমাত্র `outbox_events` টেবিলে একসাথে সেভ করা।
* **কেন (Why):** **Dual Write Problem** আটকানো। ডাটাবেসে সেভ হওয়ার পর Kafka ডাউন থাকলে মেসেজ হারিয়ে যেতে পারে।
* **কোথায় (Where in Arogyam):** Appointment, Payment, Doctor এবং Pharmacy সার্ভিসগুলোতে।
* **কীভাবে (How):** 
  ```sql
  BEGIN TRANSACTION;
  INSERT INTO appointments ...;
  INSERT INTO outbox_events (event_type, payload, status) VALUES ('APPOINTMENT_CREATED', '...', 'PENDING');
  COMMIT;
  ```
  এরপর ব্যাকগ্রাউন্ড Poller/Debezium CDC `outbox_events` পড়ে Kafka-তে পাঠায় এবং স্টেটাস `PROCESSED` করে।
* **সহজ উদাহরণ (Analogy):** চিঠি লেখে ডাকপিয়ন আসার জন্য ঘরের দরজার Outbox বাক্সে রেখে দেওয়া। ডাকপিয়ন পরে এসে ডাকঘরে দিয়ে আসবে, চিঠি হারাবে না।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Outbox Pattern কীভাবে At-Least-Once Delivery নিশ্চিত করে?*
  - **উত্তর:** ইভেন্ট Kafka-তে সুনিশ্চিতভাবে পাঠানো পর্যন্ত Outbox টেবিল থেকে রিমুভ/আপডেট করা হয় না।

---

### 9. Inbox Pattern (Idempotent Consumer)
* **কী (What):** মেসেজ কনজিউমার সাইডে `processed_events` টেবিল দিয়ে আগের প্রসেস হওয়া ইভেন্ট ট্র্যাক করে ডুপ্লিকেট মেসেজ এক্সিকিউশন আটকানো।
* **কেন (Why):** Kafka রিট্রাইয়ের কারণে একই মেসেজ ২ বার পাঠাতে পারে (At-Least-Once)। এতে পেশেন্টের থেকে ২ বার টাকা কাটা বা ২টি SMS যাওয়ার ঝুঁকি থাকে।
* **কোথায় (Where in Arogyam):** Payment Service, Notification Service এবং Search Service-এ।
* **কীভাবে (How):** কনজিউমার ইভেন্ট পেলে আগে চেক করে `SELECT 1 FROM processed_events WHERE event_id = X`। পেলে ইভেন্টটি স্কিপ করে, না পেলে প্রসেস করে ইভেন্ট আইডি সেভ করে।
* **সহজ উদাহরণ (Analogy):** ব্যাংকের ক্যাশিয়ার চেকের ইউনিক সিরিয়াল নম্বর নোটে লিখে রাখে, যাতে একই চেক ২ বার ক্যাশ না করা যায়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Idempotency কী?*
  - **উত্তর:** একই অপারেশন ১ বার করা আর ১০ বার করার ফলাফল একই হওয়া।

---

### 10. Immutable Audit Ledger
* **কী (What):** সিকিউরিটি ও HIPAA Compliance-এর জন্য এমন ডাটাবেস টেবিল ডিজাইন যেখানে শুধু `INSERT` করা যায়; `UPDATE` বা `DELETE` ডাটাবেস লেভেলে বন্ধ।
* **কেন (Why):** হেলথ প্রজেক্টে রোগীর ডাটা কে কখন দেখেছে বা পরিবর্তন করেছে তা হ্যাকারের পক্ষেও মুছে ফেলা অসম্ভব করা।
* **কোথায় (Where in Arogyam):** `Audit Service` (PostgreSQL / Append-Only Audit Logs)।
* **কীভাবে (How):** PostgreSQL-এ Table Level Rule / Trigger বসিয়ে `UPDATE` ও `DELETE` কোয়েরিতে Error Throw করা হয়।
* **সহজ উদাহরণ (Analogy):** ব্যাংকের পাসবুক বা খাতা যেখানে কোনো লেখা মোছা যায় না, যা কিছু পরিবর্তন লাল কালি দিয়ে নতুন লাইনে লিখতে হয়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Audit DB খুব বড় হয়ে গেলে স্কেল করবেন কীভাবে?*
  - **উত্তর:** Date-based Table Partitioning করে পুরনো অডিট ডাটা S3/BigQuery-তে আরকাইভ (Cold Storage) করা হয়।

---

## ⚡ ক্যাটাগরি ৩: Concurrency & Race Condition Control

### 11. Optimistic Locking
* **কী (What):** ডাটাবেসে কাস্টম ডাটাবেস লক না নিয়ে, একটি `version` কলাম দিয়ে কনকারেন্ট আপডেট প্রতিরোধ করা।
* **কেন (Why):** Pessimistic Locking (DB Lock) ডাটাবেসকে স্লো করে দেয়। 
* **কোথায় (Where in Arogyam):** `Appointment Service` (`appointments` টেবিল)।
* **কীভাবে (How):** 
  `UPDATE appointments SET status = 'BOOKED', version = version + 1 WHERE id = 101 AND version = 1;`
  যদি ২ জন ইউজার একসাথে একই স্লট আপডেট করতে চায়, ১ম ইউজারের ভার্সন ২ হয়ে যাবে এবং ২য় ইউজারের কোয়েরির 0 rows affected হবে।
* **সহজ উদাহরণ (Analogy):** Google Docs-এর ভার্সনিং। একজন এডিট করার পর ভার্সন বদলে গেলে অন্যজনের পুরোনো সেশনের চেঞ্জ রিজেক্ট হয়ে যাওয়া।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Optimistic vs Pessimistic Locking কখন কোনটা ব্যবহার করবেন?*
  - **উত্তর:** Conflict কম হলে (Low Concurrency) Optimistic; Conflict খুব বেশি ও কড়া আইসোলেশন লাগলে Pessimistic Locking।

---

### 12. Redis Distributed Locking (Redlock Algorithm)
* **কী (What):** ডিস্ট্রিবিউটেড মেমোরি ক্যাশে (Redis) কাস্টম কি (Key) লক বসিয়ে একাধিক মাইক্রোসার্ভিস ইনস্ট্যান্সের মধ্যে রেস কন্ডিশন আটকানো।
* **কেন (Why):** ১০০০ পেশেন্ট যদি ১ সেকেন্ডে ১টিমাত্র খালি ডাক্তার স্লটে ক্লিক করে, তবে ডুপ্লিকেট বুকিং আটকানো।
* **কোথায় (Where in Arogyam):** `Appointment Service` (ডাক্তার বুকিং স্লট লকিং)।
* **কীভাবে (How):** 
  `SET lock:slot:doc_5_10am "uuid" NX PX 5000`
  যে ইউজার প্রথম এই `NX` (Not Exists) লক পাবে, সে বুকিং প্রসেস করবে। বাকি ৯৯৯ জন `Lock Failure` পাবে।
* **সহজ উদাহরণ (Analogy):** ট্রেনের টয়লেটের দরজা ভেতর থেকে লক করা। লাল চিহ্ন দেখলে বাইরে ১০ জন দাঁড়িয়ে থাকলেও কেউ ঢুকতে পারে না।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Redlock-এ যদি সার্ভিস লকিংয়ের পর ক্র্যাশ করে?*
  - **উত্তর:** `PX 5000` (TTL - Time to Live) দেওয়া থাকে, যা ৫ সেকেন্ড পর অটোমেটিক এক্সপায়ার হয়ে লক রিলিজ করে দেয় (Deadlock Avoidance)।

---

### 13. Write-Through Caching
* **কী (What):** ডাটা রাইট করার সময় ডাটাবেস (PostgreSQL) এবং মেমোরি ক্যাশ (Redis)-এ একসাথে সিঙ্ক্রোনাসভাবে সেভ করা।
* **কেন (Why):** বুকিং স্লট ও Auth টোকেন ডাটাবেসে সেভ হওয়ার সাথে সাথে ক্যাশে না থাকলে পরবর্তী রিড পুরনো ডাটা দেখাতে পারে (Stale Read)।
* **কোথায় (Where in Arogyam):** Auth Tokens & Appointment Availability Slots।
* **কীভাবে (How):** `Application logic` ➔ Write to PostgreSQL ➔ Write to Redis ➔ Return Success to Client.
* **সহজ উদাহরণ (Analogy):** ডায়েরিতে কোনো মিটিংয়ের সময় লেখার সাথে সাথে মোবাইলের ক্যালেন্ডার অ্যাপেও সেভ করে রাখা।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Write-Through vs Write-Back Caching-এর পার্থক্য কী?*
  - **উত্তর:** Write-Through সিঙ্ক্রোনাস ও ডাটা সেইফ; Write-Back ক্যাশে লিখে পরে ব্যাকগ্রাউন্ডে DB-তে লেখে (দ্রুত কিন্তু পাওয়ার কাটলে ডাটা লসের ঝুঁকি থাকে)।

---

### 14. Idempotency-Key Pattern (Stripe Standard)
* **কী (What):** HTTP POST/PUT রিকোয়েস্টের হেডারে `Idempotency-Key` নামে ইউনিক UUID পাঠিয়ে রিট্রাই রিকোয়েস্টে ডুপ্লিকেট অপারেশন আটকানো।
* **কেন (Why):** পেশেন্ট পেমেন্ট বাটনে ২ বার ক্লিক করলে বা নেটওয়ার্ক ড্রপ করে রিট্রাই হলে যাতে ২ বার পেমেন্ট না কাটে।
* **কোথায় (Where in Arogyam):** API Gateway & Payment / Appointment Endpoints।
* **কীভাবে (How):** 
  API Gateway রিকোয়েস্টের `Idempotency-Key` ক্যাশে (Redis) ২৪ ঘণ্টার জন্য সেভ করে রাখে। একই কি দিয়ে ২য় বার রিকোয়েস্ট আসলে প্রসেস না করে ১ম রিকোয়েস্টের সেভড রেসপন্স ফেরত দেয়।
* **সহজ উদাহরণ (Analogy):** ব্যাংকের স্লিপে রেফারেন্স নম্বর। একই নম্বর দিলে ক্যাশিয়ার বলে "এই জমার কাজ আগেই হয়ে গেছে"।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Idempotency Key কতক্ষণ ক্যাশে রাখা উচিত?*
  - **উত্তর:** সাধারণত ২৪ থেকে ৪৮ ঘণ্টা (ব্যবসার প্রয়োজন অনুযায়ী)।

---

## 🛡️ ক্যাটাগরি ৪: Resiliency & Performance Patterns

### 15. Circuit Breaker Pattern (Resilience4j)
* **কী (What):** কোনো ডাউনিং বা স্লো থার্ড-পার্টি সার্ভিস (যেমন: SMS Gateway) অনবরত ফেল করলে কল আটকে ফলব্যাক সার্ভিস চালু করা।
* **কেন (Why):** Cascading Failure আটকানো। ১টি থার্ড-পার্টি সার্ভিস ডাউন থাকলে আপনার সার্ভারের সব থ্রেড ব্লক হয়ে পুরো অ্যাপ ডাউন হওয়া প্রতিরোধ করা।
* **কোথায় (Where in Arogyam):** `Notification Service` (Twilio SMS/SendGrid) এবং `Payment Service` (Razorpay/Stripe)।
* **কীভাবে (How):** ৩টি স্টেট থাকে:
  - **CLOSED:** সব ঠিক আছে।
  - **OPEN:** ৫০% এরর হলে সংযোগ বিচ্ছিন্ন, সাথে সাথে Fallback (যেমন: SMS-এর বদলে Email) পাঠানো।
  - **HALF-OPEN:** কিছু সময় পর ট্রাই করে দেখা সার্ভিসটি ঠিক হয়েছে কিনা।
* **সহজ উদাহরণ (Analogy):** ঘরের কারেন্টের মেইন ফিউজ/সার্কিট ব্রেকার। শটসার্কিট হলে ফিউজ উড়ে গিয়ে পুরো ঘরের ইলেকট্রনিক্স বাঁচায়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Circuit Breaker স্টেট পরিবর্তন কীভাবে নির্ধারণ করে?*
  - **উত্তর:** Sliding Window (যেমন: শেষ ১০০টি কলেই ৫০টি এরর হলে Open হবে)।

---

### 16. Bulkhead Thread Isolation
* **কী (What):** অ্যাপ্লিকেশনের মোট থ্রেড পুলকে বিভিন্ন সার্ভিসের জন্য ছোট ছোট ব্লকে ভাগ করে রাখা।
* **কেন (Why):** যদি Notification Service হঠাৎ ১ লাখ ইমেইল পাঠানোর চাপে ধীরগতির হয়ে যায়, তবে যেন Appointment Service-এর থ্রেড খালি থাকে।
* **কোথায় (Where in Arogyam):** `Resilience4j Bulkhead` in Microservices Execution Context.
* **কীভাবে (How):** মোট ২০০টি থ্রেডের মধ্যে ৫০টি Notification, ১০০টি Appointment, ৫০টি Auth-এর জন্য নির্দিষ্ট করে দেওয়া।
* **সহজ উদাহরণ (Analogy):** জাহাজের ভেতরের ওয়াটারটাইট কম্পার্টমেন্ট (Bulkhead)। জাহাজের একপাশে ছিদ্র হয়ে জল ঢুকলেও অন্য কম্পার্টমেন্টে জল ঢুকতে পারে না, ফলে জাহাজ ডোবে না।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Thread Isolation vs Semaphore Bulkhead-এর তফাত কী?*
  - **উত্তর:** Thread Isolation আলাদা থ্রেড পুল তৈরি করে; Semaphore একই থ্রেড পুলে কনকারেন্ট কলের সংখ্যা সীমিত করে।

---

### 17. Retry with Exponential Backoff & Jitter
* **কী (What):** নেটওয়ার্ক ফেল করলে তাৎক্ষণিক বারবার রিট্রাই না করে সময়ের ব্যবধান বাড়িয়ে বাড়িয়ে রিট্রাই করা ও সাথে র্যান্ডম টাইম (Jitter) যোগ করা।
* **কেন (Why):** Thundering Herd Problem আটকানো। ১০০০টি রিকোয়েস্ট একই সময়ে ফেল করে একসাথে রিট্রাই করলে রিকভার হওয়া সার্ভার আবার ক্র্যাশ করবে।
* **কোথায় (Where in Arogyam):** Microservice to Microservice gRPC & HTTP calls.
* **কীভাবে (How):** 
  - Retry 1: 1 sec delay
  - Retry 2: 2 sec delay
  - Retry 3: 4 sec delay + Jitter (+-200ms)
* **সহজ উদাহরণ (Analogy):** কোনো দরজায় নক করে সাড়া না পেলে একটু পর পর গিয়ে নক করা, অনবরত দরজায় ধাক্কা না দেওয়া।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Jitter কেন দরকার?*
  - **উত্তর:** সব ফেল হওয়া ক্লায়েন্ট যেন একই সাথে আবার রিট্রাই না করে, রিট্রাই টাইমগুলোকে ছড়িয়ে দিতে।

---

### 18. Dead Letter Queue (DLQ)
* **কী (What):** ক্যফকার যে মেসেজগুলো বারবার প্রসেস করতে গিয়ে ফেল করে (Poison Pill), সেগুলোকে আলাদা ক্যু-তে সরিয়ে নেওয়া।
* **কেন (Why):** ১টি ভুল ফরম্যাটের মেসেজের জন্য যাতে ক্যফকা কনজিউমার লুপে আটকে না থাকে এবং বাকি হাজার হাজার ভালো মেসেজ প্রসেস হওয়া বন্ধ না হয়।
* **কোথায় (Where in Arogyam):** Apache Kafka Consumers (`arogyam.appointment.dlq`)।
* **কীভাবে (How):** 
  কনজিউমার ৩ বার রিট্রাই করার পর ব্যর্থ হলে মেসেজটি `DLQ Topic`-এ পাঠিয়ে দেয় এবং পরবর্তীoffset-এ চলে যায়। ডেভলপাররা পরে DLQ মেসেজ ম্যানুয়ালি ফিক্স করে।
* **সহজ উদাহরণ (Analogy):** পোস্ট অফিসের "Undelivered Mail" বক্স। যে চিঠির ঠিকানা ভুল, সেটা আলাদা বক্সে রেখে স্বাভাবিক চিঠিপত্র বিলি চালু রাখা।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *DLQ মেসেজ প্রসেস কীভাবে করবেন?*
  - **উত্তর:** অলার্ট পাঠাব, কোড বাগ/ডাটা ফিক্স করে মেসেজটি Re-drive (পুনরায় মূল টপিকে পাঠানো) করব।

---

### 19. Token Bucket Rate Limiting
* **কী (What):** নির্দিষ্ট সময়ের মধ্যে একজন ইউজার বা IP কতগুলো API রিকোয়েস্ট পাঠাতে পারবে তা টোকেন বালতির মাধ্যমে নিয়ন্ত্রণ করা।
* **কেন (Why):** DDoS অ্যাটাক, ব্রুট-ফোর্স লগইন অ্যাটাক এবং API সর্ভার ক্র্যাশ হওয়া থেকে বাঁচানো।
* **কোথায় (Where in Arogyam):** API Gateway (Redis Token Bucket Limiter)।
* **কীভাবে (How):** 
  প্রতি ইউজারের জন্য Redis-এ একটি বালতি থাকে যেখানে নির্দিষ্ট হারে (যেমন: ১০০ টোকেন/মি) টোকেন জমা হয়। প্রতি রিকোয়েস্টে ১টি টোকেন কমে। টোকেন শূন্য হলে `429 Too Many Requests` এরর দেওয়া হয়।
* **সহজ উদাহরণ (Analogy):** ওয়াটার পার্কের রাইডের টিকিট টোকেন। টোকেন শেষ হয়ে গেলে আবার টোকেন রিচার্জ হওয়া পর্যন্ত লাইনে দাঁড়াতে হয়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Rate Limiting-এর অ্যালগরিদম কী কী আছে?*
  - **উত্তর:** Token Bucket, Leaky Bucket, Fixed Window Counter, Sliding Window Log, Sliding Window Counter।

---

### 20. Cache-Aside & Invalidation Pattern
* **কী (What):** অ্যাপ ডাটা পড়ার সময় আগে ক্যাশে খুঁজে, না পেলে ডাটাবেস থেকে পড়ে ক্যাশে রাইট করে; আর ডাটা আপডেট হলে ক্যাশ ডিলিট/ইনভ্যালিডেট করে দেওয়া।
* **কেন (Why):** ডাটাবেসের ওপর রিড প্রেশার কমানো এবং ক্যাশে পুরনো ডাটা জমতে না দেওয়া।
* **কোথায় (Where in Arogyam):** Patient & Doctor Profile Data (Redis Cache)।
* **কীভাবে (How):** 
  - **Read:** `App` ➔ `Redis (Miss)` ➔ `PostgreSQL` ➔ `Write to Redis` ➔ `Return`.
  - **Update:** `App` ➔ `Update PostgreSQL` ➔ `Delete Redis Key`.
* **সহজ উদাহরণ (Analogy):** পড়া মুখস্থ করার পর পড়ার টেবিলে শর্টনোট লিখে রাখা। বইয়ের পাতা বারবার না উল্টে শর্টনোট দেখে নেওয়া।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Cache Invalidation-এ Cache Update না করে Cache Delete করা হয় কেন?*
  - **উত্তর:** ডিলিট করা নিরাপদ (Lazy Loading)। আপডেট করলে রেস কন্ডিশনে ক্যাশে পুরোনো ডাটা থেকে যাওয়ার ভয় থাকে।

---

### 21. Cursor Pagination Standard (Uber/Meta Standard)
* **কী (What):** ডাটাবেস পেজিনেশনে `OFFSET` ব্যবহার না করে শেষ দেখা আইটেমের ইউনিক আইডি বা টাইমস্ট্যাম্প (`cursor`) দিয়ে পরবর্তী ডাটা ফেচ করা।
* **কেন (Why):** `OFFSET 100000` ব্যবহার করলে DB-কে আগের ১ লাখ রো স্ক্যান করতে হয় যা অত্যন্ত স্লো। এছাড়া নতুন ডাটা ঢুকলে পেজিনেশনে আইটেম রিপিট হয়।
* **কোথায় (Where in Arogyam):** Patient Appointments List & Health Records List APIs.
* **কীভাবে (How):** 
  `GET /api/v1/appointments?cursor=app_999&limit=20`
  SQL: `SELECT * FROM appointments WHERE id > 'app_999' ORDER BY id ASC LIMIT 20;`
* **সহজ উদাহরণ (Analogy):** বইয়ের কত নম্বর পাতায় আছেন তা না খুঁজে, শেষ যে শব্দটি পড়েছিলেন তার পর থেকে পড়া শুরু করা।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Cursor Pagination-এর অসুবিধা কী?*
  - **উত্তর:** সরাসরি নির্দিষ্ট কোনো পেজে (যেমন: পেজ নম্বর ১৫) লাফ দেওয়া যায় না (No direct page jumping)।

---

## 🔐 ক্যাটাগরি ৫: Security & Zero-Trust Architecture

### 22. Zero-Trust Architecture & RBAC
* **কী (What):** নেটওয়ার্কের ভেতরে বা বাইরে কাউকেই বাই-ডিফল্ট ট্রাস্ট না করা এবং Role-Based Access Control (RBAC) দিয়ে সূক্ষ্ম পারমিশন হ্যান্ডেল করা।
* **কেন (Why):** হ্যাকার যদি ভেতরের নেটওয়ার্কে ঢুকেও পড়ে, তাহলেও সে যেন ডাক্তারের পারমিশন ছাড়া রোগীর মেডিকেল হিস্ট্রি দেখতে না পারে।
* **কোথায় (Where in Arogyam):** Admin, Identity, and Patient Services.
* **কীভাবে (How):** রোলস: `Super Admin`, `Doctor Admin`, `Doctor`, `Patient`, `Auditor`। প্রতিটি API এন্ডপয়েন্টে `@PreAuthorize("hasRole('DOCTOR')")` দিয়ে ভ্যালিডেশন করা।
* **সহজ উদাহরণ (Analogy):** পঞ্চতারকা হোটেলের অ্যাকসেস কার্ড। ভিজিটর কার্ড দিয়ে আপনি শুধু লবি ও আপনার রুমে যেতে পারবেন, প্রেসিডেন্টের সুইটে বা কিচেনে ঢুকতে পারবেন না।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *RBAC vs ABAC-এর তফাত কী?*
  - **উত্তর:** RBAC ইউজার রোলের ওপর ভিত্তি করে এক্সেস দেয়; ABAC (Attribute-Based) রোলের পাশাপাশি টাইম, লোকেশন, ডিভাইসের ওপর ভিত্তি করে এক্সেস দেয়।

---

### 23. JWT & OAuth2 / OIDC
* **কী (What):** স্টেটলেস ইউজারের আইডেন্টিটি প্রমাণ করার জন্য ডিজিটালভাবে সাইন করা JSON Web Token (JWT) ব্যবহার করা।
* **কেন (Why):** প্রতিটি API কলে ব্যাকএন্ড ডাটাবেসে সেশন ক্যোয়ারি করা এড়ানো, যাতে হাজার হাজার সার্ভিস স্টেটলেসভাবে স্কেল করতে পারে।
* **কোথায় (Where in Arogyam):** Identity Service & API Gateway।
* **কীভাবে (How):** 
  ইউজার লগইন করলে Identity Service Secret Key দিয়ে সাইন করা `Access Token` (মেয়াদ: ১৫ মিনিট) এবং `Refresh Token` (মেয়াদ: ৭ দিন) ফেরত দেয়।
* **সহজ উদাহরণ (Analogy):** কনসার্টের সিকিউরিটি ব্যান্ড। হাতে রিস্টব্যান্ড পরা থাকলে সিকিউরিটি বারবার টিকিটিং কাউন্টারে না পাঠিয়ে সরাসরি ভেতরে যেতে দেয়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *JWT Token কীভাবে Revoke/Invalidate করবেন যদি তা স্টেটলেস হয়?*
  - **উত্তর:** Redis-এ Token Blacklist মেইনটেইন করে অথবা Short-lived Token (১৫ মি) ব্যবহার করে।

---

### 24. mTLS (Mutual TLS)
* **কী (What):** ক্লায়েন্ট-সার্ভার এনক্রিপশনের পাশাপাশি মাইক্রোসার্ভিসগুলোর নিজেদের মধ্যেও একে অপরের ডিজিটাল সার্টিফিকেট যাচাই করা (Two-way Authentication)।
* **কেন (Why):** ক্লাস্টারের ভেতরে কোনো ফেইক/ক্ষতিকারক পড ঢুকে সার্ভিসগুলোর ভেতরের কথা শুনতে (Man-in-the-Middle Attack) না পারে।
* **কোথায় (Where in Arogyam):** Kubernetes Service Mesh (Istio Envoy Proxies)।
* **কীভাবে (How):** `Appointment Service` যখন `Patient Service`-কে gRPC কল করে, তখন Istio সাইডকার অটোমেটিক ২ পাশের TLS Certificate এক্সচেঞ্জ করে ডেটা এনক্রিপ্ট করে দেয়।
* **সহজ উদাহরণ (Analogy):** গোপন মিশনের এজেন্টদের পাসওয়ার্ড বিনিময়। আপনিও তার পরিচয় ভ্যালিড করবেন, সেও আপনার পরিচয় ভ্যালিড করবে।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *TLS vs mTLS-এর পার্থক্য কী?*
  - **উত্তর:** TLS-এ শুধু ক্লায়েন্ট সার্ভারকে ভেরিফাই করে (যেমন: ব্রাউজার Lock Icon); mTLS-এ সার্ভার ও ক্লায়েন্ট দুজনই দুজনকে ভেরিফাই করে।

---

### 25. PII Field-Level Encryption & HashiCorp Vault
* **কী (What):** পেশেন্টের Personally Identifiable Information (PII - যেমন: জাতীয় পরিচয়পত্র নম্বর, ফোন নম্বর) ডাটাবেসে সেভ করার আগেই কাস্টম এনক্রিপশন করা এবং পাসওয়ার্ড/সিক্রেট সেন্ট্রাল Vault-এ রাখা।
* **কেন (Why):** ডাটাবেসের এক্সেস হ্যাক হলেও হ্যাকার যেন প্লেইন টেক্সট রোগীর গোপন তথ্য দেখতে না পায়।
* **কোথায় (Where in Arogyam):** `Patient Service` & `HashiCorp Vault` Configuration.
* **কীভাবে (How):** 
  AES-256 দিয়ে `national_id` এনক্রিপ্ট করা হয়। এনক্রিপশন কি (Encryption Key) কোনো ফাইল বা কোডে থাকে না, সেন্ট্রাল HashiCorp Vault থেকে রানটাইমে নিয়ে আসা হয়।
* **সহজ উদাহরণ (Analogy):** মূল্যবান অলঙ্কার লকারে রাখা এবং লকারের চাবি সেফে রাখা।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Field-Level Encrypted Data-তে Search কীভাবে করবেন?*
  - **উত্তর:** Deterministic Encryption (Blind Index / HMAC Hash) ব্যবহার করে সার্চ ক্যোয়ারি চালানো হয়।

---

## 📊 ক্যাটাগরি ৬: Observability & DevOps

### 26. Distributed Tracing (OpenTelemetry + Jaeger)
* **কী (What):** একাধিক মাইক্রোসার্ভিস ও ক্যফকা ঘুরে আসা একটি ইউজার রিকোয়েস্টের শুরু থেকে শেষ পর্যন্ত একটি ইউনিক `TraceID` দিয়ে ট্র্যাক করা।
* **কেন (Why):** বুকিং বাটনে ক্লিক করার পর ৪ সেকেন্ড ল্যাটেন্সি হলে কোন নির্দিষ্ট সার্ভিস বা SQL ক্যোয়ারি স্লো করছে তা দ্রুত চিহ্নিত করা।
* **কোথায় (Where in Arogyam):** OpenTelemetry SDK Integration in all Microservices & Jaeger UI.
* **কীভাবে (How):** 
  Gateway `TraceID: abc-123` জেনারেট করে। HTTP/gRPC Header এবং Kafka Header-এর মাধ্যমে এই ID পাস হয়। Jaeger UI-তে পুরো ভিজ্যুয়াল ওয়াটারফল টাইমলাইন দেখা যায়।
* **সহজ উদাহরণ (Analogy):** কুরিয়ার সার্ভিসের ট্র্যাকিং নম্বর। পার্সেলটি কোন হাব থেকে কোন গাড়িতে যাচ্ছে তার লাইভ আপডেট দেখা।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Tracing overhead কীভাবে কমাবেন?*
  - **উত্তর:** Head-based / Tail-based Sampling (যেমন: ১০% ট্রাফিক বা শুধু এরর হওয়া রিকোয়েস্ট ট্র্যাকিং করা)।

---

### 27. Metrics & Alerting (Prometheus + Grafana)
* **কী (What):** সার্ভারের সিপিইউ, মেমোরি, রিকোয়েস্ট পার সেকেন্ড (RPS), এবং ক্যফকা ল্যাগ টাইম-সিরিজ ডাটা হিসেবে রিয়েল-টাইমে মনিটর করা।
* **কেন (Why):** সার্ভার ডাউন বা মেমোরি লিক হওয়ার আগেই সতর্কবার্তা পাওয়া।
* **কোথায় (Where in Arogyam):** Prometheus Collector & Grafana Dashboard & Alertmanager (PagerDuty/Slack).
* **কীভাবে (How):** 
  প্রতিটি মাইক্রোসার্ভিস `/actuator/prometheus` বা `/metrics` এন্ডপয়েন্ট এক্সপোজ করে। Prometheus প্রতি ৫ সেকেন্ডে ডাটা টানে এবং Grafana ড্যাশবোর্ডে লাইভ গ্রাফ দেখায়।
* **সহজ উদাহরণ (Analogy):** রোগীর আইসিইউ মনিটর। হৃদস্পন্দন বা অক্সিজেন কমলেই অ্যালার্ম বাজতে শুরু করে।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Kafka Lag বৃদ্ধি পেলে Prometheus কীভাবে সতর্ক করবে?*
  - **উত্তর:** `kafka_consumergroup_lag > 1000` হলে Prometheus Alertmanager সাথে সাথে ইঞ্জিনিয়ারদের Slack/PagerDuty-তে অ্যালার্ট পাঠাবে।

---

### 28. Structured Logging (ELK Stack)
* **কী (What):** প্লেইন টেক্সট লাইনের বদলে JSON ফরম্যাটে স্ট্রাকচার্ড লগ লেখা এবং সেন্ট্রাল Elasticsearch-এ ইনডেক্স করা।
* **কেন (Why):** কোটি কোটি লগের মধ্যে নির্দিষ্ট ইউজার বা TraceID-এর এরর লগ এক সেকেন্ডে খুঁজে বের করা।
* **কোথায় (Where in Arogyam):** Logback JSON Encoder ➔ Fluentd/Logstash ➔ Elasticsearch ➔ Kibana (ELK Stack).
* **কীভাবে (How):** 
  `{"timestamp": "...", "traceId": "abc-123", "level": "ERROR", "service": "payment", "message": "Gateway timeout"}`
* **সহজ উদাহরণ (Analogy):** এলোমেলো ফাইলের বদলে লাইব্রেরিতে বিষয় ও লেখক অনুযায়ী ফাইল ক্যাটালগ করে রাখা।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Unstructured vs Structured Logging-এর পার্থক্য কী?*
  - **উত্তর:** Unstructured সাধারণ টেক্সট (পার্স করা কঠিন); Structured JSON ফরম্যাটে কি-ভ্যালু দিয়ে তৈরি (মেশিন রিডেবল ও সার্চ ফ্রেন্ডলি)।

---

### 29. GitOps & Kubernetes Scaling (HPA & Canary)
* **কী (What):** Git রিপোজিটরিকে আর্কিটেকচারের Single Source of Truth ধরে অটোমেটিক Kubernetes Cluster স্কেলিং ও জিরো-ডাউনটাইম ডিপ্লয়মেন্ট করা।
* **কেন (Why):** ম্যানুয়ালি কুবারনেটিস কমান্ড চালিয়ে ডিপ্লয়মেন্টে ভুল হওয়া আটকানো এবং ট্রাফিক বাড়লে স্বয়ংক্রিয়ভাবে সার্ভার বাড়ানো।
* **কোথায় (Where in Arogyam):** `arogyam-infra` GitOps Repo, ArgoCD, Kubernetes HPA.
* **কীভাবে (How):** 
  - **HPA:** CPU > 70% বা Kafka Lag বাড়লে Pod সংখ্যা ৫টি থেকে বাড়িয়ে ২০টি করে দেয়।
  - **Canary:** নতুন কোড ৫% ট্রাফিকে টেস্ট করে, এরর না থাকলে ধীরে ধীরে ১০০% ভার্সন চালু করে।
* **সহজ উদাহরণ (Analogy):** নতুন বিমান টেকঅফ করানোর আগে রানওয়েতে কম স্পিডে চালিয়ে ভ্যালিডেট করা।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Canary vs Blue-Green Deployment-এর পার্থক্য কী?*
  - **উত্তর:** Blue-Green এক ধাক্কায় ১০০% ট্রাফিক নতুন এনভায়রনমেন্টে পাঠায়; Canary শতাংশ হিসেবে (৫% ➔ ২০% ➔ ১০০%) ট্রাফিক পাঠায়।

---

## 🧩 ক্যাটাগরি ৭: Low-Level Code Design & Principles

### 30. Clean Architecture (Hexagonal / Ports & Adapters)
* **কী (What):** কোডের বিজনেস লজিককে (Core Domain) ফ্রেমওয়ার্ক, ডাটাবেস ড্রাইভার এবং UI থেকে সম্পূর্ণ আলাদা রাখা।
* **কেন (Why):** ভবিষ্যতে PostgreSQL থেকে MongoDB-তে সুইচ করলে যেন মূল বিজনেস লজিক কোডে ১ লাইনও পরিবর্তন না করতে হয়।
* **কোথায় (Where in Arogyam):** All Microservices Codebase.
* **কীভাবে (How):** 
  `Transport (Controller/Kafka)` ➔ `Application Service` ➔ `Domain Model` ➔ `Ports (Interfaces)` ⬅️ `Adapters (Postgres/Redis Impl)`
* **সহজ উদাহরণ (Analogy):** ইলেকট্রিক সকেট (Port) এবং প্লাগ (Adapter)। প্লাগ ইন্ডিয়ান হোক বা ইউকে, সকেটের ইন্টারফেস এক থাকলে কারেন্ট জ্বলবে।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Clean Architecture-এ Dependency-এর দিক কোন দিকে থাকে?*
  - **উত্তর:** সবসময় বাইরের লেয়ার (DB/UI) ভেতরের ডোমেন লেয়ারের দিকে পয়েন্ট করে (Dependencies Point Inward)।

---

### 31. Domain-Driven Design (DDD) Aggregates & Bounded Contexts
* **কী (What):** সফটওয়্যার ডাটাবেস ডিজাইন দিয়ে শুরু না করে বাস্তব ব্যবসার ডোমেন মডেল ও Aggregate Root দিয়ে শুরু করা।
* **কেন (Why):** অ্যাপয়েন্টমেন্ট ও প্রেসক্রিপশনের মতো জটিল বিজনেস রিলেশনশিপে ডাটা ইনকনসিস্টেন্সি আটকানো।
* **কোথায় (Where in Arogyam):** `Appointment` Aggregate Root (যার ভেতরে `Prescription` ও `PaymentState` সামলানো হয়)।
* **কীভাবে (How):** ক্লায়েন্ট সরাসরি প্রেসক্রিপশন টেবিল এডিট করতে পারে না; শুধুমাত্র `Appointment` Aggregate Root-এর সার্ভিস মেথডের মাধ্যমে ডাটা স্টেট আপডেট করা যায়।
* **সহজ উদাহরণ (Analogy):** একটি গাড়ি। আপনি চাকা বা ইঞ্জিন আলাদা চালাতে পারেন না, গাড়ির ড্রাইভিং সিটে বসেই পুরো কার অ্যাকসেস করতে হয়।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Value Object এবং Entity-এর পার্থক্য কী?*
  - **উত্তর:** Entity-এর নিজস্ব ইউনিক আইডি (`user_id`) থাকে; Value Object-এর কোনো আইডি থাকে না, এটি শুধু মান নির্দেশ করে (যেমন: `Address` বা `Money`)।

---

### 32. SOLID Principles (SRP, OCP, DIP with Repository Pattern)
* **কী (What):** অবজেক্ট ওরিয়েন্টেড প্রোগ্রামিংয়ের ৫টি মৌলিক বেস্ট প্র্যাকটিস ডিজাইন নীতি।
* **কেন (Why):** কোডকে রিড্যাবল, মেইনটেইনেবল, টেস্টেবল এবং স্কেলেবল করার জন্য।
* **কোথায় (Where in Arogyam):** 
  - **SRP (Single Responsibility):** প্রতিটি ক্লাসের একটিমাত্র কাজ (যেমন: `PasswordHasherService` শুধু হ্যাশিং করবে)।
  - **OCP (Open/Closed):** `NotificationProvider` ইন্টারফেস ব্যবহার করা হয়েছে (নতুন WhatsApp চ্যানেল আনলে আগের কোড এডিট না করে নতুন ক্লাস যোগ করা যাবে)।
  - **DIP (Dependency Inversion):** `AppointmentService` সরাসরি `PostgreSQLRepository`-র উপর নির্ভর করে না, `IAppointmentRepository` ইন্টারফেসের উপর নির্ভর করে।
* **সহজ উদাহরণ (Analogy):** মাল্টিপ্লাগ ও ইলেকট্রিক অ্যাপ্লায়েন্স।
* **ইন্টারভিউ ক্রস-কোশ্চেন:** *Dependency Injection (DI) এবং Dependency Inversion Principle (DIP)-এর মধ্যে তফাত কী?*
  - **উত্তর:** DIP হলো একটি ডিজাইন প্রিন্সিপল (উচ্চ লেয়ার নিম্ন লেয়ারের ইন্টারফেসের ওপর ডিপেন্ড করবে); DI হলো এই প্রিন্সিপল ইমপ্লিমেন্ট করার একটি টেকনিক (ফ্রেসওয়ার্ক অবজেক্ট সাপ্লাই করে)।

---

📌 **প্রস্তুতির ফাইনাল টিপস:**
এই ডকুমেন্টটি রিভিশন দিলে ইন্টারভিউয়ার আপনাকে যেকোনো আর্কিটেকচারাল সিদ্ধান্ত, কনকারেন্সি প্রবলেম, ডাটাবেস চয়েস বা ফল্ট টলারেন্স নিয়ে প্রশ্ন করলে আপনি নির্দ্বিধায় যুক্তি ও বাস্তব উদাহরণসহ উত্তর দিতে পারবেন।