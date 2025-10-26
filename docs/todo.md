# Real-Time Traffic Intelligence Hub: Project Checklist

This checklist breaks down the entire project into actionable steps, following the implementation plan in [plan.md](./plan.md) and aligned with [spec.md](./spec.md).

**Progress Tracking:**

- [ ] Not started
- [x] Completed

---

## Phase 1: Foundational Setup & Environment

**Goal:** Establish a stable, reproducible development environment with all infrastructure services running locally.

**Reference:** spec.md §5 (Environment & Build), §15 (Folder Structure)

### Chunk 1.1: Project Scaffolding & Version Control

- [ ] Initialize Git repository with `.python-version` file set to `3.11`
- [ ] Create complete directory structure per spec.md §15:
  - [ ] `src/{ingestion,processing,ml,schemas,utils}/`
  - [ ] `api/{routes,models}/`
  - [ ] `dashboard/`
  - [ ] `airflow/{dags,config}/`
  - [ ] `tests/{unit,integration}/`
  - [ ] `data/{raw,processed}/`
  - [ ] `docs/`
  - [ ] `scripts/`
  - [ ] `.github/workflows/`
- [ ] Create `.gitkeep` files in `data/raw/` and `data/processed/` directories
- [ ] Initialize `pyproject.toml` with `uv` targeting Python 3.11
- [ ] Define project metadata (name, version, description, authors) in `pyproject.toml`
- [ ] Create comprehensive `.gitignore` (Python, data files, MLflow artifacts, Docker volumes, `.env`)
- [ ] Create initial `README.md` with project overview and quick start instructions
- [ ] Create `.env.example` template with all required environment variables:
  - [ ] Kafka broker URL
  - [ ] PostgreSQL connection string
  - [ ] MLflow tracking URI

### Chunk 1.2: Core Services Orchestration

**Reference:** spec.md §4 (Architectural Overview), §14 (Local Development Flow)

- [x] Create `docker-compose.yml` with service definitions
- [x] Configure PostgreSQL service (port 5432, persistent volume, init scripts support)
- [x] Configure Zookeeper service (port 2181)
- [x] Configure Kafka service (port 9092, depends_on Zookeeper)
- [x] Add Kafka UI service (port 8080, optional for monitoring)
- [x] Configure MLflow server (port 5001, PostgreSQL backend, artifact volume)
- [x] Configure Docker networking with bridge network for inter-service communication
- [ ] Add health checks for PostgreSQL and Kafka services
- [ ] Create `scripts/init_db.sh` for PostgreSQL schema initialization
- [ ] Create `scripts/setup_kafka_topics.sh` to create `traffic_raw` and `traffic_dlq` topics
- [x] Verify services: `docker compose up -d` and check logs for successful startup

### Chunk 1.3: Automation & Dependency Management

**Reference:** spec.md §5 (Environment & Build) for complete Makefile commands

- [ ] Create comprehensive `Makefile` with command groups:
  - [ ] **Quick Start:** `dev`, `stop-all`
  - [ ] **Environment:** `sync`, `clean`
  - [ ] **Code Quality:** `format`, `lint`, `typecheck`, `check`
  - [ ] **Testing:** `test`, `test-cov`
  - [ ] **Application:** `run-api`, `run-streamlit`, `run-producer`
  - [ ] **Infrastructure:** `docker-up`, `docker-down`, `docker-logs`, `docker-clean`
  - [ ] **Utilities:** `kafka-topics`, `kafka-ui`, `mlflow-ui`, `db-connect`
- [ ] Define initial dependencies in `pyproject.toml`:
  - [ ] Core: `pydantic`, `python-dotenv`
  - [ ] Quality: `ruff`, `mypy`, `pytest`, `pytest-cov`, `pytest-asyncio`
  - [ ] Data: `kafka-python`, `pyspark`, `psycopg2-binary`, `sqlalchemy`
  - [ ] ML: `scikit-learn`, `xgboost`, `mlflow`
  - [ ] API: `fastapi`, `uvicorn`
  - [ ] Dashboard: `streamlit`, `plotly`, `pandas`
  - [ ] Orchestration: `apache-airflow` (with providers)
