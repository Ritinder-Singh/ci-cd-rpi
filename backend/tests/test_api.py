"""Basic API endpoint tests.

Add your real API tests here following the examples in test_example.py
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_hello_endpoint(client: AsyncClient):
    """Test /api/v1/hello endpoint."""
    response = await client.get("/api/v1/hello")
    assert response.status_code == 200

    data = response.json()
    assert "message" in data
    assert "version" in data


@pytest.mark.asyncio
async def test_system_info(client: AsyncClient):
    """Test /api/v1/info endpoint."""
    response = await client.get("/api/v1/info")
    assert response.status_code == 200

    data = response.json()
    assert "cpu_percent" in data
    assert "memory_percent" in data
    assert "disk_percent" in data
