# 🛣️ Real-Time Traffic Intelligence Hub

A data engineering and machine learning platform that ingests streaming and batch traffic data, predicts congestion, and visualizes live road analytics.

---

## 🚀 Quick Start — Environment Setup (using `uv`)

This project uses [`uv`](https://docs.astral.sh/uv/) for Python environment + dependency management.

### 1️⃣ Install uv
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

After installing, check:
```bash
uv --version
```

---

### 2️⃣ Clone the Repository
```bash
git clone https://github.com/<your-org>/traffic-intelligence-hub.git
cd traffic-intelligence-hub
```

---

### 3️⃣ Set Up Python & Environment
Target version: **Python 3.11** (stable for ML + Airflow + PySpark)

```bash
uv python install 3.11
uv python pin 3.11
```

---

### 4️⃣ Sync Dependencies
All dependencies are defined in `pyproject.toml` and locked via `uv.lock`.

```bash
uv sync
```

This creates a reproducible virtual environment inside `.venv/`.

You can now run commands with:
```bash
uv run python
```

or activate interactively:
```bash
eval $(uv activate)
```

---

### 5️⃣ Verify Setup
Run a quick import check:
```bash
uv run python -c "import pandas, pyspark, mlflow, fastapi, streamlit; print('✅ Environment ready!')"
```

---

## 🧩 Standard Workflow

| Task | Command | Description |
|------|----------|-------------|
| Install new library | `uv add <package>` | Adds and locks dependency |
| Add dev-only package | `uv add --dev <package>` | Linters, test libs |
| Start API locally | `uv run fastapi dev` | Serve FastAPI endpoints |
| Run Streamlit dashboard | `uv run streamlit run visualization/dashboard.py` | Visualization UI |
| Run tests | `uv run pytest -v` | Unit/integration tests |
| Format code | `uv run black .` | Ensure consistent styling |

---

## 🗂️ Included Components
- **Kafka Producer** → generates synthetic traffic data streams  
- **Spark Streaming Job** → real-time ingestion + processing  
- **Airflow DAGs** → batch ingestion & feature builds  
- **ML / FastAPI Service** → model inference + REST endpoints  
- **Streamlit Dashboard** → live traffic visualization  

---

## 🔧 Troubleshooting

| Issue | Possible Fix |
|--------|----------------|
| Missing wheel or compile fail | Ensure Python 3.11, rerun `uv sync` |
| Network errors during install | Try `uv sync --refresh` |
| Wrong Python in shell | `uv python pin 3.11` and restart terminal |

---

## 👥 Collaboration Notes
- Use feature branches: `feat/<name>` or `fix/<name>`  
- Always run tests + `black .` before committing  
- Never commit `.venv` or `.env` files.  
- Update `README.md` if dependencies or key commands change.  

---

## 📜 License
MIT — use, modify, and share responsibly.

---

**Maintainers:**  
👨💻 Alex — Data Infrastructure + APIs  
🤖 [Your Teammate] — ML Models + Dashboards# 🛣️ Real-Time Traffic Intelligence Hub

A data engineering and machine learning platform that ingests streaming and batch traffic data, predicts congestion, and visualizes live road analytics.

---

## 🚀 Quick Start — Environment Setup (using `uv`)

This project uses [`uv`](https://docs.astral.sh/uv/) for Python environment + dependency management.

### 1️⃣ Install uv
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

After installing, check:
```bash
uv --version
```

---

### 2️⃣ Clone the Repository
```bash
git clone https://github.com/<your-org>/traffic-intelligence-hub.git
cd traffic-intelligence-hub
```

---

### 3️⃣ Set Up Python & Environment
Target version: **Python 3.11** (stable for ML + Airflow + PySpark)

```bash
uv python install 3.11
uv python pin 3.11
```

---

### 4️⃣ Sync Dependencies
All dependencies are defined in `pyproject.toml` and locked via `uv.lock`.

```bash
uv sync
```

This creates a reproducible virtual environment inside `.venv/`.

You can now run commands with:
```bash
uv run python
```

or activate interactively:
```bash
eval $(uv activate)
```

---

### 5️⃣ Verify Setup
Run a quick import check:
```bash
uv run python -c "import pandas, pyspark, mlflow, fastapi, streamlit; print('✅ Environment ready!')"
```

---

## 🧩 Standard Workflow

| Task | Command | Description |
|------|----------|-------------|
| Install new library | `uv add <package>` | Adds and locks dependency |
| Add dev-only package | `uv add --dev <package>` | Linters, test libs |
| Start API locally | `uv run fastapi dev` | Serve FastAPI endpoints |
| Run Streamlit dashboard | `uv run streamlit run visualization/dashboard.py` | Visualization UI |
| Run tests | `uv run pytest -v` | Unit/integration tests |
| Format code | `uv run black .` | Ensure consistent styling |

---

## 🗂️ Included Components
- **Kafka Producer** → generates synthetic traffic data streams  
- **Spark Streaming Job** → real-time ingestion + processing  
- **Airflow DAGs** → batch ingestion & feature builds  
- **ML / FastAPI Service** → model inference + REST endpoints  
- **Streamlit Dashboard** → live traffic visualization  

---

## 🔧 Troubleshooting

| Issue | Possible Fix |
|--------|----------------|
| Missing wheel or compile fail | Ensure Python 3.11, rerun `uv sync` |
| Network errors during install | Try `uv sync --refresh` |
| Wrong Python in shell | `uv python pin 3.11` and restart terminal |

---

## 👥 Collaboration Notes
- Use feature branches: `feat/<name>` or `fix/<name>`  
- Always run tests + `black .` before committing  
- Never commit `.venv` or `.env` files.  
- Update `README.md` if dependencies or key commands change.  

---

## 📜 License
MIT — use, modify, and share responsibly.

---

**Maintainers:**  
👨💻 Alex — Data Infrastructure + APIs  
🤖 [Your Teammate] — ML Models + Dashboards