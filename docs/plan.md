## Phase 1: Foundational Setup & Environment

The goal of this phase is to establish a stable, reproducible development environment. This is the bedrock upon which all other components will be built.

### Chunk 1.1: Project Scaffolding & Version Control

- **Step 1.1.1:** Initialize a new Git repository.
- **Step 1.1.2:** Create the top-level directory structure as defined in the specification (`airflow/`, `kafka_producer/`, `ml/`, `src/utils`, `tests/`, etc.).
- **Step 1.1.3:** Create placeholder `.gitkeep` files in empty directories to ensure they are tracked by Git.
- **Step 1.1.4:** Create the `pyproject.toml` file and initialize it with `uv`. Define basic project metadata (name, version, authors).
- **Step 1.1.5:** Create an initial `README.md` and a `.gitignore` file for Python projects.

### Chunk 1.2: Core Services Orchestration

- **Step 1.2.1:** Create the `docker-compose.yml` file.
- **Step 1.2.2:** Add base services: a PostgreSQL database with a defined user, password, and initial database.
- **Step 1.2.3:** Add Zookeeper and Kafka services to the `docker-compose.yml` file, ensuring they are on the same Docker network.
- **Step 1.2.4:** Add an MLflow tracking server service, configured to use the PostgreSQL instance as its backend store and a local volume for artifacts.
- **Step 1.2.5:** Verify that `docker compose up -d` successfully starts all services without errors.

### Chunk 1.3: Automation & Dependency Management

- **Step 1.3.1:** Create the `Makefile`.
- **Step 1.3.2:** Define initial dependencies in `pyproject.toml`: `pydantic` for schema validation and `ruff`, `mypy` for quality assurance.
- **Step 1.3.3:** Implement the `make sync` command in the Makefile to install/update dependencies using `uv sync`.
- **Step 1.3.4:** Implement the `make qa` command to run `ruff check` and `mypy .`.
- **Step 1.3.5:** Add basic Docker Compose commands to the Makefile: `make up` (`docker compose up -d`), `make down` (`docker compose down`), and `make logs`.

### Chunk 1.4: Base Utilities & Configuration

- **Step 1.4.1:** Create a configuration management file (`src/utils/config.py`) to load settings (e.g., Kafka broker URL, PostgreSQL connection string) from environment variables.
- **Step 1.4.2:** Implement a standardized logging utility (`src/utils/logging_utils.py`) that provides a pre-configured logger for consistent, structured logging across the project.
- **Step 1.4.3:** Define the core data schema (`src/schemas/traffic_event.py`) using Pydantic to ensure data integrity from the very beginning.

---

## Phase 2: Data Ingestion & Storage

With the environment set up, the next step is to get data flowing into the system and stored correctly.

### Chunk 2.1: Real-Time Data Producer

- **Step 2.1.1:** Add the `kafka-python` library to `pyproject.toml` and run `make sync`.
- **Step 2.1.2:** Create the producer script (`kafka_producer/producer.py`).
- **Step 2.1.3:** In the script, implement a function to connect to the Kafka broker using settings from the config utility.
- **Step 2.1.4:** Write a function that generates a single, random-but-valid traffic event using the Pydantic schema.
- **Step 2.1.5:** Create a main loop that generates and sends these events to the `traffic_raw` Kafka topic as JSON bytes.
- **Step 2.1.6:** Add a `make producer` command to the Makefile to run this script.

### Chunk 2.2: Initial Database Setup

- **Step 2.2.1:** Add `psycopg2-binary` and `sqlalchemy` to `pyproject.toml` and run `make sync`.
- **Step 2.2.2:** Create a simple script (`src/utils/init_db.py`) that uses SQLAlchemy to connect to the PostgreSQL container.
- **Step 2.2.3:** Define the table schema for `processed_traffic_data` in the script, matching the cleaned data structure.
- **Step 2.2.4:** Add a `make init-db` command to the Makefile that runs this script to create the table.

### Chunk 2.3: Simple Stream Processor

