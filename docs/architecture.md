# System Architecture — Real-Time Traffic Intelligence Hub

## 1. Overview

The platform processes city traffic data in both **real-time** and **batch** modes to generate congestion predictions and visual insights.

---

## 2. High-Level Components

| Component                     | Description                                                         |
| ----------------------------- | ------------------------------------------------------------------- |
| **Kafka Producer**            | Simulates incoming IoT traffic events (speed, location, timestamp). |
| **Spark Streaming Processor** | Cleans, validates, and aggregates streaming data.                   |
| **Data Lake / Warehouse**     | Stores historical data for reprocessing and model training.         |
| **Airflow DAGs**              | Schedules ETL pipelines, feature creation, and model retraining.    |
| **ML Pipeline**               | Trains and tracks models using MLflow; supports auto‑retrains.      |
| **FastAPI Service**           | Serves real-time predictions through REST endpoints.                |
| **Streamlit Dashboard**       | Displays live metrics, congestion forecasts, and anomalies.         |

---

## 3. Data Flow Diagram

```text
[Kafka Producer] → [Spark Stream Processor] → [Cassandra/S3] → [Airflow Batch Feature Builder]
       → [MLflow Model Registry] → [FastAPI Prediction API] → [Streamlit Dashboard]
```

---

## 4. Technologies & Tools

- **Processing:** Apache Spark Structured Streaming
- **Scheduling:** Apache Airflow
- **ML & Tracking:** scikit-learn, MLflow
- **Serving:** FastAPI
- **Visualization:** Streamlit
- **Infrastructure:** Docker Compose, uv, Makefile