- [ ] Implement `make sync` using `uv sync`
- [ ] Implement `make format` (ruff format), `make lint` (ruff check), `make typecheck` (mypy)
- [ ] Implement `make check` to run all quality checks sequentially
- [ ] Implement `make dev` to start all infrastructure and open browser tabs for UIs

### Chunk 1.4: Base Utilities & Configuration

**Reference:** spec.md §6.2 (Event Schema), §10 (Error Handling), §13 (Observability)

- [ ] Create `src/utils/config.py`:
  - [ ] Load from `.env` file using `python-dotenv`
  - [ ] Define settings dataclass/Pydantic model for Kafka, PostgreSQL, MLflow
  - [ ] Validate required environment variables on startup
- [ ] Create `src/utils/logging.py`:
  - [ ] Structured logging with timestamps and service names
  - [ ] Support both file and stdout output
  - [ ] Configure log levels from environment
  - [ ] Include correlation IDs for request tracing
- [ ] Create `src/utils/spark_session.py`:
  - [ ] Factory function for creating configured SparkSession
  - [ ] Include Kafka and PostgreSQL JDBC connectors
  - [ ] Set appropriate memory and executor configurations
- [ ] Define `src/schemas/traffic_event.py` using Pydantic:
  - [ ] Fields: `road_id`, `timestamp`, `speed`, `vehicle_count`, `weather_condition`, `accident_reported`
  - [ ] Validation: non-null road_id/timestamp, speed bounds (0-120), positive vehicle count
  - [ ] Include serialization methods for Kafka (JSON bytes)

---

## Phase 2: Data Ingestion & Storage

**Goal:** Implement streaming data ingestion from Kafka and establish persistent storage in PostgreSQL.

**Reference:** spec.md §4 (Data Ingestion Layer), §6 (Data Handling Strategy)

### Chunk 2.1: Real-Time Data Producer

**Reference:** spec.md §6.1 (Data Sources), §6.2 (Event Schema)

- [ ] Create `src/ingestion/kafka_producer.py` using `kafka-python` library
- [ ] Implement producer configuration:
  - [ ] Connect to Kafka broker from config
  - [ ] Set serialization (JSON with UTF-8 encoding)
  - [ ] Configure acknowledgments for reliability (`acks='all'`)
  - [ ] Add retry and timeout settings
- [ ] Create data generation functions:
  - [ ] Random traffic event generator using Pydantic schema validation
  - [ ] Support for multiple data source types (TomTom API simulation, NYC Open Data format)
  - [ ] Include realistic patterns (rush hour variations, weather correlation)
- [ ] Implement error handling per spec.md §10:
  - [ ] Pydantic validation before sending
  - [ ] Malformed events to DLQ topic (`traffic_dlq`)
  - [ ] Structured logging for all send operations
- [ ] Create main loop with configurable send rate (events/second)
- [ ] Add `make run-producer` command to Makefile
- [ ] Test producer: verify events appear in Kafka UI at `localhost:8080`

### Chunk 2.2: Database Schema & Initialization

**Reference:** spec.md §6.3 (Storage Strategy)

- [ ] Create `src/utils/database.py` with SQLAlchemy models:
  - [ ] `TrafficRaw` table (raw streaming data with JSON column)
  - [ ] `TrafficProcessed` table (cleaned, aggregated data)
  - [ ] `FeatureStore` table (ML-ready features)
  - [ ] `HistoricalTraffic` table (batch ingested data)
- [ ] Define table schemas matching spec.md §6.2:
  - [ ] Indexes on `road_id`, `timestamp` for query performance
  - [ ] Partitioning strategy for time-series data (optional)
  - [ ] Constraints for data integrity
- [ ] Update `scripts/init_db.sh`:
  - [ ] Create database and user
  - [ ] Execute SQLAlchemy table creation
  - [ ] Add initial data quality constraints