- **Step 2.3.1:** Add `pyspark` to `pyproject.toml` and run `make sync`.
- **Step 2.3.2:** Create the Spark streaming script (`spark_streaming/stream_processor.py`).
- **Step 2.3.3:** Implement a utility (`src/utils/spark_session.py`) to create a configured SparkSession that can connect to Kafka.
- **Step 2.3.4:** In the processor script, read from the `traffic_raw` Kafka topic.
- **Step 2.3.5:** Perform a basic transformation: parse the JSON, select the fields, and print the resulting DataFrame to the console using a `writeStream` with a `console` sink.
- **Step 2.3.6:** Add a `make stream` command to the Makefile to run the Spark job via `spark-submit`.

---

## Phase 3: End-to-End Data Flow

This phase connects the components built in Phase 2 to create a complete, albeit simple, streaming pipeline.

### Chunk 3.1: Persisting Streamed Data

- **Step 3.1.1:** Modify the Spark streaming job (`spark_streaming/stream_processor.py`).
- **Step 3.1.2:** Instead of writing to the console, change the `writeStream` sink to write to the PostgreSQL table created in Chunk 2.2. This will require the PostgreSQL JDBC driver.
- **Step 3.1.3:** Add schema validation and basic data cleaning (e.g., dropping rows with null `road_id` or `timestamp`).
- **Step 3.1.4:** Implement a simple 5-minute tumbling window aggregation to calculate `avg_speed` and `vehicle_count`.
- **Step 3.1.5:** Run the full flow: `make up`, `make init-db`, `make producer`, `make stream`. Connect to the PostgreSQL database and verify that aggregated data is being written correctly.

### Chunk 3.2: Batch Ingestion with Airflow

