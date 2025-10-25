# Real-Time Traffic Intelligence

A complete **data engineering + machine learning platform** that continuously ingests traffic data (batch + streaming), predicts congestion, and provides a live analytics dashboard — built with modern open-source tools.

---

## Tech Stack

| Domain                    | Tools                                                        |
| ------------------------- | ------------------------------------------------------------ |
| **Language & Env**        | Python 3.11 (managed via [`uv`](https://docs.astral.sh/uv/)) |
| **Streaming**             | Apache Kafka, Spark Structured Streaming                     |
| **Batch / Orchestration** | Apache Airflow                                               |
| **Storage**               | PostgreSQL, S3 (data lake)                                   |
| **ML**                    | scikit-learn, XGBoost, MLflow                                |
| **Serving / API**         | FastAPI                                                      |
| **Visualization**         | Streamlit                                                    |
| **Infra / DevOps**        | Docker Compose, Ruff, Mypy, pytest, Makefile                 |

---

## Quick Setup Guide

### Install `uv`

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
uv --version
```

---

### Clone & Setup Environment

```bash
git clone https://github.com/CHAKHVA/real-time-traffic-intelligence.git
cd real-time-traffic-intelligence

# Pin compatible Python version (3.11)
uv python install 3.11
uv python pin 3.11

# Sync all dependencies
make sync
```

---

### Configure Environment Variables

Duplicate `.env.example` → `.env`, then adjust credentials as needed:

```bash
cp .env.example .env
```

---

### Start Local Infrastructure

Spin up Kafka, PostgreSQL, and MLflow:

```bash
docker compose up -d
```

---

### Run Core Services

| Service                | Command                                             |
| ---------------------- | --------------------------------------------------- |
| FastAPI API            | `make api`                                          |
| Streamlit Dashboard    | `make dashboard`                                    |
| Kafka Stream Producer  | `uv run python kafka_producer/simulate_stream.py`   |
| Spark Stream Processor | `uv run python spark_streaming/stream_processor.py` |

Visit:

- **MLflow UI** → [http://localhost:5000](http://localhost:5000)
- **FastAPI Docs** → [http://localhost:8080/docs](http://localhost:8080)
- **Streamlit Dashboard** → [http://localhost:8501](http://localhost:8501)

---

## Development Workflow

All key operations are defined in the **Makefile**:

| Command          | Description                         |
| ---------------- | ----------------------------------- |
| `make sync`      | Sync dependencies (using `uv`)      |
| `make qa`        | Run format + lint + type-check      |
| `make format`    | Auto-fix style (Ruff)               |
| `make lint`      | Lint (no modifications)             |
| `make typecheck` | Run Mypy static checks              |
| `make test`      | Run full pytest suite + coverage    |
| `make clean`     | Remove cache, lock, and build files |

---

## Testing

Run all tests (with coverage):

```bash
make test
```

Test stack (installed via `uv --dev`):

- `pytest`
- `pytest-asyncio`
- `pytest-cov`
- `pytest-mock`
- `pytest-xdist`

Example test (`tests/test_api_routes.py`):

```python
def test_healthcheck(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

---

## Code Quality

- **Formatting, Linting, Imports** → `Ruff`
- **Static Typing** → `Mypy`
- **Test Coverage** → `pytest-cov`
- **Automation** → `Makefile` targets

---
