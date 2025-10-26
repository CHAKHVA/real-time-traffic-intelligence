.PHONY: help sync install format lint typecheck test test-cov check ci clean run-api run-streamlit run-producer docker-up docker-down docker-logs docker-clean kafka-topics mlflow-ui kafka-ui db-connect dev stop-all

PYTHON := uv run python
RUFF := uv run ruff
MYPY := uv run mypy
PYTEST := uv run pytest

## Default target: show help
help:
	@echo "Available make targets:"
	@echo ""
	@echo "Quick Start:"
	@echo "  dev           - Start ALL services (infrastructure + apps + UIs)"
	@echo "  stop-all      - Stop all running services"
	@echo ""
	@echo "Environment Setup:"
	@echo "  sync          - Create/sync the environment from pyproject.toml"
	@echo "  install       - Alias for sync"
	@echo "  clean         - Remove Python cache files and build artifacts"
	@echo ""
	@echo "Code Quality:"
	@echo "  format        - Format code (auto-fix with Ruff)"
	@echo "  lint          - Check linting only (no modifications)"
	@echo "  typecheck     - Run static type checking with mypy"
	@echo "  check         - Run all checks (lint, typecheck, test)"
	@echo "  ci            - Run all CI checks (same as check)"
	@echo ""
	@echo "Testing:"
	@echo "  test          - Run tests with pytest"
	@echo "  test-cov      - Run tests with coverage report"
	@echo ""
	@echo "Application Services:"
	@echo "  run-api       - Run FastAPI application"
	@echo "  run-streamlit - Run Streamlit dashboard"
	@echo "  run-producer  - Run Kafka producer"
	@echo ""
	@echo "Infrastructure:"
	@echo "  docker-up     - Start all Docker services"
	@echo "  docker-down   - Stop all Docker services"
	@echo "  docker-logs   - View logs from all services"
	@echo "  docker-clean  - Stop services and remove volumes"
	@echo ""
	@echo "Utilities:"
	@echo "  kafka-topics  - List all Kafka topics"
	@echo "  kafka-ui      - Open Kafka UI in browser"
	@echo "  mlflow-ui     - Open MLflow UI in browser"
	@echo "  db-connect    - Connect to PostgreSQL database"

## Create / sync the environment from pyproject.toml
sync:
	uv sync

## Alias for sync
install: sync

## Format code (auto-fix with Ruff)
format:
	$(RUFF) check . --fix
	$(RUFF) format .

## Check linting only (no modifications)
lint:
	$(RUFF) check .

## Static type checking
typecheck:
	$(MYPY) .

## Run tests
test:
	$(PYTEST)

## Run tests with coverage
test-cov:
	$(PYTEST) --cov=. --cov-report=html --cov-report=term

## Run all checks (lint, typecheck, test)
check: lint typecheck test

## CI target (alias for check)
ci: check

## Clean Python cache and build artifacts
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "htmlcov" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name ".coverage" -delete 2>/dev/null || true

## Run FastAPI application
run-api:
	$(PYTHON) -m uvicorn api.main:app --reload

## Run Streamlit dashboard
run-streamlit:
	uv run streamlit run dashboard/app.py

## Run Kafka producer
run-producer:
	$(PYTHON) -m src.ingestion.kafka_producer

## Start all Docker services
docker-up:
	docker compose up -d

## Stop all Docker services
docker-down:
	docker compose down

## View logs from all services
docker-logs:
	docker compose logs -f

## Stop services and remove volumes (clean slate)
docker-clean:
	docker compose down -v

## List all Kafka topics
kafka-topics:
	docker compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list

## Open Kafka UI in browser
kafka-ui:
	@echo "Opening Kafka UI at http://localhost:8080"
	@open http://localhost:8080 2>/dev/null || xdg-open http://localhost:8080 2>/dev/null || echo "Please open http://localhost:8080 in your browser"

## Open MLflow UI in browser
mlflow-ui:
	@echo "Opening MLflow UI at http://localhost:5000"
	@open http://localhost:5000 2>/dev/null || xdg-open http://localhost:5000 2>/dev/null || echo "Please open http://localhost:5000 in your browser"

## Connect to PostgreSQL database
db-connect:
	docker compose exec postgres psql -U traffic_user -d traffic_db

## Start ALL services (infrastructure + apps + open UIs)
dev:
	@echo "🚀 Starting all infrastructure services..."
	docker compose up -d
	@echo ""
	@echo "⏳ Waiting for services to be healthy..."
	@sleep 5
	@echo ""
	@echo "✅ Infrastructure ready!"
	@echo ""
	@echo "📊 Opening UIs..."
	@open http://localhost:8080 2>/dev/null || xdg-open http://localhost:8080 2>/dev/null || true
	@open http://localhost:5000 2>/dev/null || xdg-open http://localhost:5000 2>/dev/null || true
	@echo ""
	@echo "🎯 Service URLs:"
	@echo "   - Kafka UI:  http://localhost:8080"
	@echo "   - MLflow UI: http://localhost:5000"
	@echo "   - API:       http://localhost:8000 (run 'make run-api' in another terminal)"
	@echo "   - Dashboard: http://localhost:8501 (run 'make run-streamlit' in another terminal)"
	@echo ""
	@echo "📝 Next steps:"
	@echo "   1. Run 'make run-producer' in a new terminal to start data ingestion"
	@echo "   2. Run 'make run-api' in a new terminal to start the API"
	@echo "   3. Run 'make run-streamlit' in a new terminal to start the dashboard"
	@echo ""
	@echo "💡 View logs with 'make docker-logs'"
	@echo "🛑 Stop everything with 'make stop-all'"

## Stop all services (Docker + kill any running Python processes)
stop-all:
	@echo "🛑 Stopping all Docker services..."
	docker compose down
	@echo "✅ All services stopped!"
