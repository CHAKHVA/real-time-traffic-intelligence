# Real-Time Traffic Intelligence Hub: Implementation Checklist

Actionable implementation steps aligned with [spec.md](./spec.md). Each task is a complete, testable unit of work.

**Progress Tracking:**
- [ ] Not started
- [x] Completed

---

## Phase 1: Foundation & Infrastructure

### 1.1 Environment Setup
- [x] Initialize Git repository and create directory structure
- [x] Create `docker-compose.yml` with all services (Postgres, Kafka, Zookeeper, MLflow, Kafka UI)
- [ ] Create `.env.example` with all required environment variables
- [ ] Create database initialization script (`scripts/init_db.sh`)
- [ ] Create Kafka topics setup script (`scripts/setup_kafka_topics.sh`)
- [ ] **Test:** Run `docker compose up -d` and verify all services healthy

### 1.2 Development Tooling
- [ ] Configure `pyproject.toml` with all dependencies (Kafka, Spark, FastAPI, Streamlit, MLflow, etc.)
- [ ] Create comprehensive `Makefile` with commands: `dev`, `sync`, `format`, `lint`, `typecheck`, `test`, `docker-up/down`
- [ ] Configure `ruff` for formatting and linting
- [ ] Configure `mypy` for type checking
- [ ] **Test:** Run `make sync`, `make format`, `make lint`, `make typecheck`

### 1.3 Core Utilities
- [ ] Implement `src/utils/config.py` - load environment variables, validate settings
- [ ] Implement `src/utils/logging.py` - structured logging with timestamps and service names
- [ ] Implement `src/utils/spark_session.py` - factory for Spark session with Kafka/JDBC connectors
- [ ] Define Pydantic schema `src/schemas/traffic_event.py` with validation (speed 0-120, required fields)
- [ ] **Test:** Write unit tests for config loading, logging setup, and schema validation

---

## Phase 2: Data Ingestion Pipeline

### 2.1 Kafka Producer
- [ ] Implement `src/ingestion/kafka_producer.py` with connection handling and serialization
- [ ] Add traffic event generator with realistic patterns (rush hours, weather correlation)
- [ ] Implement DLQ routing for invalid events (validation errors → `traffic_dlq`)
- [ ] Add CLI arguments: `--rate`, `--error-rate`, `--duration`
- [ ] Create `make run-producer` command
- [ ] **Test:** Run producer and verify events in Kafka UI (port 8080)

### 2.2 Database Schema
- [ ] Create SQLAlchemy models in `src/utils/database.py`:
  - `TrafficRaw` - raw streaming data
  - `TrafficProcessed` - cleaned, aggregated data
  - `FeatureStore` - ML-ready features
  - `HistoricalTraffic` - batch ingested data
- [ ] Add indexes on `road_id` and `timestamp` columns
- [ ] Implement connection pool with retry logic in `src/utils/db_connection.py`
- [ ] Update `scripts/init_db.sh` to create tables
- [ ] **Test:** Run init script and verify tables created in Postgres

### 2.3 Spark Streaming (Basic)
- [ ] Implement `src/processing/spark_streaming.py` with Kafka consumer
- [ ] Add schema parsing and JSON deserialization
- [ ] Implement basic filtering (remove nulls, invalid timestamps)
- [ ] Add console sink for debugging
- [ ] Configure checkpoint directory for fault tolerance
- [ ] Create `make run-stream` command
- [ ] **Test:** Run producer + stream processor, verify console output

---

## Phase 3: Stream Processing & Batch Pipeline

### 3.1 Advanced Stream Processing
- [ ] Add 5-minute tumbling window aggregations (avg_speed, vehicle_count, max/min speed)
- [ ] Implement speed categorization: free_flow (>60), moderate (30-60), congested (<30)
- [ ] Add data quality controls: clip speeds to 0-120, deduplicate with watermarks
- [ ] Implement PostgreSQL JDBC sink using `foreachBatch`
- [ ] Add DLQ error handling (malformed JSON → `traffic_dlq`, log errors, continue processing)
- [ ] Add monitoring metrics (records/sec, processing lag)
- [ ] **Test:** End-to-end flow (producer → Spark → Postgres), query `TrafficProcessed` table

