# Real-Time Traffic Intelligence Hub — Engineering Specification

---

## 1. Overview

The Real-Time Traffic Intelligence Hub is an end-to-end data engineering and machine learning system that ingests live (Kafka) and historical (batch) traffic data, processes it through scalable Spark and Airflow pipelines, trains models with MLflow tracking, serves predictions through FastAPI, and visualizes them in a Streamlit dashboard.

This document defines requirements, architecture decisions, data handling, error strategies, and a testing plan so a developer can immediately build, scale, and operate the system.

---

## 2. Goals

- Collect and process both real-time sensor and historical traffic data.
- Build a resilient streaming + batch infrastructure (Lambda architecture).
- Provide short-term congestion forecasts and anomaly detection.
- Enable continuous model training and versioned prediction serving.
- Expose results via an API and an interactive dashboard.

---

## 3. Core Components

| Layer                 | Responsibilities                              | Key Tech                             |
| :-------------------- | :-------------------------------------------- | :----------------------------------- |
| **Ingestion**         | Continuous IoT traffic data & API integration | Kafka, Python Producer               |
| **Stream Processing** | Real-time cleaning & aggregates               | Spark Structured Streaming           |
| **Batch Processing**  | Historical ingestion, feature computation     | Spark Batch Processing               |
| **Storage**           | Raw + feature + model data                    | PostgreSQL                           |
| **ML & Tracking**     | Training, evaluation, registry                | scikit-learn, XGBoost, MLflow        |
| **Serving**           | Real-time predictions REST API                | FastAPI                              |
| **Visualization**     | Insights dashboard                            | Streamlit                            |
| **DevOps**            | Environment, testing, CI/CD                   | uv, Docker, Makefile, GitHub Actions |

---

## 4. Architectural Overview

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                            DATA INGESTION LAYER                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

                  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                  ┃       DATA SOURCES            ┃
                  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
                  ┃  • TomTom/HERE API            ┃
                  ┃  • NYC Open Data              ┃
                  ┃  • Simulated IoT Feeds        ┃
                  ┗━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┛
                                │
                                │ Kafka Producer
                                │ publishes events
                                ▼
╔══════════════════════════════════════════════════════════════════════════════╗
║                           STREAMING LAYER                                    ║
╚══════════════════════════════════════════════════════════════════════════════╝

                  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                  ┃       KAFKA TOPICS            ┃
                  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
                  ┃  traffic_raw                  ┃
                  ┃  traffic_dlq (errors)         ┃
                  ┗━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┛
                                │
                                │ Consumes & Processes
                                ▼
                  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                  ┃   SPARK STREAM AGGREGATOR     ┃
                  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
                  ┃  • Schema validation          ┃
                  ┃  • Filtering & cleaning       ┃
                  ┃  • 5-min aggregates           ┃
                  ┃  • Speed categorization       ┃
                  ┗━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┛
                                │
                                │ Writes to
                                ▼
                  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                  ┃      STORAGE LAYER            ┃
                  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
                  ┃        PostgreSQL             ┃
                  ┗━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┛
                                │
                                │ Schedules
                                ▼
╔══════════════════════════════════════════════════════════════════════════════╗
║                        BATCH PROCESSING LAYER                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

                  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                  ┃       AIRFLOW DAGS            ┃
                  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
                  ┃  • Daily batch ingestion      ┃
                  ┃  • Feature engineering        ┃
                  ┃  • Weekly model retraining    ┃
                  ┗━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┛
                                │
                                │ Registers models
                                ▼
╔══════════════════════════════════════════════════════════════════════════════╗
║                          ML & SERVING LAYER                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝

                  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                  ┃         MLFLOW                ┃
                  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
                  ┃  • Model registry             ┃
                  ┃  • Experiment tracking        ┃
                  ┃  • Artifact storage           ┃
                  ┗━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┛
                                │
                                │ Serves via
                                ▼
                  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                  ┃         FASTAPI               ┃
                  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
                  ┃  • /predict endpoint          ┃
                  ┃  • /health monitoring         ┃
                  ┃  • Model inference            ┃
                  ┗━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┛
                                │
                                │ Consumed by
                                ▼
╔══════════════════════════════════════════════════════════════════════════════╗
║                        VISUALIZATION LAYER                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

                  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                  ┃       STREAMLIT DASHBOARD     ┃
                  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
                  ┃  • Live KPIs                  ┃
                  ┃  • Historical trends          ┃
                  ┃  • Prediction visualization   ┃
                  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## 5. Environment & Build

