# **Real-Time Traffic Intelligence Hub — Engineering Specification**

---

### **1. 📘 Overview**

The Real-Time Traffic Intelligence Hub is an end-to-end data engineering and machine learning system that ingests live (Kafka) and historical (batch) traffic data, processes it through scalable Spark and Airflow pipelines, trains models with MLflow tracking, serves predictions through FastAPI, and visualizes them in a Streamlit dashboard.

This document defines requirements, architecture decisions, data handling, error strategies, and a testing plan so a developer can immediately build, scale, and operate the system.

---

### **2. 🎯 Goals**

- Collect and process both real-time sensor and historical traffic data.
- Build a resilient streaming + batch infrastructure (Lambda architecture).
- Provide short-term congestion forecasts and anomaly detection.
- Enable continuous model training and versioned prediction serving.
- Expose results via an API and an interactive dashboard.

---

### **3. 🧱 Core Components**

| Layer                 | Responsibilities                              | Key Tech                             |
| :-------------------- | :-------------------------------------------- | :----------------------------------- |
| **Ingestion**         | Continuous IoT traffic data & API integration | Kafka, Python Producer               |
| **Stream Processing** | Real-time cleaning & aggregates               | Spark Structured Streaming           |
| **Batch Processing**  | Historical ingestion, feature computation     | Apache Airflow                       |
| **Storage**           | Raw + feature + model data                    | PostgreSQL, S3 (data lake)           |
| **ML & Tracking**     | Training, evaluation, registry                | scikit-learn, XGBoost, MLflow        |
| **Serving**           | Real-time predictions REST API                | FastAPI                              |
| **Visualization**     | Insights dashboard                            | Streamlit + Plotly                   |
| **DevOps**            | Environment, testing, CI/CD                   | uv, Docker, Makefile, GitHub Actions |

---

### **4. ⚙️ Architectural Overview**

```
┌────────────────────┐
│   Data Sources      │
│ ─────────────────── │
│  • TomTom/HERE API  │
│  • NYC Open Data    │
│  • Simulated Feeds  │
└─────────┬───────────┘
          │
 (Kafka Producer publishes events)
          │
     ┌────▼───────────────────────────┐
     │       Kafka Topics             │
     │ traffic_raw / processed / dlq  │
     └────┬───────────────────────────┘
          │
   ┌──────▼────────┐
   │ Spark Stream  │ cleans + enriches
   │ Aggregator    │ writes to DB
   └──────┬────────┘
          │
         (DB/S3)
          │
   ┌──────▼────────┐
   │ Airflow DAGs  │
   │ Batch ingest   │
   │ Feature build  │
   │ Model retrain  │
   └──────┬────────┘
          │
   ┌──────▼────────┐
   │   MLflow      │ model registry + artifacts
   └──────┬────────┘
          │
   ┌──────▼────────┐
   │ FastAPI        │ provides predictions
   └──────┬────────┘
          │
   ┌──────▼────────┐
   │ Streamlit     │ visualizes insights
   └───────────────┘
```

---

### **5. 📦 Environment & Build**

| Tool               | Purpose                             |
| :----------------- | :---------------------------------- |
| **uv**             | Python version + dependency manager |
| **Docker Compose** | Local infra (Kafka, MLflow, DB)     |
| **Makefile**       | Unified automation                  |
| **Ruff + Mypy**    | Linting + typing                    |
| **pytest suite**   | Testing and coverage                |
| **CI/CD**          | GitHub Actions integration          |

**Base Setup:**

- **Target:** Python 3.11
- **Environment managed via:** `uv`
- **Entry commands:**
  ```bash
  make sync          # install deps
  make qa            # lint + type check
  make test          # run tests
  make producer      # start replay producer
  make api           # run FastAPI service
  make dashboard     # start Streamlit UI
  ```

---

### **6. 🗃️ Data Handling Strategy**

#### **6.1 Data Sources**

| Type          | Dataset                            | Usage                          |
| :------------ | :--------------------------------- | :----------------------------- |
| **Real-Time** | TomTom/HERE Traffic API            | Kafka producer feeds live JSON |
| **Offline**   | NYC DOT Traffic Volume (2014-2019) | Replay + training baseline     |
| **Auxiliary** | NOAA Weather, Accident data        | Enrichment for model features  |

#### **6.2 Event Schema**

All streaming/batch data is normalized to the following schema. Pydantic validation (`src/schemas/traffic_event.py`) guarantees integrity.

```json
{
  "road_id": "R_1032",
  "timestamp": "2025-10-26T13:15:00Z",
  "vehicle_count": 24,
  "avg_speed": 46.7,
  "latitude": 40.73,
  "longitude": -73.98,
  "weather": "rain"
}
```

#### **6.3 Storage Strategy**

| Layer                | System                                         | Format                |
| :------------------- | :--------------------------------------------- | :-------------------- |
| **Raw streaming**    | Kafka topic (`traffic_raw`)                    | JSON bytes            |
| **Clean processed**  | PostgreSQL table                               | Tabular columns       |
| **Data lake backup** | S3 bucket (`traffic-raw`, `traffic-processed`) | Parquet               |
| **Features**         | PostgreSQL (`feature_store`)                   | numeric + categorical |
| **Models**           | MLflow artifacts                               | pickle / pyfunc       |