- [ ] Create `src/utils/db_connection.py`:
  - [ ] Connection pool management
  - [ ] Retry logic with exponential backoff (per spec.md §10)
  - [ ] Health check function
- [ ] Add `make db-init` and `make db-connect` commands to Makefile

### Chunk 2.3: Spark Streaming Processor (Basic)

**Reference:** spec.md §4 (Streaming Layer), §6.4 (Transformation Pipeline)

- [ ] Create `src/processing/spark_streaming.py`
- [ ] Initialize Spark Structured Streaming:
  - [ ] Use `src/utils/spark_session.py` to create session
  - [ ] Configure Kafka source (bootstrap servers, topic, starting offsets)
  - [ ] Set checkpoint directory for fault tolerance
- [ ] Implement schema parsing:
  - [ ] Define Spark `StructType` matching Pydantic schema
  - [ ] Parse JSON from Kafka value column
  - [ ] Handle schema evolution gracefully
- [ ] Add basic transformations:
  - [ ] Filter null/invalid records (per spec.md §6.4)
  - [ ] Type conversions and casting
  - [ ] Timestamp parsing and normalization
- [ ] Implement console sink for testing:
  - [ ] `writeStream.format("console")`
  - [ ] Trigger mode: processing time (5 seconds)
  - [ ] Output mode: append
- [ ] Add `make run-stream` command using `spark-submit`
- [ ] Test: Run producer + stream processor, verify console output

---

## Phase 3: End-to-End Data Flow

**Goal:** Complete the Lambda architecture by connecting streaming and batch processing to persistent storage.

**Reference:** spec.md §4 (Batch Processing Layer), §6.4 (Transformation Pipeline), §10 (Error Handling)

### Chunk 3.1: Advanced Stream Processing with PostgreSQL Sink

**Reference:** spec.md §6.4 (Transformation Pipeline - Streaming)

- [ ] Modify `src/processing/spark_streaming.py` to add aggregations:
  - [ ] Implement 5-minute tumbling window on `timestamp` column
  - [ ] Calculate per-window aggregates: `avg_speed`, `total_vehicle_count`, `max_speed`, `min_speed`
  - [ ] Add speed categorization: "free_flow" (>60), "moderate" (30-60), "congested" (<30)
- [ ] Implement data quality controls per spec.md §12:
  - [ ] Clipping: speed values to 0-120 range
  - [ ] Duplicate suppression using watermarks
  - [ ] Null handling for required fields
- [ ] Add PostgreSQL JDBC sink:
  - [ ] Download PostgreSQL JDBC driver to Spark jars
  - [ ] Configure JDBC write with `.format("jdbc")`
  - [ ] Use `foreachBatch` for better control and error handling
  - [ ] Write to `TrafficProcessed` table
  - [ ] Set appropriate batch trigger interval
- [ ] Implement checkpoint management:
  - [ ] Configure checkpoint location in local/persistent storage
  - [ ] Enable write-ahead logs for exactly-once semantics
- [ ] Add monitoring logs for processing metrics (records/second, lag)
- [ ] Test end-to-end flow:
  - [ ] `make dev` (start all infrastructure)
  - [ ] `make run-producer` (Terminal 2)
  - [ ] `make run-stream` (Terminal 3)
  - [ ] `make db-connect` and query `TrafficProcessed` table

### Chunk 3.2: Batch Processing with Airflow

**Reference:** spec.md §4 (Batch Processing Layer), §6.4 (Transformation Pipeline - Batch)

- [ ] Add Airflow to `docker-compose.yml`:
  - [ ] Airflow webserver (port 8081)
  - [ ] Airflow scheduler
  - [ ] Configure PostgreSQL as metadata database
  - [ ] Mount `airflow/dags/` directory
  - [ ] Set `AIRFLOW__CORE__LOAD_EXAMPLES=False`
- [ ] Create Airflow configuration in `airflow/config/airflow.cfg`:
  - [ ] Set executor to LocalExecutor
  - [ ] Configure connections (PostgreSQL, MLflow)
  - [ ] Email alert settings (per spec.md §10)