| Tool               | Purpose                             |
| :----------------- | :---------------------------------- |
| **uv**             | Python version + dependency manager |
| **Docker Compose** | Local infra (Kafka, MLflow, DB)     |
| **Makefile**       | Unified automation                  |
| **Ruff + Mypy**    | Formatting + Linting + typing       |
| **pytest suite**   | Testing and coverage                |
| **CI/CD**          | GitHub Actions integration          |

**Base Setup:**

- **Target:** Python 3.11
- **Environment managed via:** `uv`
- **Entry commands:**

  ```bash
  # Quick Start
  make dev            # Start ALL services (infrastructure + open UIs)
  make stop-all       # Stop all running services

  # Environment Setup
  make sync           # Install/sync dependencies
  make clean          # Remove cache files

  # Code Quality
  make format         # Auto-format code
  make lint           # Check linting
  make typecheck      # Type checking
  make check          # Run all checks (lint + typecheck + test)

  # Testing
  make test           # Run tests
  make test-cov       # Run tests with coverage

  # Application Services
  make run-api        # Start FastAPI server
  make run-streamlit  # Start Streamlit dashboard
  make run-producer   # Start Kafka producer

  # Infrastructure
  make docker-up      # Start all Docker services
  make docker-down    # Stop all Docker services
  make docker-logs    # View service logs
  make docker-clean   # Stop and remove volumes

  # Utilities
  make kafka-topics   # List Kafka topics
  make kafka-ui       # Open Kafka UI (http://localhost:8080)
  make mlflow-ui      # Open MLflow UI (http://localhost:5001)
  make db-connect     # Connect to PostgreSQL
  ```

---

## 6. Data Handling Strategy

### 6.1 Data Sources

| Type          | Dataset                            | Usage                          |
| :------------ | :--------------------------------- | :----------------------------- |
| **Real-Time** | TomTom/HERE Traffic API            | Kafka producer feeds live JSON |
| **Offline**   | NYC DOT Traffic Volume (2014-2019) | Replay + training baseline     |
| **Auxiliary** | NOAA Weather, Accident data        | Enrichment for model features  |

### 6.2 Event Schema

All streaming/batch data is normalized to schema. Pydantic validation (`src/schemas/traffic_event.py`) guarantees integrity.

```
### 6.3 Storage Strategy

| Layer               | System                          | Format                |
| :------------------ | :------------------------------ | :-------------------- |
| **Raw streaming**   | Kafka topic (`traffic_raw`)     | JSON bytes            |
| **Clean processed** | PostgreSQL table                | Tabular columns       |
| **Features**        | PostgreSQL (`feature_store`)    | numeric + categorical |
| **Models**          | MLflow artifacts                | pickle                |

### 6.4 Transformation Pipeline

**Streaming (Spark Job):**

- Schema parsing
- Filtering invalid/missing data
- Computing 5-minute aggregates
- Categorizing speed bands
- Writing to PostgreSQL (errors → `traffic_dlq`)

**Batch (Airflow Tasks):**

- Daily download & cleanse
- Feature engineering (rolling stats, rush-hour flags)
- Writing to feature store
- Triggering weekly model retraining

---

## 7. Machine Learning Details

| Aspect             | Choice                                                              |
| :----------------- | :------------------------------------------------------------------ |
| **Problem**        | Predict average speed / congestion level for the next 15 min        |
| **Features**       | `rolling_means`, `weather`, `hour`, `day_of_week`, `rush_hour_flag` |
| **Models**         | `XGBoostRegressor` / `RandomForestRegressor`                        |
| **Tracking**       | MLflow (metrics: RMSE, R²)                                          |
| **Model Registry** | MLflow model name: `traffic_speed_predictor`                        |
| **Retraining**     | Airflow weekly DAG                                                  |
| **Serving**        | FastAPI loads the latest "Production" version                       |

---

## 8. Model Serving (FastAPI)

| Endpoint     | Method | Purpose                              |
| :----------- | :----- | :----------------------------------- |
| **/health**  | `GET`  | Health check                         |
| **/predict** | `POST` | Predict average speed given features |
| **/metrics** | `GET`  | Simple metrics for monitoring        |
```

````
**Startup Behavior:**

- Loads `models:/traffic_speed_predictor/Production`.
- Cached via `lru_cache`.
- If the model is unavailable, returns `503 Service Unavailable`.

---

## 9. Visualization Layer

- **Streamlit Dashboard (`dashboard/app.py`):**
  - Live KPIs (Avg Speed, Congestion Index)
  - Historical trend chart
  - Manual prediction trigger
- **Data Sources:**
  - PostgreSQL (for live window data)
  - FastAPI `/predict` endpoint

---

## 10. Error & Failure Handling

