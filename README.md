# Real-Time Traffic Intelligence

A complete **data engineering + machine learning platform** that continuously ingests traffic data (batch + streaming), predicts congestion, and provides a live analytics dashboard — built with modern open-source tools.

---

## Tech Stack

| Domain                    | Tools                                                        |
| ------------------------- | ------------------------------------------------------------ |
| **Language & Env**        | Python 3.11 (managed via [`uv`](https://docs.astral.sh/uv/)) |
| **Streaming**             | Apache Kafka, Spark Structured Streaming                     |
| **Batch / Orchestration** | Apache Airflow                                               |
| **Storage**               | PostgreSQL                                                   |
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

### Quick Start (One Command!)

Start all infrastructure services and open UIs:

```bash
make dev
```

This will:

- Start PostgreSQL, Kafka, Zookeeper, MLflow, Kafka UI
- Open Kafka UI and MLflow UI in your browser
- Show you next steps to run application services

Then in separate terminals:

```bash
make run-producer     # Terminal 2: Start data ingestion
make run-api          # Terminal 3: Start prediction API
make run-streamlit    # Terminal 4: Start dashboard
```

**Service URLs:**

- **Kafka UI** → [http://localhost:8080](http://localhost:8080)
- **MLflow UI** → [http://localhost:5001](http://localhost:5001)
- **FastAPI Docs** → [http://localhost:8000/docs](http://localhost:8000/docs)
- **Streamlit Dashboard** → [http://localhost:8501](http://localhost:8501)

---

### Alternative: Manual Setup

If you prefer step-by-step:

```bash
# 1. Start infrastructure
make docker-up

# 2. Run application services (in separate terminals)
make run-producer
make run-api
make run-streamlit

# 3. View logs
make docker-logs

# 4. Stop everything
make docker-down
```

---

## Development Workflow

All key operations are defined in the **Makefile**:

### Quick Start Commands

| Command         | Description                                  |
| --------------- | -------------------------------------------- |
| `make dev`      | Start all services + open UIs (one command!) |
| `make stop-all` | Stop all running services                    |

### Application Services

| Command              | Description                           |
| -------------------- | ------------------------------------- |
| `make run-api`       | Start FastAPI prediction service      |
| `make run-streamlit` | Start Streamlit dashboard             |
| `make run-producer`  | Start Kafka producer (data ingestion) |

### Infrastructure

| Command             | Description                      |
| ------------------- | -------------------------------- |
| `make docker-up`    | Start all Docker services        |
| `make docker-down`  | Stop all Docker services         |
| `make docker-logs`  | View logs from all services      |
| `make docker-clean` | Stop services and remove volumes |

### Code Quality

| Command          | Description                              |
| ---------------- | ---------------------------------------- |
| `make sync`      | Sync dependencies (using `uv`)           |
| `make check`     | Run all checks (lint + typecheck + test) |
| `make format`    | Auto-fix style (Ruff)                    |
| `make lint`      | Lint (no modifications)                  |
| `make typecheck` | Run Mypy static checks                   |
| `make test`      | Run full pytest suite                    |
| `make test-cov`  | Run tests with coverage report           |
| `make clean`     | Remove cache, lock, and build files      |

### Utilities

| Command             | Description                    |
| ------------------- | ------------------------------ |
| `make kafka-topics` | List all Kafka topics          |
| `make kafka-ui`     | Open Kafka UI in browser       |
| `make mlflow-ui`    | Open MLflow UI in browser      |
| `make db-connect`   | Connect to PostgreSQL database |

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

---

## Code Quality

- **Formatting, Linting, Imports** → `Ruff`
- **Static Typing** → `Mypy`
- **Test Coverage** → `pytest-cov`
- **Automation** → `Makefile` targets

---

## Architecture

For detailed architecture, data flow, and deployment strategy, see:

- **[Engineering Specification](docs/spec.md)** - Complete system architecture and design decisions
- **[Implementation Plan](docs/plan.md)** - Step-by-step development guide
- **[Project Checklist](docs/todo.md)** - Task breakdown and progress tracking

### Project Structure

```
real-time-traffic-intelligence/
├── src/              # Core application code (ingestion, processing, ML)
├── api/              # FastAPI prediction service
├── dashboard/        # Streamlit visualization
├── airflow/          # Batch processing DAGs
├── tests/            # Unit and integration tests
├── data/             # Local data storage
├── docs/             # Documentation
└── scripts/          # Utility scripts
```