### 3.2 Airflow Batch Processing
- [ ] Add Airflow services to `docker-compose.yml` (webserver port 8081, scheduler)
- [ ] Configure Airflow to use Postgres metadata DB and LocalExecutor
- [ ] Create `airflow/dags/batch_ingestion.py` - daily historical data ingestion at 2 AM
  - Download/read NYC DOT Traffic CSV
  - Clean and validate data
  - Write to `HistoricalTraffic` table
  - Add data quality checks and retries (3x with backoff)
- [ ] Create Airflow connections for Postgres and MLflow
- [ ] **Test:** Trigger DAG manually in Airflow UI, verify data in database

### 3.3 DLQ Monitoring
- [ ] Create `src/processing/dlq_monitor.py` to consume and log DLQ events
- [ ] Update producer to inject malformed events based on `--error-rate` flag
- [ ] **Test:** Run producer with errors, verify Spark continues processing, check DLQ topic

---

## Phase 4: Machine Learning Pipeline

### 4.1 Feature Engineering
- [ ] Implement `src/ml/feature_engineering.py` with feature transformations:
  - Temporal: hour_of_day, day_of_week, is_weekend, rush_hour_flag (7-9 AM, 5-7 PM)
  - Rolling stats: 1-hour mean speed, 3-hour mean vehicle count, rolling std
  - Lag features: previous hour's speed
  - Weather encoding (if available)
- [ ] Add feature versioning (timestamp, version ID)
- [ ] Read from `TrafficProcessed` and `HistoricalTraffic` tables
- [ ] Write to `FeatureStore` with upsert logic
- [ ] Create `make run-features` command
- [ ] **Test:** Generate features and query `FeatureStore` table

### 4.2 Model Training with MLflow
- [ ] Implement `src/ml/train_model.py` with MLflow tracking
- [ ] Configure MLflow client (tracking URI: `http://localhost:5001`)
- [ ] Load data from `FeatureStore` with 70/15/15 train/val/test split
- [ ] Train XGBoost and RandomForest models
- [ ] Log params, metrics (RMSE, MAE, R²), and artifacts to MLflow
- [ ] Compare models and select best performer
- [ ] Add feature importance visualization
- [ ] Create `make train-model` command
- [ ] **Test:** Run training, verify experiments in MLflow UI (port 5001)

### 4.3 Model Registry & Automated Retraining
- [ ] Register best model to MLflow Registry as `traffic_speed_predictor`
- [ ] Add tags (version, training_date, metrics) and transition to "Staging"
- [ ] Create `src/ml/promote_model.py` - compare Staging vs Production metrics, promote if 5% RMSE improvement
- [ ] Create `airflow/dags/model_training.py` - weekly retraining (Sundays 3 AM):
  - Task 1: Run feature engineering
  - Task 2: Train models with MLflow
  - Task 3: Evaluate and promote if better
  - Task 4: Log training summary
- [ ] Add error handling (MLflow failures, training errors, data quality issues)
- [ ] **Test:** Trigger DAG, verify model in Registry with "Production" tag

---

## Phase 5: API & Visualization

### 5.1 FastAPI Prediction Service
- [ ] Create FastAPI app structure in `api/main.py` with CORS, exception handlers, logging
- [ ] Implement `api/models/model_loader.py` - load `traffic_speed_predictor/Production` with `@lru_cache`
- [ ] Define Pydantic schemas for `PredictionRequest`, `PredictionResponse`, `HealthResponse`
- [ ] Implement `GET /health` in `api/routes/health.py`:
  - Return 200 if model loaded, 503 if unavailable
  - Include model version and status
- [ ] Implement `POST /predict` in `api/routes/predict.py`:
  - Validate request, make prediction, return 400/503 on errors
  - Log requests with correlation ID
- [ ] Implement `GET /metrics` - request count, avg response time, prediction count
- [ ] Add startup event (load model, test DB) and shutdown event (cleanup)
- [ ] Create `make run-api` command (uvicorn with reload)
- [ ] **Test:** Curl `/health` and `/predict` endpoints, verify error handling

### 5.2 Streamlit Dashboard
- [ ] Create `dashboard/app.py` with multi-tab layout (Overview, Predictions, Monitoring)
- [ ] Implement database connection utility with pooling
- [ ] Build **Overview Tab**:
  - Live KPIs (avg speed, congestion index, active roads, total vehicles) updating every 30s
  - Time series chart (Plotly) with historical speed trends
  - Speed distribution histogram