| Layer              | Failure Type                | Strategy                                    |
| :----------------- | :-------------------------- | :------------------------------------------ |
| **Kafka Producer** | Schema/serialization error  | Pydantic validation → send to DLQ           |
| **Spark Stream**   | Bad events / processing lag | Checkpoint + DLQ resend recovery            |
| **Airflow DAGs**   | Task failure                | Retries (3x) + alert email                  |
| **MLflow**         | Connection failure          | Cached local artifact until service resumes |
| **FastAPI**        | Bad request                 | Return `400` with a descriptive error       |
| **Prediction**     | Model missing               | `503 "Model not loaded"`                    |
| **Dashboard**      | API down                    | Fallback to cached data + banner alert      |
| **Storage**        | Write failure               | Retries with exponential backoff            |
| **Network**        | Transient errors            | Built-in retry decorators                   |

> All exceptions are logged by `src/utils/logging.py` to both file and stdout.

---

## 11. Testing Plan

| Category             | Tools                       | Example Scope                                  |
| :------------------- | :-------------------------- | :--------------------------------------------- |
| **Unit Tests**       | `pytest`                    | Utility functions, feature generation, schemas |
| **Integration**      | `pytest-asyncio`            | Kafka → Spark → Postgres path                  |
| **API Tests**        | FastAPI `TestClient`        | `/predict`, `/health` responses                |
| **E2E Tests**        | `pytest` + `docker-compose` | Full data flow simulation                      |
| **Model Validation** | `sklearn.metrics`           | RMSE, MAE comparison                           |
| **Load/Perf**        | `locust`                    | 100 req/sec, P95 < 200 ms                      |
| **Static Analysis**  | `ruff` + `mypy`             | Code style & typing correctness                |

- **Coverage Goal:** 85%+ enforced in CI.
- **CI Workflow (`.github/workflows/ci.yml`):**
  1. `checkout` → `uv sync`
  2. Run all checks (`make ci` - includes lint + typecheck + test)
  3. Generate coverage report (`make test-cov`)
  4. Upload coverage to Codecov

---

## 12. Data Quality Controls

| Control                   | Mechanism                             |
| :------------------------ | :------------------------------------ |
| **Schema enforcement**    | Pydantic + Spark `StructType`         |
| **Units & bounds**        | Clipping in Spark cleaning stage      |
| **Duplicate suppression** | Spark windowing + aggregations        |
| **Anomaly tagging**       | Residual vs. rolling mean threshold   |
| **Feature versioning**    | Airflow + timestamped Parquet outputs |

---

## 13. Observability & Monitoring

- **Logging:** Structured with timestamps and service names.
- **Health Checks:** `HTTP 200` from `/health` in API & Airflow sensors.

---

## 14. Local Development Flow

