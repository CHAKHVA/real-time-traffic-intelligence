# Contributing Guide

## 1. Environment Setup

Ensure you have `uv` installed and sync the project:

```bash
uv python install 3.11
uv python pin 3.11
make sync
```

---

## 2. Branching Strategy

- `main` → stable, production-ready
- `feature/<name>` → new features
- `fix/<name>` → bug fixes

---

## 3. Code Quality Before Commit

Always run:

```bash
make qa
make test
```

Ensure:

- No lint errors (Ruff)
- 100% type checking passed (Mypy)
- All tests green (pytest)

---

## 4. Commit Convention

Use short imperative messages:

```
feat(stream): add Spark structured streaming job
fix(api): correct missing return in healthcheck
chore(docs): update README and contributing guide
```

---

## 5. Code Reviews

- Review each other's PRs (no self-merges)
- Ensure CI passes (`make qa`, `make test`)

---

## 6. Adding New Dependencies

Use `uv` inside Makefile workflow:

```bash
uv add <package>
uv sync
```

Then commit updated `pyproject.toml` and `uv.lock`.

---

## 7. Adding Tests

Test guidelines:

- Unit tests under `/tests/`
- Async endpoints tested with `pytest-asyncio`
- Coverage goal: ≥ 85%

---

## 8. Documentation

- Update `/docs/architecture.md` when altering key components
- Update `README.md` setup instructions if dependencies change
