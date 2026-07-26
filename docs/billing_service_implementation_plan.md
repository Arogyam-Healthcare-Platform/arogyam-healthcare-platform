# Arogyam Billing Service — Implementation Plan

## Overview
Consultation fee payment processing, invoice generation, and payment history management.
Saga Pattern দিয়ে Appointment Service এর সাথে distributed transaction handle করে।

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | Java 17 |
| Framework | Spring Boot 3.2 |
| Database | PostgreSQL (arogyam_billing DB) |
| Payment Gateway | Razorpay / Stripe (mock for dev) |
| Messaging | Kafka Consumer + Producer |
| Auth | gRPC → Auth Service |
| Port | **8009** |

## Domain Models

```java
Invoice {
  id, appointmentId, patientId, doctorId
  amount, currency: "INR"
  status: PENDING | PAID | REFUNDED | FAILED
  paymentGatewayOrderId
  paymentGatewayPaymentId
  version  // Optimistic locking
  createdAt, paidAt
}

Payment {
  id, invoiceId, patientId
  amount, method: UPI | CARD | NETBANKING | WALLET
  status: SUCCESS | FAILED | REFUNDED
  gatewayResponse (JSON)
  transactionId
  processedAt
}

Refund {
  id, paymentId, invoiceId
  amount, reason
  status: INITIATED | PROCESSED | FAILED
  initiatedAt, processedAt
}
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/billing/invoices` | Create invoice for appointment |
| `GET` | `/api/v1/billing/invoices/{id}` | Get invoice |
| `GET` | `/api/v1/billing/invoices/patient/{patientId}` | Patient invoice history |
| `POST` | `/api/v1/billing/payments/initiate` | Initiate payment (returns gateway URL) |
| `POST` | `/api/v1/billing/payments/webhook` | Payment gateway webhook |
| `POST` | `/api/v1/billing/refunds` | Initiate refund |
| `GET` | `/api/v1/billing/payments/{id}` | Payment status |
| `GET` | `/health` | Health check |

## Kafka Events

### Consumed
```
appointment.created.v1    → Create invoice (PENDING)
appointment.cancelled.v1  → Initiate refund if paid
```

### Published
```
payment.success.v1        → Notification Service (push: "Payment successful")
payment.failed.v1         → Notification Service (push: "Payment failed, retry")
refund.initiated.v1       → Notification Service (push: "Refund initiated")
```

## Saga Pattern (Booking Flow)

```
1. Appointment Service → appointment.created.v1
2. Billing Service creates PENDING invoice
3. Patient pays → gateway webhook → payment.success.v1
4. Appointment status → CONFIRMED

Rollback (if payment fails):
1. payment.failed.v1 → Appointment Service cancels booking
2. Notification: "Booking failed due to payment"
```

## Security
- Webhook signature verification (Razorpay HMAC)
- Patient শুধু নিজের invoices দেখতে পারবে
- Soft delete — no financial record ever deleted (compliance)

## docker-compose.yml Addition
```yaml
billing-service:
  build: ./arogyam-billing-service
  container_name: arogyam-billing-service
  ports:
    - "8009:8009"
  environment:
    - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-db:5432/arogyam_billing
    - SPRING_DATASOURCE_USERNAME=arogyam_admin
    - SPRING_DATASOURCE_PASSWORD=arogyam_secure_pass_2026
    - AUTH_SERVICE_GRPC_HOST=auth-service
    - AUTH_SERVICE_GRPC_PORT=50051
    - KAFKA_BOOTSTRAP_SERVERS=kafka:9092
    - RAZORPAY_KEY_ID=your_key_id
    - RAZORPAY_KEY_SECRET=your_key_secret
    - PAYMENT_MODE=MOCK
  depends_on:
    postgres-db:
      condition: service_healthy
    kafka:
      condition: service_healthy
  networks:
    - arogyam-net
```
