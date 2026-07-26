# Arogyam AI Analysis Service — Implementation Plan

## Overview
Doctor recommendation engine using AI/ML. Strategy Pattern দিয়ে
RuleBased → MLBased → LLMBased models hot-swap করা যাবে।
Patient symptoms → Best matching doctor recommend করবে।

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | Python 3.11 |
| Framework | FastAPI |
| ML | scikit-learn (Phase 1), PyTorch (Phase 2) |
| LLM | OpenAI API / Ollama local (Phase 3) |
| Vector DB | Elasticsearch (already running) |
| Cache | Redis |
| Port | **8014** |

## Recommendation Models (Strategy Pattern)

```python
class RecommendationEngine(ABC):
    @abstractmethod
    async def recommend(self, request: RecommendationRequest) -> List[DoctorScore]:
        pass

class RuleBasedEngine(RecommendationEngine):
    """Phase 1: Simple specialty matching + rating sort"""
    async def recommend(self, request):
        # specialty match → sort by rating + experience + distance

class MLBasedEngine(RecommendationEngine):
    """Phase 2: Trained model on historical booking data"""
    async def recommend(self, request):
        # Feature: [specialty_match, distance, rating, price, availability]
        # Model: Random Forest / XGBoost

class LLMBasedEngine(RecommendationEngine):
    """Phase 3: Symptom → specialty mapping via LLM"""
    async def recommend(self, request):
        # GPT/Ollama: "Patient has chest pain, shortness of breath"
        # → {"specialty": "Cardiology", "urgency": "HIGH"}
        # → Then query Elasticsearch for matching doctors
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/ai/recommend/doctors` | Get doctor recommendations |
| `POST` | `/api/v1/ai/analyze/symptoms` | Symptom → Specialty mapping |
| `GET` | `/api/v1/ai/specialties` | All available specialties |
| `GET` | `/api/v1/ai/model/status` | Which model is active |
| `GET` | `/health` | Health check |

## Request / Response

```json
// POST /api/v1/ai/recommend/doctors
{
  "symptoms": ["chest pain", "shortness of breath", "dizziness"],
  "location": { "lat": 22.5726, "lng": 88.3639 },
  "max_distance_km": 10,
  "preferred_fee_range": { "min": 200, "max": 1000 },
  "language": "Bengali"
}

// Response
{
  "recommended_specialty": "Cardiology",
  "urgency": "HIGH",
  "doctors": [
    {
      "doctorId": "doc_123",
      "name": "Dr. Priya Sharma",
      "specialty": "Cardiologist",
      "rating": 4.8,
      "distance_km": 2.3,
      "consultation_fee": 500,
      "next_available": "2026-07-28T10:00:00Z",
      "match_score": 0.94
    }
  ]
}
```

## Kafka Events Consumed
```
appointment.completed.v1  → Training data collection
doctor.profile.updated.v1 → Update doctor index in Elasticsearch
```

## Phases

```
Phase 1 (Now):     RuleBasedEngine — specialty match + sort
Phase 2 (Later):   MLBasedEngine — trained on booking history
Phase 3 (Future):  LLMBasedEngine — OpenAI/Ollama symptom analysis
```

## docker-compose.yml Addition
```yaml
ai-analysis-service:
  build: ./arogyam-ai-analysis-service
  container_name: arogyam-ai-analysis-service
  ports:
    - "8014:8014"
  environment:
    - ELASTICSEARCH_URL=http://elasticsearch:9200
    - REDIS_HOST=redis-cache
    - REDIS_PORT=6379
    - REDIS_PASSWORD=redis_secure_pass_2026
    - KAFKA_BROKERS=kafka:9092
    - RECOMMENDATION_ENGINE=RULE_BASED
    - OPENAI_API_KEY=your_key_here
  depends_on:
    - elasticsearch
    - redis-cache
  networks:
    - arogyam-net
```
