# Testing Framework Guide

Complete guide to the testing framework for the CI/CD backend.

## Table of Contents
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
- [Writing Tests](#writing-tests)
- [Running Tests](#running-tests)
- [Test Coverage](#test-coverage)
- [Best Practices](#best-practices)
- [Advanced Patterns](#advanced-patterns)

## Directory Structure

```
backend/
├── tests/
│   ├── __init__.py              # Makes tests a Python package
│   ├── conftest.py              # Shared fixtures and configuration
│   ├── test_example.py          # Example tests (reference)
│   ├── test_api.py              # Basic API tests (add more here)
│   └── test_<feature>.py        # Add your feature tests here
├── pytest.ini                   # Pytest configuration
├── requirements.txt             # Includes test dependencies
└── app/                         # Application code to test
```

### Key Files Explained

**conftest.py**
- Contains shared test fixtures
- Provides database session for tests
- Provides HTTP client for API tests
- Pytest automatically discovers this file

**pytest.ini**
- Configures pytest behavior
- Sets coverage thresholds
- Defines test markers
- Configures HTML report generation

**test_*.py**
- Must start with `test_` or end with `_test.py`
- Pytest automatically discovers these files
- Contains actual test functions/classes

## Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

Test dependencies included:
- `pytest` - Testing framework
- `pytest-asyncio` - Async test support
- `pytest-cov` - Coverage reporting
- `pytest-html` - HTML test reports
- `httpx` - HTTP client for testing
- `coverage` - Code coverage tool

### 2. Run First Test

```bash
# Run all tests
pytest

# Run with output
pytest -v

# Run specific file
pytest tests/test_example.py
```

### 3. Check Coverage

```bash
# Run with coverage report
pytest --cov=app --cov-report=html

# Open coverage report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

## Writing Tests

### Basic Test Pattern

```python
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_endpoint_name(client: AsyncClient):
    """Test description."""
    # 1. Make request
    response = await client.get("/api/endpoint")

    # 2. Assert status code
    assert response.status_code == 200

    # 3. Assert response data
    data = response.json()
    assert data["key"] == "expected_value"
```

### Test Class Pattern

```python
class TestFeatureName:
    """Group related tests together."""

    @pytest.mark.asyncio
    async def test_scenario_one(self, client):
        """Test specific scenario."""
        response = await client.get("/endpoint")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_scenario_two(self, client):
        """Test another scenario."""
        response = await client.post("/endpoint", json={...})
        assert response.status_code == 201
```

### Testing with Database

```python
@pytest.mark.asyncio
async def test_create_and_retrieve(client: AsyncClient, db_session):
    """Test creating and retrieving data."""
    from app.models import ApprovalRequest

    # Create test data
    approval = ApprovalRequest(
        build_number="123",
        job_name="test-job",
        # ... other fields
    )
    db_session.add(approval)
    await db_session.commit()

    # Test API retrieval
    response = await client.get("/api/v1/approvals")
    assert response.status_code == 200
    assert response.json()["count"] == 1
```

### Testing Different HTTP Methods

```python
# GET request
response = await client.get("/api/endpoint")

# POST request with JSON
response = await client.post(
    "/api/endpoint",
    json={"key": "value"}
)

# PUT request
response = await client.put(
    "/api/endpoint/1",
    json={"key": "new_value"}
)

# DELETE request
response = await client.delete("/api/endpoint/1")

# With query parameters
response = await client.get(
    "/api/endpoint",
    params={"status": "pending", "limit": 10}
)
```

## Running Tests

### Basic Commands

```bash
# Run all tests
pytest

# Verbose output (show test names)
pytest -v

# Very verbose (show all output)
pytest -vv

# Show print statements
pytest -s

# Stop after first failure
pytest -x

# Run last failed tests
pytest --lf
```

### Run Specific Tests

```bash
# Run specific file
pytest tests/test_api.py

# Run specific class
pytest tests/test_api.py::TestHealthEndpoints

# Run specific test
pytest tests/test_api.py::TestHealthEndpoints::test_health_check

# Run tests matching pattern
pytest -k "health"  # Runs all tests with "health" in name
```

### Parallel Execution

```bash
# Install pytest-xdist first
pip install pytest-xdist

# Run tests in parallel
pytest -n auto  # Use all CPU cores
pytest -n 4     # Use 4 workers
```

## Test Coverage

### Generate Coverage Reports

```bash
# Terminal report
pytest --cov=app

# HTML report (detailed)
pytest --cov=app --cov-report=html

# XML report (for CI/CD)
pytest --cov=app --cov-report=xml

# Combined reports
pytest --cov=app --cov-report=html --cov-report=term-missing
```

### Coverage Configuration

In `pytest.ini`:
```ini
[coverage:report]
fail_under = 70  # Fail if coverage below 70%
```

### View Coverage

```bash
# After running with --cov-report=html
cd htmlcov
python -m http.server 8000
# Open http://localhost:8000 in browser
```

## Best Practices

### 1. Test Organization

```
tests/
├── test_api.py           # API endpoint tests
├── test_models.py        # Database model tests
├── test_services.py      # Business logic tests
├── test_integration.py   # Integration tests
└── fixtures/             # Test data files
```

### 2. Test Naming

```python
# Good: Descriptive names
def test_user_can_login_with_valid_credentials():
    pass

def test_returns_404_when_resource_not_found():
    pass

# Bad: Vague names
def test_login():
    pass

def test_error():
    pass
```

### 3. AAA Pattern (Arrange, Act, Assert)

```python
@pytest.mark.asyncio
async def test_create_approval(client):
    # Arrange - Set up test data
    payload = {
        "build_number": "123",
        "job_name": "test-job"
    }

    # Act - Perform action
    response = await client.post("/api/approvals", json=payload)

    # Assert - Verify results
    assert response.status_code == 201
    assert response.json()["build_number"] == "123"
```

### 4. Test Isolation

- Each test should be independent
- Don't rely on test execution order
- Clean up after tests (fixtures handle this)
- Use transactions for database tests

### 5. What to Test

✅ **DO Test:**
- API endpoints (status codes, response data)
- Business logic
- Edge cases and error handling
- Database operations
- Authentication/authorization

❌ **DON'T Test:**
- Third-party libraries
- Framework internals
- Trivial code (getters/setters)

## Advanced Patterns

### Custom Fixtures

Add to `conftest.py`:

```python
@pytest.fixture
async def admin_user(db_session):
    """Create admin user for testing."""
    user = User(username="admin", role="admin")
    db_session.add(user)
    await db_session.commit()
    return user

@pytest.fixture
async def authenticated_client(client, admin_user):
    """Client with authentication."""
    token = generate_token(admin_user)
    client.headers.update({"Authorization": f"Bearer {token}"})
    return client
```

### Parametrized Tests

```python
@pytest.mark.parametrize("status,expected_count", [
    ("pending", 2),
    ("approved", 1),
    ("rejected", 0),
])
@pytest.mark.asyncio
async def test_filter_by_status(client, status, expected_count):
    """Test filtering with different statuses."""
    response = await client.get(f"/api/approvals?status={status}")
    assert response.json()["count"] == expected_count
```

### Test Markers

```python
# Mark slow tests
@pytest.mark.slow
async def test_large_dataset():
    pass

# Run with: pytest -m "not slow"


# Mark integration tests
@pytest.mark.integration
async def test_full_workflow():
    pass

# Run with: pytest -m integration
```

### Mocking External Services

```python
from unittest.mock import patch, AsyncMock

@pytest.mark.asyncio
@patch("app.services.send_email")
async def test_notification_sent(mock_send_email, client):
    """Test email notification is sent."""
    mock_send_email.return_value = AsyncMock(return_value=True)

    response = await client.post("/api/notify")

    assert response.status_code == 200
    mock_send_email.assert_called_once()
```

## CI/CD Integration

### Jenkins Pipeline

```groovy
stage('Test') {
    steps {
        sh '''
            cd backend
            pip install -r requirements.txt
            pytest --cov=app --cov-report=xml --cov-report=html
        '''
    }
    post {
        always {
            // Publish HTML report
            publishHTML([
                reportDir: 'backend/htmlcov',
                reportFiles: 'index.html',
                reportName: 'Coverage Report'
            ])

            // Publish test results
            junit 'backend/test-report.xml'
        }
    }
}
```

### GitHub Actions

```yaml
- name: Run Tests
  run: |
    cd backend
    pytest --cov=app --cov-report=xml

- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    file: ./backend/coverage.xml
```

## Troubleshooting

### Tests Not Discovered

```bash
# Check pytest can find tests
pytest --collect-only

# Ensure file names start with test_
# Ensure functions start with test_
# Check pytest.ini configuration
```

### Database Connection Errors

```bash
# Ensure staging database is running
podman ps | grep postgres-staging

# Test connection
podman exec postgres-staging psql -U cicd_user -d cicd_staging -c "SELECT 1"

# Check DATABASE_URL in conftest.py
```

### Async Test Errors

```bash
# Ensure decorator is present
@pytest.mark.asyncio

# Check pytest-asyncio is installed
pip list | grep pytest-asyncio

# Set asyncio mode in pytest.ini
asyncio_mode = auto
```

## Next Steps

1. **Add more tests**: Create `test_<feature>.py` files
2. **Increase coverage**: Aim for >80% code coverage
3. **Add integration tests**: Test complete workflows
4. **Set up CI/CD**: Run tests automatically on push
5. **Add performance tests**: Use pytest-benchmark

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [FastAPI Testing](https://fastapi.tiangolo.com/tutorial/testing/)
- [SQLAlchemy Testing](https://docs.sqlalchemy.org/en/14/orm/session_transaction.html#joining-a-session-into-an-external-transaction-such-as-for-test-suites)
- [Coverage.py](https://coverage.readthedocs.io/)