```bash
# Quick Start - One Command
make dev              # Starts all infrastructure + opens UIs

# Then in separate terminals:
make run-producer     # Terminal 2: Start data ingestion
make run-api          # Terminal 3: Start API service
make run-streamlit    # Terminal 4: Start dashboard

# Development workflow
make format           # Format code
make check            # Validate before committing

# Monitoring
make docker-logs      # View service logs

# Cleanup
make stop-all         # Stop everything
````

---

## 15. Folder Structure

```
real-time-traffic-intelligence/
├── .github/
│   └── workflows/
│       └── ci.yml                    # CI/CD pipeline configuration
│
├── src/                              # Main application code
│   ├── ingestion/
│   │   ├── __init__.py
│   │   └── kafka_producer.py        # Kafka producer for streaming data
│   │
│   ├── processing/
│   │   ├── __init__.py
│   │   └── spark_streaming.py       # Spark streaming jobs
│   │
│   ├── ml/
│   │   ├── __init__.py
│   │   ├── feature_engineering.py   # Feature transformation logic
│   │   └── train_model.py           # Model training scripts
│   │
│   ├── schemas/
│   │   ├── __init__.py
│   │   └── traffic_event.py         # Pydantic schemas for validation
│   │
│   └── utils/
│       ├── __init__.py
│       ├── logging.py               # Logging configuration
│       ├── config.py                # Environment config loader
│       └── spark_session.py         # Spark session utilities
│
├── api/                              # FastAPI application
│   ├── __init__.py
│   ├── main.py                       # FastAPI app entry point
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── health.py                # Health check endpoint
│   │   └── predict.py               # Prediction endpoint
│   └── models/
│       ├── __init__.py
│       └── model_loader.py          # MLflow model loader
│
├── dashboard/                        # Streamlit dashboard
│   ├── __init__.py
│   └── app.py                        # Dashboard application
│
├── airflow/                          # Airflow orchestration
│   ├── dags/
│   │   ├── batch_ingestion.py       # Daily batch data ingestion
│   │   ├── feature_engineering.py   # Feature pipeline DAG
│   │   └── model_training.py        # Weekly model retraining
│   └── config/
│       └── airflow.cfg              # Airflow configuration
│
├── tests/                            # Test suite
│   ├── unit/
│   │   ├── test_ingestion.py        # Kafka producer tests
│   │   ├── test_processing.py       # Spark processing tests
│   │   └── test_ml.py               # ML logic tests
│   ├── integration/
│   │   └── test_pipeline.py         # End-to-end pipeline tests
│   └── conftest.py                  # Pytest fixtures
│
├── data/                             # Local data storage (gitignored)
│   ├── raw/                          # Raw traffic data
│   └── processed/                    # Processed datasets
│
├── docs/                             # Documentation
│   ├── spec.md                       # Engineering specification
│   └── CONTRIBUTING.md               # Contribution guidelines
│
├── scripts/                          # Utility scripts
│   ├── setup_kafka_topics.sh        # Initialize Kafka topics
│   └── init_db.sh                   # Database schema setup
│
├── .env.example                      # Environment variables template
├── .gitignore                        # Git ignore patterns
├── .python-version                   # Python version (3.11)
├── docker-compose.yml                # Infrastructure services
├── Makefile                          # Development commands
├── pyproject.toml                    # Project dependencies
├── README.md                         # Project overview
└── uv.lock                           # Locked dependencies
```

---

## 16. Deployment Strategy

### Local Development

- **Infrastructure:** Docker Compose (`make dev`)
- **Data Volume:** Persistent volumes for PostgreSQL, MLflow artifacts
- **Networking:** Bridge network for service communication
- **Hot Reload:** API and Dashboard support live code updates

### Production Deployment

**Target Environment:** Single Cloud VM (AWS EC2 t3.medium)

**Containerization:**

```
All services run as Docker containers:
- PostgreSQL (with volume mounts for data persistence)
- Kafka + Zookeeper
- MLflow server
- FastAPI (behind Nginx reverse proxy)
- Streamlit Dashboard
- Spark streaming job
```

**Deployment Process:**

1. **Build:** GitHub Actions builds Docker images on push to `main`
2. **Registry:** Images pushed to Docker Hub / GitHub Container Registry
3. **Deploy:** SSH into VM → Pull latest images → `docker compose up -d`
4. **Health Check:** Automated health checks for API, DB, Kafka

**Infrastructure Setup:**

```bash
# On cloud VM
- Install Docker & Docker Compose
- Clone repository
- Copy .env.production with secrets
- Run: make docker-up
- Configure Nginx reverse proxy (SSL with Let's Encrypt)
- Setup systemd service for auto-restart on reboot
```

**Secrets Management:**

- Environment variables via `.env.production` (gitignored)
- Secure credential storage using cloud provider secrets (AWS Secrets Manager / Parameter Store)
- Read-only database user for dashboard/API

### CI/CD Pipeline

**GitHub Actions Workflow (`.github/workflows/cd.yml`):**

```yaml
on: push to main
jobs: 1. Run tests (make ci)
  2. Build Docker images
  3. Push to registry
  4. SSH to production VM
  5. Pull & restart services
  6. Run smoke tests
```

### Rollback Strategy

| Component         | Rollback Method                                              |
| :---------------- | :----------------------------------------------------------- |
| **ML Model**      | MLflow model version rollback (tag previous as "Production") |
| **API/Dashboard** | Revert to previous Docker image tag                          |
| **Database**      | Restore from latest backup (automated daily dumps)           |
| **Full System**   | Git revert → redeploy via CI/CD                              |

### Monitoring & Observability

| Aspect               | Tool/Method                                        |
| :------------------- | :------------------------------------------------- |
| **Application Logs** | Docker logs → CloudWatch / file rotation           |
| **Metrics**          | FastAPI `/metrics` endpoint, Docker stats          |
| **Uptime**           | Simple health check endpoint (`/health`)           |
| **Alerts**           | (Optional) Uptime monitoring service (UptimeRobot) |

### Cost Optimization

- **Estimated Monthly Cost:** ~$10-20 (single VM + minimal egress)
- **Auto-shutdown:** Optional off-hours shutdown for demo projects
- **Resource Limits:** Docker memory/CPU limits to prevent overuse

---

## 17. Acceptance Criteria

- End-to-end data pipeline flows successfully (Kafka → DB → MLflow → API → Dashboard).
- Model registry contains at least one "Production" model.
- REST API serves predictions reliably.
- Dashboard visualizes live and forecast values.
- CI pipeline passes; test coverage ≥ 85%.
- Developer onboarding takes < 30 minutes using the README.
