# Real-Time Traffic Intelligence Hub: Project Checklist

This checklist breaks down the entire project into actionable steps, following the phased blueprint. Mark items as complete as you progress.

---

## Phase 1: Foundational Setup & Environment

**Goal:** Establish a stable, reproducible development environment.

### Chunk 1.1: Project Scaffolding & Version Control

- [ ] Initialize a new Git repository (`git init`).
- [ ] Create the top-level directory structure (`airflow/`, `kafka_producer/`, `ml/`, `src/utils/`, `tests/`, `data/`, `docs/`, `visualization/`).
- [ ] Add placeholder `.gitkeep` files to empty directories to ensure they are tracked by Git.
- [ ] Create and initialize the `pyproject.toml` file.
- [ ] Create an initial `README.md` with a project overview.
- [ ] Create a standard Python `.gitignore` file.

### Chunk 1.2: Core Services Orchestration

- [ ] Create the `docker-compose.yml` file.
- [ ] Add the PostgreSQL service, including volume for data persistence and environment variables for credentials.
- [ ] Add Zookeeper and Kafka services, ensuring they are on the same Docker network.
- [ ] Add the MLflow tracking server service.
- [ ] Configure MLflow to use the PostgreSQL instance as its backend store.
- [ ] Configure MLflow to use a local volume for storing artifacts.
- [ ] Verify that `docker compose up -d` starts all services without errors.

### Chunk 1.3: Automation & Dependency Management

- [ ] Create the `Makefile`.
- [ ] Add initial dependencies to `pyproject.toml`: `pydantic`, `ruff`, `mypy`.
- [ ] Implement `make sync` command in the Makefile (`uv sync`).
- [ ] Implement `make qa` command (`ruff check . && mypy .`).
- [ ] Add basic Docker Compose commands to the Makefile: `make up`, `make down`, `make logs`.

### Chunk 1.4: Base Utilities & Configuration

- [ ] Create a configuration management file (`src/utils/config.py`) to load settings from environment variables.
- [ ] Implement a standardized logging utility (`src/utils/logging_utils.py`) for structured logging.
- [ ] Define the core traffic event schema using Pydantic (`src/schemas/traffic_event.py`).

---

## Phase 2: Data Ingestion & Storage

**Goal:** Get data flowing into the system and stored correctly.

### Chunk 2.1: Real-Time Data Producer

- [ ] Add `kafka-python` to `pyproject.toml` and run `make sync`.
- [ ] Create the producer script (`kafka_producer/producer.py`).
- [ ] Implement Kafka connection logic using the config utility.
- [ ] Write a function to generate a valid traffic event based on the Pydantic schema.
- [ ] Create a main loop to send events to the `traffic_raw` Kafka topic.
- [ ] Add `make producer` command to the Makefile.

### Chunk 2.2: Initial Database Setup

- [ ] Add `psycopg2-binary` and `sqlalchemy` to `pyproject.toml` and run `make sync`.
- [ ] Create a database initialization script (`src/utils/init_db.py`).
- [ ] Define the table schema for `processed_traffic_data` in the script.
- [ ] Add a `make init-db` command to the Makefile to execute the script.

### Chunk 2.3: Simple Stream Processor

- [ ] Add `pyspark` to `pyproject.toml` and run `make sync`.
- [ ] Create the Spark streaming script (`spark_streaming/stream_processor.py`).
- [ ] Implement a SparkSession utility (`src/utils/spark_session.py`).
- [ ] Configure the Spark job to read from the `traffic_raw` Kafka topic.
- [ ] Implement a basic transformation (JSON parsing, field selection).
- [ ] Use a `console` sink to print the streaming DataFrame for initial verification.
- [ ] Add a `make stream` command to the Makefile.

---

## Phase 3: End-to-End Data Flow

**Goal:** Connect components to create a complete, simple streaming pipeline.

### Chunk 3.1: Persisting Streamed Data

- [ ] Modify the Spark job to write to the PostgreSQL `processed_traffic_data` table instead of the console.
- [ ] Add schema validation and null-value filtering to the Spark job.
- [ ] Implement a 5-minute tumbling window aggregation (avg_speed, vehicle_count).
- [ ] Run the full flow (`make up`, `make init-db`, `make producer`, `make stream`) and verify data appears in PostgreSQL.

### Chunk 3.2: Batch Ingestion with Airflow