- [ ] Build **Predictions Tab**:
  - Input form (road selector, datetime, weather)
  - Predict button calling FastAPI `/predict`
  - Display predicted speed with model version
  - Actual vs Predicted comparison chart
- [ ] Build **Monitoring Tab**:
  - System health status (API, DB, Kafka)
  - Recent predictions table
  - DLQ error logs
  - Model performance metrics from MLflow
- [ ] Add error handling (API down → cached data + alert, DB failures → retry with backoff)
- [ ] Implement caching with `@st.cache_data` (1-min TTL)
- [ ] Create `make run-streamlit` command
- [ ] **Test:** Open dashboard (port 8501), test all tabs and prediction workflow

---

## Phase 6: Testing & CI/CD

### 6.1 Unit Tests
- [ ] Create `tests/conftest.py` with fixtures (mock Kafka, test DB, sample events, mock MLflow)
- [ ] Write `tests/unit/test_schemas.py` - Pydantic validation, serialization, boundary conditions
- [ ] Write `tests/unit/test_ingestion.py` - producer connection, event generation, DLQ routing
- [ ] Write `tests/unit/test_processing.py` - Spark transformations, aggregations, speed categorization
- [ ] Write `tests/unit/test_ml.py` - feature engineering, rolling windows, temporal features
- [ ] Write `tests/unit/test_utils.py` - config loading, logging, DB utilities
- [ ] Configure pytest in `pyproject.toml` with 85% coverage threshold
- [ ] **Test:** Run `make test`, verify all tests pass

### 6.2 Integration & E2E Tests
- [ ] Write `tests/integration/test_api.py` using FastAPI `TestClient`:
  - Test `/health` (200/503), `/predict` (200/400/503), `/metrics`
  - Test CORS headers and concurrent requests
- [ ] Write `tests/integration/test_pipeline.py` - Kafka → Spark → Postgres flow with docker-compose
- [ ] Write `tests/integration/test_model.py` - training, MLflow logging, model loading, inference
- [ ] Create `tests/e2e/test_full_flow.py`:
  - Start all services, run producer, verify data flow
  - Trigger feature engineering → training → prediction → dashboard data
- [ ] Add Makefile commands: `test-integration`, `test-e2e`, `test-cov`
- [ ] **Test:** Run integration and E2E tests, verify 85%+ coverage

### 6.3 CI/CD Pipeline
- [ ] Create `.github/workflows/ci.yml`:
  - Trigger on push/PR
  - Install uv, Python 3.11, sync dependencies
  - Run format check, lint, typecheck
  - Run tests with coverage
  - Upload coverage to Codecov
- [ ] Add GitHub Actions badges to README
- [ ] Configure branch protection (require CI pass, code review, block force push)
- [ ] **Test:** Push to GitHub, verify CI pipeline passes

### 6.4 Documentation & Final Validation
- [ ] Update `README.md` with:
  - Architecture diagram, quick start (< 30 min), prerequisites
  - Installation steps, all `make` commands, environment variables
  - Troubleshooting section
- [ ] Create `docs/ARCHITECTURE.md` with diagrams and component descriptions
- [ ] Add docstrings and type hints to all public functions
- [ ] Verify all acceptance criteria from spec.md §17:
  - End-to-end pipeline works (Kafka → DB → MLflow → API → Dashboard)
  - Model registry has "Production" model
  - API serves predictions reliably
  - Dashboard visualizes live and forecast data
  - CI passes with ≥85% coverage
  - Developer onboarding < 30 min
- [ ] **Test:** Fresh clone → `make dev` → verify entire system works

---

## Progress Summary

- **Phase 1:** [ ] Complete (Foundation & Infrastructure)
- **Phase 2:** [ ] Complete (Data Ingestion Pipeline)
- **Phase 3:** [ ] Complete (Stream Processing & Batch)
- **Phase 4:** [ ] Complete (Machine Learning Pipeline)
- **Phase 5:** [ ] Complete (API & Visualization)
- **Phase 6:** [ ] Complete (Testing & CI/CD)

**Project Complete:** [ ]
