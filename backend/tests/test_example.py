"""Example test file - Basic API endpoint tests.

This file demonstrates the basic testing patterns.
Copy this structure to create new test files.
"""
import pytest
from httpx import AsyncClient


class TestHealthEndpoints:
    """Test basic health check endpoints.

    Test classes group related tests together.
    Class name must start with 'Test'.
    """

    @pytest.mark.asyncio
    async def test_health_check(self, client: AsyncClient):
        """Test /health endpoint returns healthy status.

        Args:
            client: HTTP client fixture from conftest.py

        Pattern:
            1. Make request
            2. Assert status code
            3. Assert response data
        """
        # Make request
        response = await client.get("/health")

        # Check status code
        assert response.status_code == 200

        # Check response data
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "backend"
        assert "timestamp" in data

    @pytest.mark.asyncio
    async def test_root_endpoint(self, client: AsyncClient):
        """Test / endpoint returns API info."""
        response = await client.get("/")
        assert response.status_code == 200

        data = response.json()
        assert data["name"] == "CI/CD Backend API"
        assert "version" in data
        assert "docs" in data


# ============================================
# HOW TO ADD MORE TESTS
# ============================================

# 1. Create new test file: tests/test_<feature>.py
# 2. Import pytest and AsyncClient
# 3. Create test class: class Test<Feature>:
# 4. Add test methods: async def test_<scenario>(self, client):
# 5. Use @pytest.mark.asyncio decorator for async tests

# ============================================
# EXAMPLE: Testing database operations
# ============================================

class TestDatabaseOperations:
    """Example of testing with database."""

    @pytest.mark.asyncio
    async def test_list_empty_approvals(self, client: AsyncClient):
        """Test listing approvals when database is empty."""
        response = await client.get("/api/v1/approvals")
        assert response.status_code == 200

        data = response.json()
        assert data["count"] == 0
        assert data["approvals"] == []


# ============================================
# RUNNING TESTS
# ============================================

# Run all tests:
#   pytest

# Run specific file:
#   pytest tests/test_example.py

# Run specific test:
#   pytest tests/test_example.py::TestHealthEndpoints::test_health_check

# Run with coverage:
#   pytest --cov=app --cov-report=html

# Run verbose:
#   pytest -v

# Run and see print statements:
#   pytest -s
