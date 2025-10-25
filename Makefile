PYTHON := uv run python
RUFF := uv run ruff
MYPY := uv run mypy

.DEFAULT_GOAL := help

## Create / sync the environment from pyproject.toml
sync:
	uv sync

## Remove lock and dependencies
clean:
	rm -rf .venv uv.lock __pycache__ */__pycache__ .mypy_cache

## Format code (auto-fix with Ruff)
format:
	$(RUFF) check . --fix
	$(RUFF) format .

## Check linting only (no modifications)
lint:
	$(RUFF) check .

## Static type checking
typecheck:
	$(MYPY) src tests

## Run all quality checks (format, lint, typing)
qa: format lint typecheck

## Run Streamlit dashboard
dashboard:
	uv run streamlit run visualization/dashboard.py

## Run FastAPI server (dev mode)
api:
	uv run fastapi dev ml/predict_service/main.py --host 0.0.0.0 --port 8080

