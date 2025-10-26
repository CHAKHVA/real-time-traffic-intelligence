# Contributing

## Getting Started

### Prerequisites

- Python 3.11
- Docker & Docker Compose
- uv package manager

### Setup

```bash
# Clone the repo
git clone https://github.com/CHAKHVA/real-time-traffic-intelligence.git
cd real-time-traffic-intelligence

# Install dependencies
make sync

# Copy environment file
cp .env.example .env

# Start services
docker compose up -d
```

## Development Workflow

1. **Create a branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes**

3. **Run checks before committing**

   ```bash
   make format  # Format code
   make check   # Run lint, typecheck, tests
   ```

4. **Commit and push**

   ```bash
   git add .
   git commit -m "feat: your change description"
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request**

## Code Style

- Follow PEP 8
- Use type hints
- Add docstrings to public functions
- Run `make format` before committing

## Testing

- Add tests for new features
- Minimum 85% coverage
- Run tests with `make test`

## Pull Request Guidelines

- Keep PRs focused and small
- Write clear commit messages
- Ensure CI passes
- Get at least one review approval

## Need Help?

Open an issue with the `question` label.
