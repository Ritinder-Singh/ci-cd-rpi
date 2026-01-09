# Backend Tests

This directory contains the testing framework for the CI/CD backend.

## Quick Start

```bash
# Install dependencies
pip install -r ../requirements.txt

# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html
```

## Structure

```
tests/
├── README.md           # This file
├── __init__.py         # Package marker
├── conftest.py         # Shared fixtures (DB, HTTP client)
├── test_example.py     # Example tests (reference)
└── test_api.py         # Basic API tests
```

## Adding New Tests

1. Create file: `test_<feature>.py`
2. Import fixtures: `from httpx import AsyncClient`
3. Write test:
   ```python
   @pytest.mark.asyncio
   async def test_my_feature(client: AsyncClient):
       response = await client.get("/api/endpoint")
       assert response.status_code == 200
   ```

## Documentation

See **[TESTING_GUIDE.md](../TESTING_GUIDE.md)** for complete documentation including:
- Detailed examples
- Best practices
- Advanced patterns
- CI/CD integration
- Troubleshooting

## Test Fixtures Available

From `conftest.py`:

- `client` - HTTP client for API testing
- `db_session` - Database session (creates/drops tables per test)
- `event_loop` - Async event loop

## Configuration

- **pytest.ini** - Pytest and coverage settings
- **conftest.py** - Shared fixtures and setup
- Test database: `postgresql://cicd_user@localhost:5433/cicd_staging`

## Coverage Goals

- Minimum: 70% (configured in pytest.ini)
- Target: 80%+
- Critical paths: 100%

Run `pytest --cov=app --cov-report=html` and open `htmlcov/index.html` to see detailed coverage.