#### **6.4 Transformation Pipeline**

**Streaming (Spark Job):**

- Schema parsing
- Filtering invalid/missing data
- Computing 5-minute aggregates
- Categorizing speed bands
- Writing to Postgres + `traffic_processed` topic

**Batch (Airflow Tasks):**

- Daily download & cleanse
- Feature engineering (rolling stats, rush-hour flags)
- Writing to feature store
- Triggering weekly model retraining

---

### **7. 📊 Machine Learning Details**

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

### **8. 🧩 Model Serving (FastAPI)**

| Endpoint     | Method | Purpose                              |
| :----------- | :----- | :----------------------------------- |
| **/health**  | `GET`  | Health check                         |
| **/predict** | `POST` | Predict average speed given features |
| **/metrics** | `GET`  | Simple metrics for monitoring        |

**Request Schema:**

```json
{
  "road_id": "R_1032",
  "hour": 14,
  "day_of_week": 2,
  "is_rush_hour": true,
  "vol_rolling_mean_3h": 42.1
}
```

**Response Schema:**

```json
{
  "predicted_speed": 47.2,
  "confidence": 0.83,
  "timestamp": "2025-10-26T13:20:00Z"
}
```

**Startup Behavior:**

- Loads `models:/traffic_speed_predictor/Production`.
- Cached via `lru_cache`.
- If the model is unavailable, returns `503 Service Unavailable`.

---

### **9. 🎨 Visualization Layer**

- **Streamlit Dashboard (`visualization/dashboard.py`):**
  - Live KPIs (Avg Speed, Congestion Index)
  - Interactive map colored by speed (Plotly + Mapbox)
  - Historical trend chart
  - Manual prediction trigger
- **Data Sources:**
  - PostgreSQL (for live window data)
  - FastAPI `/predict` endpoint

---

### **10. 🧮 Error & Failure Handling**

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

> All exceptions are logged by `src/utils/logging_utils.py` to both file and stdout.

---

### **11. 🧪 Testing Plan**

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
  2. Lint + type check (`make qa`)
  3. Run tests (`pytest --cov`)
  4. Upload coverage to Codecov

---

### **12. 🧠 Data Quality Controls**

| Control                   | Mechanism                             |
| :------------------------ | :------------------------------------ |
| **Schema enforcement**    | Pydantic + Spark `StructType`         |
| **Units & bounds**        | Clipping in Spark cleaning stage      |
| **Duplicate suppression** | Spark windowing + aggregations        |
| **Anomaly tagging**       | Residual vs. rolling mean threshold   |
| **Feature versioning**    | Airflow + timestamped Parquet outputs |

---

### **13. 🧰 Observability & Monitoring**

- **Logging:** Structured with timestamps and service names.
- **Metrics:** Exposed at `/metrics` for Prometheus.
- **Dashboards:** Optional Grafana (for Kafka lag, API latency).
- **Health Checks:** `HTTP 200` from `/health` in API & Airflow sensors.

---

### **14. 💻 Local Development Flow**

```bash
# 1. Start all infrastructure services in the background
docker compose up -d

# 2. Send streaming data to the Kafka topic
make producer

# 3. Run the prediction API service
make api

# 4. Start the visualization dashboard
make dashboard

# 5. Validate codebase before committing
make qa && make test
```

---

### **15. 📁 Folder Structure**

```
traffic-intelligence-hub/
├── airflow/                 # DAGs for batch, feature, retrain
├── kafka_producer/          # Real-time + replay producers
├── spark_streaming/         # Stream processors + transformations
├── ml/
│   ├── feature_engineering.py
│   ├── train_model.py
│   └── predict_service/
│       ├── main.py
│       └── model_loader.py
├── visualization/           # Streamlit dashboard
├── src/utils/               # logging, spark_session, config, metrics
├── tests/                   # all pytest tests
├── data/                    # raw + processed datasets
├── docker-compose.yml
├── Makefile
├── pyproject.toml
├── uv.lock
└── docs/                    # architecture & contributions
```

---

### **16. 🚀 Deployment Strategy**

| Environment         | Strategy                                          |
| :------------------ | :------------------------------------------------ |
| **Local Dev**       | Docker Compose stack                              |
| **Staging**         | Container images → Cloud VM (EC2 / GCP Compute)   |
| **Prod (optional)** | Kubernetes deployment (Helm chart)                |
| **Monitoring**      | Prometheus + Grafana                              |
| **Rollback**        | MLflow model version rollback + `compose down/up` |

---

### **17. ✅ Acceptance Criteria**

- End-to-end data pipeline flows successfully (Kafka → DB → MLflow → API → Dashboard).
- Model registry contains at least one "Production" model.
- REST API serves predictions reliably.
- Dashboard visualizes live and forecast values.
- CI pipeline passes; test coverage ≥ 85%.
- Developer onboarding takes < 30 minutes using the README.

---

### **18. 🧩 Future Extensions**

- Add real-time alerting for congestion anomalies.
- Scale Spark jobs cluster-wide (e.g., AWS EMR / Dataproc).
- Integrate dedicated feature-store systems (e.g., Feast / Hopsworks).
- Deploy models via MLflow's Docker registry on Kubernetes.
- Add authentication and role-based access to the API.
- Use a stream-to-stream join with weather topics for richer ML context.
