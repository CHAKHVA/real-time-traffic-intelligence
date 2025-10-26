# Real-Time Traffic Intelligence

A data engineering and machine learning platform for real-time traffic monitoring. Ingests traffic data through streaming and batch pipelines, predicts congestion using ML models, and provides live analytics through an interactive dashboard.

## Features

- **Real-time data ingestion** with Apache Kafka
- **Batch processing** with Apache Spark and Apache Airflow
- **ML-powered predictions** using scikit-learn and XGBoost
- **RESTful API** with FastAPI
- **Interactive dashboard** built with Streamlit
- **Experiment tracking** with MLflow

## Tech Stack

- **Language:** Python 3.11
- **Streaming:** Apache Kafka, Spark Structured Streaming
- **Batch Processing:** Apache Spark and Apache Airflow
- **Database:** PostgreSQL
- **ML/MLOps:** scikit-learn, XGBoost, MLflow
- **API:** FastAPI
- **Visualization:** Streamlit
- **Infrastructure:** Docker Compose

## Installation

### Prerequisites

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) package manager
- Docker and Docker Compose

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/CHAKHVA/real-time-traffic-intelligence.git
cd real-time-traffic-intelligence
```

2. **Install uv (if not already installed)**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

3. **Setup Python environment**

```bash
uv python install 3.11
uv python pin 3.11
make sync
```

4. **Configure environment variables**

```bash
cp .env.example .env
# Edit .env with your configuration
```

## Usage

### Quick Start

Start all services with one command:

```bash
make dev
```

This starts the infrastructure and opens Kafka UI and MLflow UI in your browser.

### Run Application Services

In separate terminals, run:

```bash
make run-producer     # Start data ingestion
make run-api          # Start prediction API
make run-streamlit    # Start dashboard
```

### Access Services

- **Kafka UI:** <http://localhost:8080>
- **MLflow UI:** <http://localhost:5001>
- **FastAPI Docs:** <http://localhost:8000/docs>
- **Streamlit Dashboard:** <http://localhost:8501>

### Stop Services

```bash
make stop-all
```

## Development

### Common Commands

```bash
make sync          # Install/sync dependencies
make check         # Run linting, type checking, and tests
make format        # Auto-format code
make test          # Run tests
make test-cov      # Run tests with coverage
```

### Project Structure

```
real-time-traffic-intelligence/
├── src/              # Core application code
├── api/              # FastAPI prediction service
├── dashboard/        # Streamlit visualization
├── airflow/          # Batch processing DAGs
├── tests/            # Tests
├── data/             # Local data storage
├── docs/             # Documentation
└── scripts/          # Utility scripts
```

## Documentation

- [Engineering Specification](docs/spec.md) - System architecture and design
- [Project Checklist](docs/todo.md) - Task breakdown

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