- [ ] Add `apache-airflow` to `pyproject.toml` and `make sync`.
- [ ] Add an Airflow service (webserver, scheduler) to `docker-compose.yml`, using the existing PostgreSQL as a backend.
- [ ] Create a simple "Hello World" DAG to verify the Airflow instance works.
- [ ] Create a daily batch ingestion DAG (`airflow/dags/batch_ingestion_dag.py`).
- [ ] Implement a task to read historical data from a local CSV file.
- [ ] Implement a task to cleanse the data and append it to a `historical_traffic_data` table in PostgreSQL.

### Chunk 3.3: Dead-Letter Queue (DLQ) for Error Handling

- [ ] In the Spark job, add error handling for JSON parsing.
- [ ] On parsing failure, write the malformed event to a `traffic_dlq` Kafka topic.
- [ ] Modify the Kafka producer to occasionally send a malformed message.
- [ ] Verify that bad messages land in the DLQ while good messages are still processed.

---

## Phase 4: Machine Learning Integration

**Goal:** Build, train, and track the predictive model.

### Chunk 4.1: Feature Engineering

- [ ] Add `scikit-learn`, `xgboost`, and `mlflow` to `pyproject.toml`.
- [ ] Create the feature engineering script (`ml/feature_engineering.py`).
- [ ] Implement logic to read from the `historical_traffic_data` table.
- [ ] Implement functions to create features (rolling means, time-based flags).
- [ ] Write the final features to a `feature_store` table in PostgreSQL.

### Chunk 4.2: Model Training & Tracking

- [ ] Create the model training script (`ml/train_model.py`).
- [ ] Implement logic to read from the `feature_store` table.
- [ ] Set up an MLflow experiment block (`with mlflow.start_run():`).
- [ ] Log model parameters (hyperparameters) and evaluation metrics (RMSE, R²).
- [ ] Train an `XGBoostRegressor` model.
- [ ] Log the trained model to MLflow as a scikit-learn artifact.

### Chunk 4.3: Automating Retraining with Airflow

- [ ] Create a weekly model retraining DAG (`airflow/dags/model_retraining_dag.py`).
- [ ] Add a task to run the feature engineering script.
- [ ] Add a downstream task to run the model training script.
- [ ] Add a final task to use the MLflow API to register the newly trained model in the Model Registry.

---

## Phase 5: Serving & Visualization

**Goal:** Make the system's intelligence accessible to end-users.

### Chunk 5.1: Prediction API

- [ ] Add `fastapi` and `uvicorn` to `pyproject.toml`.
- [ ] Create the FastAPI application (`ml/predict_service/main.py`).
- [ ] Implement the `/health` endpoint.
- [ ] Create a model loading utility (`ml/predict_service/model_loader.py`) that loads the "Production" model from MLflow on startup.
- [ ] Implement the `/predict` endpoint with Pydantic schemas for request/response validation.
- [ ] Add a `make api` command to the Makefile.

### Chunk 5.2: Interactive Dashboard

- [ ] Add `streamlit` and `plotly` to `pyproject.toml`.
- [ ] Create the Streamlit dashboard script (`visualization/dashboard.py`).
- [ ] Connect to PostgreSQL to display a live KPI.
- [ ] Add a Plotly chart for historical data trends.
- [ ] Create an interactive form that calls the FastAPI `/predict` endpoint.
- [ ] Display the prediction result to the user.
- [ ] Add a `make dashboard` command to the Makefile.

---

## Phase 6: Testing & CI/CD

**Goal:** Ensure the system is robust, reliable, and maintainable.

### Chunk 6.1: Unit & Integration Testing

- [ ] Add `pytest` and `pytest-cov` to `pyproject.toml`.
- [ ] Write unit tests for utility functions and feature engineering logic (`tests/`).
- [ ] Write unit tests for Pydantic schemas.
- [ ] Write integration tests for the FastAPI endpoints using `TestClient`.
- [ ] Implement the `make test` command to run `pytest --cov`.
- [ ] Ensure test coverage meets or exceeds the 85% goal.

### Chunk 6.2: CI/CD Pipeline

- [ ] Create the GitHub Actions workflow file (`.github/workflows/ci.yml`).
- [ ] Define a job that triggers on `push` and `pull_request`.
- [ ] Add steps for: checkout, setup Python with `uv`, `make sync`, `make qa`, `make test`.
- [ ] (Optional) Add a step to upload code coverage results.

### Chunk 6.3: Documentation & Finalization

- [ ] Update `README.md` with complete setup and usage instructions.
- [ ] Add architecture diagrams and contribution guidelines to the `docs/` folder.
- [ ] Review all error handling strategies from the spec and confirm their implementation.
- [ ] Perform a final end-to-end test of the entire system to validate all acceptance criteria.