- [ ] Create test DAG (`airflow/dags/hello_world_dag.py`) to verify setup
- [ ] Create `airflow/dags/batch_ingestion.py`:
  - [ ] Schedule: daily at 2 AM (`schedule_interval="0 2 * * *"`)
  - [ ] Task 1: Download/read historical data (NYC DOT Traffic Volume CSV)
  - [ ] Task 2: Data cleansing (remove nulls, normalize timestamps, validate schema)
  - [ ] Task 3: Write to `HistoricalTraffic` table in PostgreSQL
  - [ ] Configure retries: 3 attempts with exponential backoff (per spec.md §10)
- [ ] Add utility tasks:
  - [ ] Data quality checks (row count, null percentage, date range)
  - [ ] Alerts on failure (email or log)
- [ ] Test DAG: `make airflow-ui` (<http://localhost:8081>), trigger manually, verify execution

### Chunk 3.3: Error Handling & Dead-Letter Queue

**Reference:** spec.md §10 (Error & Failure Handling)

- [ ] Update `scripts/setup_kafka_topics.sh` to create `traffic_dlq` topic
- [ ] Modify Spark streaming job for DLQ pattern:
  - [ ] Wrap JSON parsing in try-except
  - [ ] On `JSONDecodeError` or Pydantic `ValidationError`:
    - [ ] Log error with event details
    - [ ] Send malformed event to `traffic_dlq` topic
    - [ ] Continue processing (don't fail job)
  - [ ] Track DLQ metrics (count, error types)
- [ ] Update `src/ingestion/kafka_producer.py`:
  - [ ] Add `--error-rate` CLI flag (default 0.05)
  - [ ] Randomly inject malformed JSON (missing fields, invalid types)
  - [ ] Log when sending corrupt data for testing
- [ ] Create DLQ monitoring script (`src/processing/dlq_monitor.py`):
  - [ ] Consume from `traffic_dlq` topic
  - [ ] Log error patterns
  - [ ] Option to replay/fix and resubmit to `traffic_raw`
- [ ] Test DLQ flow:
  - [ ] Run producer with error injection
  - [ ] Verify Spark job continues processing good events
  - [ ] Check `traffic_dlq` topic in Kafka UI for malformed events
  - [ ] Verify structured logging captures error details

---

## Phase 4: Machine Learning Integration

**Goal:** Build, train, and track ML models for traffic prediction with automated retraining.

**Reference:** spec.md §7 (Machine Learning Details), §4 (ML & Serving Layer)

### Chunk 4.1: Feature Engineering Pipeline

**Reference:** spec.md §7 (Features), §12 (Data Quality Controls)

- [ ] Create `src/ml/feature_engineering.py` with feature transformation logic
- [ ] Implement feature generation functions:
  - [ ] **Temporal features:** `hour_of_day`, `day_of_week`, `month`, `is_weekend`
  - [ ] **Rush hour flag:** Define morning (7-9 AM) and evening (5-7 PM) rush hours
  - [ ] **Rolling statistics:**
    - [ ] 1-hour rolling mean of speed
    - [ ] 3-hour rolling mean of vehicle count
    - [ ] Rolling standard deviation for volatility
  - [ ] **Weather features:** Categorical encoding (if available)
  - [ ] **Lag features:** Previous hour's average speed
- [ ] Add feature versioning per spec.md §12:
  - [ ] Timestamp feature creation runs
  - [ ] Version identifier in feature table
  - [ ] Schema validation for feature columns
- [ ] Implement data reading:
  - [ ] Query `TrafficProcessed` and `HistoricalTraffic` tables
  - [ ] Union streaming and batch data
  - [ ] Filter by date range (e.g., last 90 days)
- [ ] Write to `FeatureStore` table:
  - [ ] Include all features + target variable (future speed)
  - [ ] Add metadata columns (created_at, feature_version)
  - [ ] Implement upsert logic to prevent duplicates
- [ ] Add `make run-features` command
- [ ] Test: Run feature generation, query `FeatureStore` table

### Chunk 4.2: Model Training & MLflow Tracking

**Reference:** spec.md §7 (Model details, Tracking, Registry)

- [ ] Create `src/ml/train_model.py` for model training
- [ ] Configure MLflow:
  - [ ] Set tracking URI from config (`http://localhost:5001`)
  - [ ] Create/set experiment name: `traffic_speed_prediction`
  - [ ] Enable autologging for scikit-learn/XGBoost
- [ ] Implement data loading from `FeatureStore`:
  - [ ] Train/validation/test split (70/15/15)
  - [ ] Feature selection based on spec.md §7
  - [ ] Target variable: average speed for next 15 minutes
- [ ] Implement model training with MLflow tracking:
  - [ ] Log parameters (model_type, n_estimators, etc.)
  - [ ] Train XGBoost and RandomForest models
  - [ ] Log metrics (RMSE, MAE, R²)
  - [ ] Log model using `mlflow.sklearn.log_model`
  - [ ] Log feature importance plot
- [ ] Add model comparison logic:
  - [ ] Train both XGBoost and RandomForest
  - [ ] Compare metrics
  - [ ] Select best performing model
- [ ] Implement model validation per spec.md §11:
  - [ ] Cross-validation scores
  - [ ] Residual analysis
  - [ ] Feature importance visualization
- [ ] Add `make train-model` command
- [ ] Test: Run training, check MLflow UI at `localhost:5001`

### Chunk 4.3: Model Registry & Automated Retraining

**Reference:** spec.md §7 (Model Registry, Retraining)

- [ ] Add model registration to `src/ml/train_model.py`:
  - [ ] Register best model to MLflow Model Registry
  - [ ] Model name: `traffic_speed_predictor`
  - [ ] Add tags (version, training_date, metrics)
  - [ ] Transition to "Staging" initially
- [ ] Create model promotion script (`src/ml/promote_model.py`):
  - [ ] Compare Staging model metrics with Production
  - [ ] If improvement threshold met (e.g., 5% RMSE reduction), promote to Production
  - [ ] Otherwise, keep current Production model
  - [ ] Archive old Production model
- [ ] Create Airflow DAG (`airflow/dags/model_training.py`):
  - [ ] **Schedule:** Weekly on Sundays at 3 AM (`0 3 * * 0`)
  - [ ] **Task 1:** `run_feature_engineering` - Execute feature generation
  - [ ] **Task 2:** `train_model` - Run model training with MLflow
  - [ ] **Task 3:** `evaluate_and_promote` - Compare and promote model if better
  - [ ] **Task 4:** `send_metrics_report` - Log training summary
  - [ ] **Retries:** 3 with exponential backoff (per spec.md §10)
- [ ] Add error handling per spec.md §10:
  - [ ] MLflow connection failure: use cached artifact, send alert
  - [ ] Training failure: send email, keep previous model in Production
  - [ ] Data quality issues: fail with descriptive error
- [ ] Test DAG:
  - [ ] Trigger manually in Airflow UI
  - [ ] Verify model appears in MLflow Registry
  - [ ] Check model version transitions (Staging → Production)

---

## Phase 5: Serving & Visualization

**Goal:** Expose ML predictions via REST API and create an interactive dashboard for monitoring and visualization.

**Reference:** spec.md §8 (Model Serving), §9 (Visualization Layer)

### Chunk 5.1: FastAPI Prediction Service

**Reference:** spec.md §8 (Model Serving endpoints, startup behavior)

- [ ] Create FastAPI app structure in `api/main.py`:
  - [ ] Initialize FastAPI app with metadata (title, version, description)
  - [ ] Configure CORS middleware
  - [ ] Add exception handlers
  - [ ] Include structured logging
- [ ] Create `api/models/model_loader.py`:
  - [ ] Implement model loader using MLflow Python API
  - [ ] Load `models:/traffic_speed_predictor/Production`
  - [ ] Use `@lru_cache` for efficient model caching
  - [ ] Handle model not found gracefully
  - [ ] Add model reload capability (for updates)
- [ ] Create request/response schemas in `api/schemas/`:
  - [ ] `PredictionRequest`: features per spec.md §7
  - [ ] `PredictionResponse`: predicted_speed, confidence_interval, model_version, timestamp
  - [ ] `HealthResponse`: status, model_loaded, model_version, uptime
- [ ] Implement endpoints in `api/routes/`:
  - [ ] **`GET /health`** (`api/routes/health.py`):
    - [ ] Return 200 if service healthy and model loaded
    - [ ] Return 503 if model not loaded (per spec.md §8)
    - [ ] Include model version and status
  - [ ] **`POST /predict`** (`api/routes/predict.py`):
    - [ ] Validate request with Pydantic
    - [ ] Load features and make prediction
    - [ ] Return 400 for bad requests (per spec.md §10)
    - [ ] Return 503 if model unavailable
    - [ ] Log prediction requests with correlation ID
  - [ ] **`GET /metrics`** (`api/routes/metrics.py`):
    - [ ] Request count, avg response time
    - [ ] Prediction count, errors
    - [ ] Model version info
- [ ] Add startup/shutdown events:
  - [ ] On startup: load model, test database connection
  - [ ] On shutdown: cleanup resources, log metrics
- [ ] Create `api/middleware/` for logging and error tracking
- [ ] Add `make run-api` command (uvicorn with reload)
- [ ] Test API:
  - [ ] Start API: `make run-api`
  - [ ] Test `/health`: `curl http://localhost:8000/health`
  - [ ] Test `/predict`: Send POST with sample features
  - [ ] Verify error handling (invalid input, model unavailable)

### Chunk 5.2: Streamlit Dashboard

**Reference:** spec.md §9 (Visualization Layer features)

- [ ] Create `dashboard/app.py` with Streamlit layout:
  - [ ] Title and description
  - [ ] Sidebar for configuration/filters
  - [ ] Multi-tab layout (Overview, Predictions, Monitoring)
- [ ] Implement database connection utility:
  - [ ] Use SQLAlchemy connection from config
  - [ ] Connection pooling
  - [ ] Query optimization (limit recent data)
- [ ] Create **Overview Tab**:
  - [ ] **Live KPIs** (updating every 30s):
    - [ ] Average speed (last 15 min)
    - [ ] Current congestion index
    - [ ] Active roads count
    - [ ] Total vehicles processed
  - [ ] **Time series chart** (Plotly):
    - [ ] Historical average speed trend
    - [ ] Filterable by road_id and date range
    - [ ] Interactive zoom/pan
  - [ ] **Speed distribution** histogram
- [ ] Create **Predictions Tab**:
  - [ ] **Input form** for prediction features:
    - [ ] Road selector (dropdown from database)
    - [ ] Date/time picker
    - [ ] Weather condition dropdown
    - [ ] Hour, day_of_week (auto-filled from datetime)
  - [ ] **Predict button:**
    - [ ] Calls FastAPI `/predict` endpoint
    - [ ] Displays predicted speed with confidence
    - [ ] Shows model version used
  - [ ] **Comparison chart:**
    - [ ] Actual vs. Predicted speed over time
    - [ ] RMSE and MAE metrics
- [ ] Create **Monitoring Tab**:
  - [ ] System health status (API, Database, Kafka)
  - [ ] Recent predictions table
  - [ ] Error logs from DLQ
  - [ ] Model performance metrics from MLflow
- [ ] Add error handling per spec.md §10:
  - [ ] API down: show cached data + banner alert
  - [ ] Database connection failure: retry with exponential backoff
  - [ ] Graceful degradation (show static data if live updates fail)
- [ ] Implement caching with `@st.cache_data` for:
  - [ ] Database queries (1-minute TTL)
  - [ ] API responses
  - [ ] Static reference data
- [ ] Add `make run-streamlit` command
- [ ] Test dashboard:
  - [ ] Run: `make run-streamlit`
  - [ ] Open: <http://localhost:8501>
  - [ ] Verify all tabs load correctly
  - [ ] Test prediction workflow
  - [ ] Verify fallback behavior when API is down

---

## Phase 6: Testing & CI/CD

**Goal:** Ensure system robustness through comprehensive testing and automate quality checks via CI/CD pipeline.

**Reference:** spec.md §11 (Testing Plan), §5 (Code Quality tools), §17 (Acceptance Criteria)

### Chunk 6.1: Unit Testing

**Reference:** spec.md §11 (Unit Tests category)

- [ ] Create `tests/conftest.py` with pytest fixtures:
  - [ ] Mock Kafka producer/consumer
  - [ ] Test database connection (in-memory SQLite)
  - [ ] Sample traffic events
  - [ ] Mock MLflow client
- [ ] Write `tests/unit/test_schemas.py`:
  - [ ] Test Pydantic schema validation
  - [ ] Test valid/invalid traffic events
  - [ ] Test serialization to JSON
  - [ ] Test boundary conditions (speed limits, null handling)
- [ ] Write `tests/unit/test_ingestion.py`:
  - [ ] Test Kafka producer connection
  - [ ] Test event generation
  - [ ] Test DLQ routing logic
  - [ ] Test error handling (connection failures)
- [ ] Write `tests/unit/test_processing.py`:
  - [ ] Test Spark transformations (mocking Spark session)
  - [ ] Test aggregation logic
  - [ ] Test speed categorization
  - [ ] Test data quality filters
- [ ] Write `tests/unit/test_ml.py`:
  - [ ] Test feature engineering functions
  - [ ] Test rolling window calculations
  - [ ] Test temporal feature extraction
  - [ ] Test model input preparation
- [ ] Write `tests/unit/test_utils.py`:
  - [ ] Test config loading
  - [ ] Test logging setup
  - [ ] Test database utilities

### Chunk 6.2: Integration & API Testing

**Reference:** spec.md §11 (Integration and API Tests categories)

- [ ] Write `tests/integration/test_api.py`:
  - [ ] Use FastAPI `TestClient`
  - [ ] Test `GET /health` endpoint (200 when ready, 503 when model unavailable)
  - [ ] Test `POST /predict` endpoint:
    - [ ] Valid prediction request → 200 with predicted speed
    - [ ] Invalid input → 400 with error message
    - [ ] Model unavailable → 503 with error message
  - [ ] Test `GET /metrics` endpoint
  - [ ] Test CORS headers
  - [ ] Test concurrent requests
- [ ] Write `tests/integration/test_pipeline.py`:
  - [ ] End-to-end test: Kafka → Spark → PostgreSQL
  - [ ] Use docker-compose test environment
  - [ ] Send test events, verify they appear in database
  - [ ] Verify aggregations are correct
  - [ ] Test DLQ routing for malformed events
- [ ] Write `tests/integration/test_model.py`:
  - [ ] Test model training workflow
  - [ ] Test MLflow model logging
  - [ ] Test model loading from registry
  - [ ] Test prediction inference

### Chunk 6.3: Advanced Testing

**Reference:** spec.md §11 (E2E, Model Validation, Load/Perf categories)

- [ ] Create `tests/e2e/test_full_flow.py`:
  - [ ] Start all services with `docker-compose`
  - [ ] Run producer for 60 seconds
  - [ ] Verify data in PostgreSQL
  - [ ] Trigger feature engineering
  - [ ] Train model and register in MLflow
  - [ ] Make prediction via API
  - [ ] Verify prediction appears in dashboard data
- [ ] Add model validation tests (`tests/ml/test_model_validation.py`):
  - [ ] Test RMSE, MAE, R² calculations
  - [ ] Test model comparison logic
  - [ ] Test model promotion criteria
  - [ ] Cross-validation tests
- [ ] Create load testing with `locust` (optional per spec.md §11):
  - [ ] Test `/predict` endpoint with 100 req/sec
  - [ ] Verify P95 latency < 200ms
  - [ ] Test error rates under load
- [ ] Implement test commands in Makefile:
  - [ ] `make test` - Run all unit tests
  - [ ] `make test-cov` - Run with coverage report
  - [ ] `make test-integration` - Run integration tests
  - [ ] `make test-e2e` - Run end-to-end tests
- [ ] Configure pytest in `pyproject.toml`:
  - [ ] Set coverage threshold to 85% (per spec.md §11)
  - [ ] Configure test discovery patterns
  - [ ] Add markers for different test types

### Chunk 6.4: CI/CD Pipeline

**Reference:** spec.md §11 (CI Workflow), §16 (Deployment Strategy - CI/CD Pipeline)

- [ ] Create `.github/workflows/ci.yml`:
  - [ ] Configure workflow to trigger on `push` and `pull_request`
  - [ ] Add job: checkout code
  - [ ] Add job: install uv
  - [ ] Add job: set up Python 3.11
  - [ ] Add job: install dependencies (`make sync`)
  - [ ] Add job: run code formatting check (`make format --check`)
  - [ ] Add job: run linting (`make lint`)
  - [ ] Add job: run type checking (`make typecheck`)
  - [ ] Add job: run tests with coverage (`make test-cov`)
  - [ ] Add job: upload coverage to Codecov
- [ ] Create `.github/workflows/cd.yml` (optional deployment workflow):
  - [ ] Trigger on push to `main` branch
  - [ ] Build Docker images
  - [ ] Push to container registry
  - [ ] Deploy to cloud VM (per spec.md §16)
- [ ] Add GitHub Actions badges to README.md
- [ ] Configure branch protection rules:
  - [ ] Require CI to pass before merge
  - [ ] Require code review
  - [ ] Block force pushes to main

### Chunk 6.5: Documentation & Final Validation

**Reference:** spec.md §14 (Local Development Flow), §17 (Acceptance Criteria)

- [ ] Update `README.md` comprehensively:
  - [ ] Project overview and architecture diagram
  - [ ] Quick start guide (< 30 min onboarding per spec.md §17)
  - [ ] Prerequisites (Python 3.11, Docker, uv)
  - [ ] Installation steps
  - [ ] Development workflow (all `make` commands)
  - [ ] Environment variables documentation
  - [ ] Troubleshooting section
  - [ ] Contributing guidelines
- [ ] Create `docs/CONTRIBUTING.md`:
  - [ ] Code style guidelines
  - [ ] Testing requirements
  - [ ] PR process
  - [ ] Development best practices
- [ ] Create `docs/ARCHITECTURE.md`:
  - [ ] Include ASCII architecture diagram from spec.md §4
  - [ ] Component descriptions
  - [ ] Data flow diagrams
  - [ ] Technology choices and rationale
- [ ] Add inline code documentation:
  - [ ] Docstrings for all public functions
  - [ ] Type hints throughout codebase
  - [ ] Comments for complex logic
- [ ] Validate acceptance criteria from spec.md §17:
  - [ ] ✓ End-to-end pipeline flows (Kafka → DB → MLflow → API → Dashboard)
  - [ ] ✓ Model registry contains "Production" model
  - [ ] ✓ REST API serves predictions reliably
  - [ ] ✓ Dashboard visualizes live and forecast values
  - [ ] ✓ CI pipeline passes with ≥85% coverage
  - [ ] ✓ Developer onboarding < 30 minutes
- [ ] Final end-to-end manual test:
  - [ ] Fresh clone of repository
  - [ ] Run `make dev`
  - [ ] Run `make run-producer` (Terminal 2)
  - [ ] Run `make run-api` (Terminal 3)
  - [ ] Run `make run-streamlit` (Terminal 4)
  - [ ] Verify all components work together
  - [ ] Check MLflow UI for experiments
  - [ ] Check Kafka UI for topics and messages
  - [ ] Test prediction via API and dashboard
  - [ ] Verify all acceptance criteria met

---

## Progress Summary

Track your overall progress here:

- **Phase 1:** [ ] Complete
- **Phase 2:** [ ] Complete
- **Phase 3:** [ ] Complete
- **Phase 4:** [ ] Complete
- **Phase 5:** [ ] Complete
- **Phase 6:** [ ] Complete