- **Step 3.2.1:** Add `apache-airflow` and related providers to `pyproject.toml`.
- **Step 3.2.2:** Add an Airflow service to `docker-compose.yml`, configuring it to use the existing PostgreSQL instance as its backend.
- **Step 3.2.3:** Create a simple "Hello World" DAG in the `airflow/dags/` directory to verify the Airflow instance is working.
- **Step 3.2.4:** Create a new DAG (`airflow/dags/batch_ingestion_dag.py`) scheduled to run daily.
- **Step 3.2.5:** The first task in the DAG will be a `PythonOperator` that simulates downloading historical data (e.g., reads a local CSV file from the `data/` directory).
- **Step 3.2.6:** The second task will cleanse the data (similar to the Spark job's logic) and append it to a new table in PostgreSQL called `historical_traffic_data`.

### Chunk 3.3: Dead-Letter Queue (DLQ) for Error Handling

- **Step 3.3.1:** In the Spark streaming job, implement a `try-except` block around the schema parsing.
- **Step 3.3.2:** If parsing fails, instead of dropping the data, write the malformed event to a separate Kafka topic named `traffic_dlq`.
- **Step 3.3.3:** Modify the Kafka producer to occasionally send a malformed JSON message.
- **Step 3.3.4:** Run the stream and producer, and use a Kafka command-line tool to verify that bad messages land in the `traffic_dlq` topic while good messages continue to be processed.

---

## Phase 4: Machine Learning Integration

With data flowing and stored, this phase focuses on building and tracking the predictive model.

### Chunk 4.1: Feature Engineering

- **Step 4.1.1:** Add `scikit-learn`, `xgboost`, and `mlflow` to `pyproject.toml`.
- **Step 4.1.2:** Create a script `ml/feature_engineering.py`.
- **Step 4.1.3:** This script should read from the `historical_traffic_data` table.
- **Step 4.1.4:** Implement functions to create features: rolling averages for `vehicle_count`, `day_of_week`, `hour_of_day`, and a `is_rush_hour` flag.
- **Step 4.1.5:** Write the resulting feature-rich DataFrame to a new `feature_store` table in PostgreSQL.

### Chunk 4.2: Model Training & Tracking

- **Step 4.2.1:** Create the training script `ml/train_model.py`.
- **Step 4.2.2:** The script should read data from the `feature_store` table.
- **Step 4.2.3:** Implement an MLflow experiment block (`with mlflow.start_run():`).
- **Step 4.2.4:** Log parameters (e.g., model type, hyperparameters) and metrics (RMSE, R²).
- **Step 4.2.5:** Train an XGBoost Regressor model.
- **Step 4.2.6:** Log the trained model as an artifact using `mlflow.sklearn.log_model`.

### Chunk 4.3: Automating Retraining with Airflow

- **Step 4.3.1:** Create a new DAG (`airflow/dags/model_retraining_dag.py`) scheduled to run weekly.
- **Step 4.3.2:** Add a `PythonOperator` that executes the feature engineering script from Chunk 4.1.
- **Step 4.3.3:** Add a second `PythonOperator` downstream that executes the model training script from Chunk 4.2.
- **Step 4.3.4:** The final task will use the MLflow API to get the latest trained model run and register it in the MLflow Model Registry under the name `traffic_speed_predictor`.

---

## Phase 5: Serving & Visualization

This phase makes the system's intelligence accessible to end-users.

### Chunk 5.1: Prediction API

- **Step 5.1.1:** Add `fastapi` and `uvicorn` to `pyproject.toml`.
- **Step 5.1.2:** Create the FastAPI application in `ml/predict_service/main.py`.
- **Step 5.1.3:** Implement the `/health` endpoint that returns a 200 OK.
- **Step 5.1.4:** Create a `model_loader.py` utility. On startup, it should use the MLflow client to load the latest model version marked as "Production" from the `traffic_speed_predictor` registry entry.
- **Step 5.1.5:** Implement the `/predict` POST endpoint, using Pydantic models for request and response validation. This endpoint will use the loaded model to make predictions.
- **Step 5.1.6:** Add a `make api` command to the Makefile to run the service with Uvicorn.

### Chunk 5.2: Interactive Dashboard

- **Step 5.2.1:** Add `streamlit` and `plotly` to `pyproject.toml`.
- **Step 5.2.2:** Create the dashboard script `visualization/dashboard.py`.
- **Step 5.2.3:** The dashboard should connect to the PostgreSQL `processed_traffic_data` table and display a live KPI like "Average Speed (last 15 mins)".
- **Step 5.2.4:** Add a line chart showing the historical trend of average speed for a selected road.
- **Step 5.2.5:** Create an interactive form where a user can input features (hour, day of week, etc.). On submission, the dashboard will call the FastAPI `/predict` endpoint and display the returned prediction.
- **Step 5.2.6:** Add a `make dashboard` command to the Makefile.

---

## Phase 6: Testing & CI/CD

This final phase ensures the system is robust, reliable, and easy to maintain.

### Chunk 6.1: Unit & Integration Testing

- **Step 6.1.1:** Add `pytest` and `pytest-cov` to `pyproject.toml`.
- **Step 6.1.2:** Write unit tests for the feature engineering functions in `tests/ml/`.
- **Step 6.1.3:** Write unit tests for the Pydantic schemas in `tests/schemas/`.
- **Step 6.1.4:** Using FastAPI's `TestClient`, write integration tests for the `/predict` and `/health` endpoints in `tests/api/`.
- **Step 6.1.5:** Implement the `make test` command to run `pytest --cov` and enforce an 85% coverage goal.

### Chunk 6.2: CI/CD Pipeline

- **Step 6.2.1:** Create the GitHub Actions workflow file `.github/workflows/ci.yml`.
- **Step 6.2.2:** Define a job that triggers on push/pull_request to the main branch.
- **Step 6.2.3:** The job's steps should be: checkout code, set up Python with `uv`, run `make sync`, run `make qa`, and finally run `make test`.
- **Step 6.2.4:** (Optional) Add a step to upload code coverage results to a service like Codecov.

### Chunk 6.3: Documentation & Finalization

- **Step 6.3.1:** Thoroughly update the `README.md` with instructions for local setup, as per the "Local Development Flow" and acceptance criteria.
- **Step 6.3.2:** Add architecture diagrams and contribution guidelines to the `docs/` folder.
- **Step 6.3.3:** Review all error handling strategies defined in the specification and ensure they are implemented (e.g., API returning 503 if the model is not loaded, Airflow retries).
- **Step 6.3.4:** Manually run through the entire end-to-end flow to satisfy all acceptance criteria.
