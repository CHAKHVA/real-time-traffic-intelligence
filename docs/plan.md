# Real-Time Traffic Intelligence Hub — Implementation Plan

This document provides a detailed, step-by-step implementation plan for building the Real-Time Traffic Intelligence Hub as specified in [spec.md](./spec.md).

## Overview

The implementation is organized into **6 phases**, each containing multiple chunks that build upon previous work. Each phase includes:

- **Goal:** High-level objective for the phase
- **Reference:** Relevant sections from spec.md
- **Detailed Steps:** Specific, actionable implementation tasks

## Implementation Strategy

- **Incremental Development:** Each chunk delivers working functionality
- **Testing First:** Validate components before moving to the next phase
- **Spec Alignment:** All implementation references specific spec.md sections
- **Quality Gates:** Code quality checks (lint, typecheck, test) at every phase

## Quick Navigation

1. [Phase 1: Foundational Setup & Environment](#phase-1-foundational-setup--environment)
2. [Phase 2: Data Ingestion & Storage](#phase-2-data-ingestion--storage)
3. [Phase 3: End-to-End Data Flow](#phase-3-end-to-end-data-flow)
4. [Phase 4: Machine Learning Integration](#phase-4-machine-learning-integration)
5. [Phase 5: Serving & Visualization](#phase-5-serving--visualization)
6. [Phase 6: Testing & CI/CD](#phase-6-testing--cicd)

---

## Phase 1: Foundational Setup & Environment

**Goal:** Establish a stable, reproducible development environment with all infrastructure services running locally.

**Reference:** See spec.md §5 (Environment & Build), §15 (Folder Structure)

### Chunk 1.1: Project Scaffolding & Version Control

- **Step 1.1.1:** Initialize Git repository with `.python-version` file set to `3.11`.
- **Step 1.1.2:** Create complete directory structure per spec.md §15:
  ```
  src/{ingestion,processing,ml,schemas,utils}/
  api/{routes,models}/
  dashboard/
  airflow/{dags,config}/
  tests/{unit,integration}/
  data/{raw,processed}/
  docs/
  scripts/
  .github/workflows/
  ```
- **Step 1.1.3:** Create `.gitkeep` files in `data/raw/` and `data/processed/` directories.
- **Step 1.1.4:** Initialize `pyproject.toml` with `uv` targeting Python 3.11. Define project metadata (name, version, description, authors).
- **Step 1.1.5:** Create comprehensive `.gitignore` (Python, data files, MLflow artifacts, Docker volumes, `.env`).
- **Step 1.1.6:** Create initial `README.md` with project overview and quick start instructions.
- **Step 1.1.7:** Create `.env.example` template with all required environment variables (Kafka, PostgreSQL, MLflow URIs).

### Chunk 1.2: Core Services Orchestration

**Reference:** See spec.md §4 (Architectural Overview), §14 (Local Development Flow)

- **Step 1.2.1:** Create `docker-compose.yml` with service definitions:
  - PostgreSQL (port 5432, persistent volume, init scripts support)
  - Zookeeper (port 2181)
  - Kafka (port 9092, depends_on Zookeeper)
  - Kafka UI (port 8080, optional for monitoring)
  - MLflow server (port 5001, PostgreSQL backend, artifact volume)
- **Step 1.2.2:** Configure Docker networking with bridge network for inter-service communication.
- **Step 1.2.3:** Add health checks for PostgreSQL and Kafka services.
- **Step 1.2.4:** Create `scripts/init_db.sh` for PostgreSQL schema initialization.
- **Step 1.2.5:** Create `scripts/setup_kafka_topics.sh` to create `traffic_raw` and `traffic_dlq` topics.
- **Step 1.2.6:** Verify services: `docker compose up -d` and check logs for successful startup.

### Chunk 1.3: Automation & Dependency Management

**Reference:** See spec.md §5 (Environment & Build) for complete Makefile commands

- **Step 1.3.1:** Create comprehensive `Makefile` with command groups:
  - **Quick Start:** `dev`, `stop-all`
  - **Environment:** `sync`, `clean`
  - **Code Quality:** `format`, `lint`, `typecheck`, `check`
  - **Testing:** `test`, `test-cov`
  - **Application:** `run-api`, `run-streamlit`, `run-producer`
  - **Infrastructure:** `docker-up`, `docker-down`, `docker-logs`, `docker-clean`
  - **Utilities:** `kafka-topics`, `kafka-ui`, `mlflow-ui`, `db-connect`
- **Step 1.3.2:** Define initial dependencies in `pyproject.toml`:
  - Core: `pydantic`, `python-dotenv`
  - Quality: `ruff`, `mypy`, `pytest`, `pytest-cov`, `pytest-asyncio`
  - Data: `kafka-python`, `pyspark`, `psycopg2-binary`, `sqlalchemy`
  - ML: `scikit-learn`, `xgboost`, `mlflow`
  - API: `fastapi`, `uvicorn`
  - Dashboard: `streamlit`, `plotly`, `pandas`
  - Orchestration: `apache-airflow` (with providers)
- **Step 1.3.3:** Implement `make sync` using `uv sync`.
- **Step 1.3.4:** Implement `make format` (ruff format), `make lint` (ruff check), `make typecheck` (mypy).
- **Step 1.3.5:** Implement `make check` to run all quality checks sequentially.
- **Step 1.3.6:** Implement `make dev` to start all infrastructure and open browser tabs for UIs.

### Chunk 1.4: Base Utilities & Configuration

**Reference:** See spec.md §6.2 (Event Schema), §10 (Error Handling), §13 (Observability)

- **Step 1.4.1:** Create `src/utils/config.py`:
  - Load from `.env` file using `python-dotenv`
  - Define settings dataclass/Pydantic model for: Kafka broker, PostgreSQL URL, MLflow tracking URI
  - Validate required environment variables on startup
- **Step 1.4.2:** Create `src/utils/logging.py`:
  - Structured logging with timestamps and service names
  - Support both file and stdout output
  - Configure log levels from environment
  - Include correlation IDs for request tracing
- **Step 1.4.3:** Create `src/utils/spark_session.py`:
  - Factory function for creating configured SparkSession
  - Include Kafka and PostgreSQL JDBC connectors
  - Set appropriate memory and executor configurations
- **Step 1.4.4:** Define `src/schemas/traffic_event.py` using Pydantic:
  - Fields: `road_id`, `timestamp`, `speed`, `vehicle_count`, `weather_condition`, `accident_reported`
  - Validation: non-null road_id/timestamp, speed bounds (0-120), positive vehicle count
  - Include serialization methods for Kafka (JSON bytes)

---

## Phase 2: Data Ingestion & Storage

**Goal:** Implement streaming data ingestion from Kafka and establish persistent storage in PostgreSQL.

**Reference:** See spec.md §4 (Data Ingestion Layer), §6 (Data Handling Strategy)

### Chunk 2.1: Real-Time Data Producer

**Reference:** See spec.md §6.1 (Data Sources), §6.2 (Event Schema)

- **Step 2.1.1:** Create `src/ingestion/kafka_producer.py` using `kafka-python` library.
- **Step 2.1.2:** Implement producer configuration:
  - Connect to Kafka broker from config
  - Set serialization (JSON with UTF-8 encoding)
  - Configure acknowledgments for reliability (`acks='all'`)
  - Add retry and timeout settings
- **Step 2.1.3:** Create data generation functions:
  - Random traffic event generator using Pydantic schema validation
  - Support for multiple data source types (TomTom API simulation, NYC Open Data format)
  - Include realistic patterns (rush hour variations, weather correlation)
- **Step 2.1.4:** Implement error handling per spec.md §10:
  - Pydantic validation before sending
  - Malformed events to DLQ topic (`traffic_dlq`)
  - Structured logging for all send operations
- **Step 2.1.5:** Create main loop with configurable send rate (events/second).
- **Step 2.1.6:** Add `make run-producer` command to Makefile.
- **Step 2.1.7:** Test producer: verify events appear in Kafka UI at `localhost:8080`.

### Chunk 2.2: Database Schema & Initialization

**Reference:** See spec.md §6.3 (Storage Strategy)

- **Step 2.2.1:** Create `src/utils/database.py` with SQLAlchemy models:
  - `TrafficRaw` table (raw streaming data with JSON column)
  - `TrafficProcessed` table (cleaned, aggregated data)
  - `FeatureStore` table (ML-ready features)
  - `HistoricalTraffic` table (batch ingested data)
- **Step 2.2.2:** Define table schemas matching spec.md §6.2:
  - Indexes on `road_id`, `timestamp` for query performance
  - Partitioning strategy for time-series data (optional)
  - Constraints for data integrity
- **Step 2.2.3:** Update `scripts/init_db.sh`:
  - Create database and user
  - Execute SQLAlchemy table creation
  - Add initial data quality constraints
- **Step 2.2.4:** Create `src/utils/db_connection.py`:
  - Connection pool management
  - Retry logic with exponential backoff (per spec.md §10)
  - Health check function
- **Step 2.2.5:** Add `make db-init` and `make db-connect` commands to Makefile.

### Chunk 2.3: Spark Streaming Processor (Basic)

**Reference:** See spec.md §4 (Streaming Layer), §6.4 (Transformation Pipeline)

- **Step 2.3.1:** Create `src/processing/spark_streaming.py`.
- **Step 2.3.2:** Initialize Spark Structured Streaming:
  - Use `src/utils/spark_session.py` to create session
  - Configure Kafka source (bootstrap servers, topic, starting offsets)
  - Set checkpoint directory for fault tolerance
- **Step 2.3.3:** Implement schema parsing:
  - Define Spark `StructType` matching Pydantic schema
  - Parse JSON from Kafka value column
  - Handle schema evolution gracefully
- **Step 2.3.4:** Add basic transformations:
  - Filter null/invalid records (per spec.md §6.4)
  - Type conversions and casting
  - Timestamp parsing and normalization
- **Step 2.3.5:** Implement console sink for testing:
  - `writeStream.format("console")`
  - Trigger mode: processing time (5 seconds)
  - Output mode: append
- **Step 2.3.6:** Add `make run-stream` command using `spark-submit`.
- **Step 2.3.7:** Test: Run producer + stream processor, verify console output.

---

## Phase 3: End-to-End Data Flow

**Goal:** Complete the Lambda architecture by connecting streaming and batch processing to persistent storage.

**Reference:** See spec.md §4 (Batch Processing Layer), §6.4 (Transformation Pipeline), §10 (Error Handling)

### Chunk 3.1: Advanced Stream Processing with PostgreSQL Sink

**Reference:** See spec.md §6.4 (Transformation Pipeline - Streaming)

- **Step 3.1.1:** Modify `src/processing/spark_streaming.py` to add aggregations:
  - Implement 5-minute tumbling window on `timestamp` column
  - Calculate per-window aggregates: `avg_speed`, `total_vehicle_count`, `max_speed`, `min_speed`
  - Add speed categorization: "free_flow" (>60), "moderate" (30-60), "congested" (<30)
- **Step 3.1.2:** Implement data quality controls per spec.md §12:
  - Clipping: speed values to 0-120 range
  - Duplicate suppression using watermarks
  - Null handling for required fields
- **Step 3.1.3:** Add PostgreSQL JDBC sink:
  - Download PostgreSQL JDBC driver to Spark jars
  - Configure JDBC write with `.format("jdbc")`
  - Use `foreachBatch` for better control and error handling
  - Write to `TrafficProcessed` table
  - Set appropriate batch trigger interval
- **Step 3.1.4:** Implement checkpoint management:
  - Configure checkpoint location in local/persistent storage
  - Enable write-ahead logs for exactly-once semantics
- **Step 3.1.5:** Add monitoring logs for processing metrics (records/second, lag).
- **Step 3.1.6:** Test end-to-end flow:
  - `make dev` (start all infrastructure)
  - `make run-producer` (Terminal 2)
  - `make run-stream` (Terminal 3)
  - `make db-connect` and query `TrafficProcessed` table

### Chunk 3.2: Batch Processing with Airflow

**Reference:** See spec.md §4 (Batch Processing Layer), §6.4 (Transformation Pipeline - Batch)

- **Step 3.2.1:** Add Airflow to `docker-compose.yml`:
  - Airflow webserver (port 8081)
  - Airflow scheduler
  - Configure PostgreSQL as metadata database
  - Mount `airflow/dags/` directory
  - Set `AIRFLOW__CORE__LOAD_EXAMPLES=False`
- **Step 3.2.2:** Create Airflow configuration in `airflow/config/airflow.cfg`:
  - Set executor to LocalExecutor
  - Configure connections (PostgreSQL, MLflow)
  - Email alert settings (per spec.md §10)
- **Step 3.2.3:** Create test DAG (`airflow/dags/hello_world_dag.py`) to verify setup.
- **Step 3.2.4:** Create `airflow/dags/batch_ingestion.py`:
  - Schedule: daily at 2 AM (`schedule_interval="0 2 * * *"`)
  - Task 1: Download/read historical data (NYC DOT Traffic Volume CSV)
  - Task 2: Data cleansing (remove nulls, normalize timestamps, validate schema)
  - Task 3: Write to `HistoricalTraffic` table in PostgreSQL
  - Configure retries: 3 attempts with exponential backoff (per spec.md §10)
- **Step 3.2.5:** Add utility tasks:
  - Data quality checks (row count, null percentage, date range)
  - Alerts on failure (email or log)
- **Step 3.2.6:** Test DAG: `make airflow-ui` (http://localhost:8081), trigger manually, verify execution.

### Chunk 3.3: Error Handling & Dead-Letter Queue

**Reference:** See spec.md §10 (Error & Failure Handling)

- **Step 3.3.1:** Update `scripts/setup_kafka_topics.sh` to create `traffic_dlq` topic.
- **Step 3.3.2:** Modify Spark streaming job for DLQ pattern:
  - Wrap JSON parsing in try-except
  - On `JSONDecodeError` or Pydantic `ValidationError`:
    - Log error with event details
    - Send malformed event to `traffic_dlq` topic
    - Continue processing (don't fail job)
  - Track DLQ metrics (count, error types)
- **Step 3.3.3:** Update `src/ingestion/kafka_producer.py`:
  - Add `--error-rate` CLI flag (default 0.05)
  - Randomly inject malformed JSON (missing fields, invalid types)
  - Log when sending corrupt data for testing
- **Step 3.3.4:** Create DLQ monitoring script (`src/processing/dlq_monitor.py`):
  - Consume from `traffic_dlq` topic
  - Log error patterns
  - Option to replay/fix and resubmit to `traffic_raw`
- **Step 3.3.5:** Test DLQ flow:
  - Run producer with error injection
  - Verify Spark job continues processing good events
  - Check `traffic_dlq` topic in Kafka UI for malformed events
  - Verify structured logging captures error details

---

## Phase 4: Machine Learning Integration

**Goal:** Build, train, and track ML models for traffic prediction with automated retraining.

**Reference:** See spec.md §7 (Machine Learning Details), §4 (ML & Serving Layer)

### Chunk 4.1: Feature Engineering Pipeline

**Reference:** See spec.md §7 (Features), §12 (Data Quality Controls)

- **Step 4.1.1:** Create `src/ml/feature_engineering.py` with feature transformation logic.
- **Step 4.1.2:** Implement feature generation functions:
  - **Temporal features:** `hour_of_day`, `day_of_week`, `month`, `is_weekend`
  - **Rush hour flag:** Define morning (7-9 AM) and evening (5-7 PM) rush hours
  - **Rolling statistics:**
    - 1-hour rolling mean of speed
    - 3-hour rolling mean of vehicle count
    - Rolling standard deviation for volatility
  - **Weather features:** Categorical encoding (if available)
  - **Lag features:** Previous hour's average speed
- **Step 4.1.3:** Add feature versioning per spec.md §12:
  - Timestamp feature creation runs
  - Version identifier in feature table
  - Schema validation for feature columns
- **Step 4.1.4:** Implement data reading:
  - Query `TrafficProcessed` and `HistoricalTraffic` tables
  - Union streaming and batch data
  - Filter by date range (e.g., last 90 days)
- **Step 4.1.5:** Write to `FeatureStore` table:
  - Include all features + target variable (future speed)
  - Add metadata columns (created_at, feature_version)
  - Implement upsert logic to prevent duplicates
- **Step 4.1.6:** Add `make run-features` command.
- **Step 4.1.7:** Test: Run feature generation, query `FeatureStore` table.

### Chunk 4.2: Model Training & MLflow Tracking

**Reference:** See spec.md §7 (Model details, Tracking, Registry)

- **Step 4.2.1:** Create `src/ml/train_model.py` for model training.
- **Step 4.2.2:** Configure MLflow:
  - Set tracking URI from config (`http://localhost:5001`)
  - Create/set experiment name: `traffic_speed_prediction`
  - Enable autologging for scikit-learn/XGBoost
- **Step 4.2.3:** Implement data loading from `FeatureStore`:
  - Train/validation/test split (70/15/15)
  - Feature selection based on spec.md §7
  - Target variable: average speed for next 15 minutes
- **Step 4.2.4:** Implement model training with MLflow tracking:
  ```python
  with mlflow.start_run():
      # Log parameters
      mlflow.log_params({"model_type": "XGBoost", "n_estimators": 100, ...})

      # Train models
      xgb_model = XGBRegressor(...)
      rf_model = RandomForestRegressor(...)

      # Log metrics (RMSE, MAE, R²)
      mlflow.log_metrics({"rmse": ..., "r2": ..., "mae": ...})

      # Log model
      mlflow.sklearn.log_model(xgb_model, "model")

      # Log feature importance plot
  ```
- **Step 4.2.5:** Add model comparison logic:
  - Train both XGBoost and RandomForest
  - Compare metrics
  - Select best performing model
- **Step 4.2.6:** Implement model validation per spec.md §11:
  - Cross-validation scores
  - Residual analysis
  - Feature importance visualization
- **Step 4.2.7:** Add `make train-model` command.
- **Step 4.2.8:** Test: Run training, check MLflow UI at `localhost:5001`.

### Chunk 4.3: Model Registry & Automated Retraining

**Reference:** See spec.md §7 (Model Registry, Retraining)

- **Step 4.3.1:** Add model registration to `src/ml/train_model.py`:
  - Register best model to MLflow Model Registry
  - Model name: `traffic_speed_predictor`
  - Add tags (version, training_date, metrics)
  - Transition to "Staging" initially
- **Step 4.3.2:** Create model promotion script (`src/ml/promote_model.py`):
  - Compare Staging model metrics with Production
  - If improvement threshold met (e.g., 5% RMSE reduction), promote to Production
  - Otherwise, keep current Production model
  - Archive old Production model
- **Step 4.3.3:** Create Airflow DAG (`airflow/dags/model_training.py`):
  - **Schedule:** Weekly on Sundays at 3 AM (`0 3 * * 0`)
  - **Task 1:** `run_feature_engineering` - Execute feature generation
  - **Task 2:** `train_model` - Run model training with MLflow
  - **Task 3:** `evaluate_and_promote` - Compare and promote model if better
  - **Task 4:** `send_metrics_report` - Log training summary
  - **Retries:** 3 with exponential backoff (per spec.md §10)
- **Step 4.3.4:** Add error handling per spec.md §10:
  - MLflow connection failure: use cached artifact, send alert
  - Training failure: send email, keep previous model in Production
  - Data quality issues: fail with descriptive error
- **Step 4.3.5:** Test DAG:
  - Trigger manually in Airflow UI
  - Verify model appears in MLflow Registry
  - Check model version transitions (Staging → Production)

---

## Phase 5: Serving & Visualization

**Goal:** Expose ML predictions via REST API and create an interactive dashboard for monitoring and visualization.

**Reference:** See spec.md §8 (Model Serving), §9 (Visualization Layer)

### Chunk 5.1: FastAPI Prediction Service

**Reference:** See spec.md §8 (Model Serving endpoints, startup behavior)

- **Step 5.1.1:** Create FastAPI app structure in `api/main.py`:
  - Initialize FastAPI app with metadata (title, version, description)
  - Configure CORS middleware
  - Add exception handlers
  - Include structured logging
- **Step 5.1.2:** Create `api/models/model_loader.py`:
  - Implement model loader using MLflow Python API
  - Load `models:/traffic_speed_predictor/Production`
  - Use `@lru_cache` for efficient model caching
  - Handle model not found gracefully
  - Add model reload capability (for updates)
- **Step 5.1.3:** Create request/response schemas in `api/schemas/`:
  - `PredictionRequest`: features per spec.md §7 (rolling_means, weather, hour, day_of_week, rush_hour_flag)
  - `PredictionResponse`: predicted_speed, confidence_interval, model_version, timestamp
  - `HealthResponse`: status, model_loaded, model_version, uptime
- **Step 5.1.4:** Implement endpoints in `api/routes/`:
  - **`GET /health`** (`api/routes/health.py`):
    - Return 200 if service healthy and model loaded
    - Return 503 if model not loaded (per spec.md §8)
    - Include model version and status
  - **`POST /predict`** (`api/routes/predict.py`):
    - Validate request with Pydantic
    - Load features and make prediction
    - Return 400 for bad requests (per spec.md §10)
    - Return 503 if model unavailable
    - Log prediction requests with correlation ID
  - **`GET /metrics`** (`api/routes/metrics.py`):
    - Request count, avg response time
    - Prediction count, errors
    - Model version info
- **Step 5.1.5:** Add startup/shutdown events:
  - On startup: load model, test database connection
  - On shutdown: cleanup resources, log metrics
- **Step 5.1.6:** Create `api/middleware/` for logging and error tracking.
- **Step 5.1.7:** Add `make run-api` command (uvicorn with reload).
- **Step 5.1.8:** Test API:
  - Start API: `make run-api`
  - Test `/health`: `curl http://localhost:8000/health`
  - Test `/predict`: Send POST with sample features
  - Verify error handling (invalid input, model unavailable)

### Chunk 5.2: Streamlit Dashboard

**Reference:** See spec.md §9 (Visualization Layer features)

- **Step 5.2.1:** Create `dashboard/app.py` with Streamlit layout:
  - Title and description
  - Sidebar for configuration/filters
  - Multi-tab layout (Overview, Predictions, Monitoring)
- **Step 5.2.2:** Implement database connection utility:
  - Use SQLAlchemy connection from config
  - Connection pooling
  - Query optimization (limit recent data)
- **Step 5.2.3:** Create **Overview Tab**:
  - **Live KPIs** (updating every 30s):
    - Average speed (last 15 min)
    - Current congestion index
    - Active roads count
    - Total vehicles processed
  - **Time series chart** (Plotly):
    - Historical average speed trend
    - Filterable by road_id and date range
    - Interactive zoom/pan
  - **Speed distribution** histogram
- **Step 5.2.4:** Create **Predictions Tab**:
  - **Input form** for prediction features:
    - Road selector (dropdown from database)
    - Date/time picker
    - Weather condition dropdown
    - Hour, day_of_week (auto-filled from datetime)
  - **Predict button:**
    - Calls FastAPI `/predict` endpoint
    - Displays predicted speed with confidence
    - Shows model version used
  - **Comparison chart:**
    - Actual vs. Predicted speed over time
    - RMSE and MAE metrics
- **Step 5.2.5:** Create **Monitoring Tab**:
  - System health status (API, Database, Kafka)
  - Recent predictions table
  - Error logs from DLQ
  - Model performance metrics from MLflow
- **Step 5.2.6:** Add error handling per spec.md §10:
  - API down: show cached data + banner alert
  - Database connection failure: retry with exponential backoff
  - Graceful degradation (show static data if live updates fail)
- **Step 5.2.7:** Implement caching with `@st.cache_data` for:
  - Database queries (1-minute TTL)
  - API responses
  - Static reference data
- **Step 5.2.8:** Add `make run-streamlit` command.
- **Step 5.2.9:** Test dashboard:
  - Run: `make run-streamlit`
  - Open: http://localhost:8501
  - Verify all tabs load correctly
  - Test prediction workflow
  - Verify fallback behavior when API is down

---

## Phase 6: Testing & CI/CD

**Goal:** Ensure system robustness through comprehensive testing and automate quality checks via CI/CD pipeline.

**Reference:** See spec.md §11 (Testing Plan), §5 (Code Quality tools), §17 (Acceptance Criteria)

### Chunk 6.1: Unit Testing

**Reference:** See spec.md §11 (Unit Tests category)

- **Step 6.1.1:** Create `tests/conftest.py` with pytest fixtures:
  - Mock Kafka producer/consumer
  - Test database connection (in-memory SQLite)
  - Sample traffic events
  - Mock MLflow client
- **Step 6.1.2:** Write `tests/unit/test_schemas.py`:
  - Test Pydantic schema validation
  - Test valid/invalid traffic events
  - Test serialization to JSON
  - Test boundary conditions (speed limits, null handling)
- **Step 6.1.3:** Write `tests/unit/test_ingestion.py`:
  - Test Kafka producer connection
  - Test event generation
  - Test DLQ routing logic
  - Test error handling (connection failures)
- **Step 6.1.4:** Write `tests/unit/test_processing.py`:
  - Test Spark transformations (mocking Spark session)
  - Test aggregation logic
  - Test speed categorization
  - Test data quality filters
- **Step 6.1.5:** Write `tests/unit/test_ml.py`:
  - Test feature engineering functions
  - Test rolling window calculations
  - Test temporal feature extraction
  - Test model input preparation
- **Step 6.1.6:** Write `tests/unit/test_utils.py`:
  - Test config loading
  - Test logging setup
  - Test database utilities

### Chunk 6.2: Integration & API Testing

**Reference:** See spec.md §11 (Integration and API Tests categories)

- **Step 6.2.1:** Write `tests/integration/test_api.py`:
  - Use FastAPI `TestClient`
  - Test `GET /health` endpoint (200 when ready, 503 when model unavailable)
  - Test `POST /predict` endpoint:
    - Valid prediction request → 200 with predicted speed
    - Invalid input → 400 with error message
    - Model unavailable → 503 with error message
  - Test `GET /metrics` endpoint
  - Test CORS headers
  - Test concurrent requests
- **Step 6.2.2:** Write `tests/integration/test_pipeline.py`:
  - End-to-end test: Kafka → Spark → PostgreSQL
  - Use docker-compose test environment
  - Send test events, verify they appear in database
  - Verify aggregations are correct
  - Test DLQ routing for malformed events
- **Step 6.2.3:** Write `tests/integration/test_model.py`:
  - Test model training workflow
  - Test MLflow model logging
  - Test model loading from registry
  - Test prediction inference

### Chunk 6.3: Advanced Testing

**Reference:** See spec.md §11 (E2E, Model Validation, Load/Perf categories)

- **Step 6.3.1:** Create `tests/e2e/test_full_flow.py`:
  - Start all services with `docker-compose`
  - Run producer for 60 seconds
  - Verify data in PostgreSQL
  - Trigger feature engineering
  - Train model and register in MLflow
  - Make prediction via API
  - Verify prediction appears in dashboard data
- **Step 6.3.2:** Add model validation tests (`tests/ml/test_model_validation.py`):
  - Test RMSE, MAE, R² calculations
  - Test model comparison logic
  - Test model promotion criteria
  - Cross-validation tests
- **Step 6.3.3:** Create load testing with `locust` (optional per spec.md §11):
  - Test `/predict` endpoint with 100 req/sec
  - Verify P95 latency < 200ms
  - Test error rates under load
- **Step 6.3.4:** Implement test commands in Makefile:
  - `make test` - Run all unit tests
  - `make test-cov` - Run with coverage report
  - `make test-integration` - Run integration tests
  - `make test-e2e` - Run end-to-end tests
- **Step 6.3.5:** Configure pytest in `pyproject.toml`:
  - Set coverage threshold to 85% (per spec.md §11)
  - Configure test discovery patterns
  - Add markers for different test types

### Chunk 6.4: CI/CD Pipeline

**Reference:** See spec.md §11 (CI Workflow), §16 (Deployment Strategy - CI/CD Pipeline)

- **Step 6.4.1:** Create `.github/workflows/ci.yml`:
  ```yaml
  name: CI Pipeline
  on: [push, pull_request]
  jobs:
    test:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - name: Install uv
          uses: astral-sh/setup-uv@v2
        - name: Set up Python
          run: uv python install 3.11
        - name: Install dependencies
          run: make sync
        - name: Run code formatting check
          run: make format --check
        - name: Run linting
          run: make lint
        - name: Run type checking
          run: make typecheck
        - name: Run tests with coverage
          run: make test-cov
        - name: Upload coverage to Codecov
          uses: codecov/codecov-action@v3
  ```
- **Step 6.4.2:** Create `.github/workflows/cd.yml` (optional deployment workflow):
  - Trigger on push to `main` branch
  - Build Docker images
  - Push to container registry
  - Deploy to cloud VM (per spec.md §16)
- **Step 6.4.3:** Add GitHub Actions badges to README.md
- **Step 6.4.4:** Configure branch protection rules:
  - Require CI to pass before merge
  - Require code review
  - Block force pushes to main

### Chunk 6.5: Documentation & Final Validation

**Reference:** See spec.md §14 (Local Development Flow), §17 (Acceptance Criteria)

- **Step 6.5.1:** Update `README.md` comprehensively:
  - Project overview and architecture diagram
  - Quick start guide (< 30 min onboarding per spec.md §17)
  - Prerequisites (Python 3.11, Docker, uv)
  - Installation steps
  - Development workflow (all `make` commands)
  - Environment variables documentation
  - Troubleshooting section
  - Contributing guidelines
- **Step 6.5.2:** Create `docs/CONTRIBUTING.md`:
  - Code style guidelines
  - Testing requirements
  - PR process
  - Development best practices
- **Step 6.5.3:** Create `docs/ARCHITECTURE.md`:
  - Include ASCII architecture diagram from spec.md §4
  - Component descriptions
  - Data flow diagrams
  - Technology choices and rationale
- **Step 6.5.4:** Add inline code documentation:
  - Docstrings for all public functions
  - Type hints throughout codebase
  - Comments for complex logic
- **Step 6.5.5:** Validate acceptance criteria from spec.md §17:
  - ✓ End-to-end pipeline flows (Kafka → DB → MLflow → API → Dashboard)
  - ✓ Model registry contains "Production" model
  - ✓ REST API serves predictions reliably
  - ✓ Dashboard visualizes live and forecast values
  - ✓ CI pipeline passes with ≥85% coverage
  - ✓ Developer onboarding < 30 minutes
- **Step 6.5.6:** Final end-to-end manual test:
  1. Fresh clone of repository
  2. Run `make dev`
  3. Run `make run-producer` (Terminal 2)
  4. Run `make run-api` (Terminal 3)
  5. Run `make run-streamlit` (Terminal 4)
  6. Verify all components work together
  7. Check MLflow UI for experiments
  8. Check Kafka UI for topics and messages
  9. Test prediction via API and dashboard
  10. Verify all acceptance criteria met
