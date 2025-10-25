.PHONY: help sync install format lint typecheck test test-cov check ci clean run-api run-streamlit

PYTHON := uv run python
RUFF := uv run ruff
MYPY := uv run mypy
PYTEST := uv run pytest

## Default target: show help
help:
	@echo "Available targets:"
	@echo "  sync          - Create/sync the environment from pyproject.toml"
	@echo "  install       - Alias for sync"
	@echo "  format        - Format code (auto-fix with Ruff)"
	@echo "  lint          - Check linting only (no modifications)"
	@echo "  typecheck     - Run static type checking with mypy"
	@echo "  test          - Run tests with pytest"
	@echo "  test-cov      - Run tests with coverage report"
	@echo "  check         - Run all checks (lint, typecheck, test)"
	@echo "  ci            - Run all CI checks (same as check)"
	@echo "  clean         - Remove Python cache files and build artifacts"
	@echo "  run-api       - Run FastAPI application"
	@echo "  run-streamlit - Run Streamlit dashboard"

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
	$(PYTHON) -m uvicorn app.main:app --reload

## Run Streamlit dashboard
run-streamlit:
	uv run streamlit run app/dashboard.py
