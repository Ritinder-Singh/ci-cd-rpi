"""Tests for API endpoints."""
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root():
    """Test root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "name" in data
    assert "version" in data


def test_health_check():
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data
    assert data["service"] == "backend"


def test_hello_endpoint():
    """Test hello endpoint."""
    response = client.get("/api/v1/hello")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data
    assert "timestamp" in data


def test_info_endpoint():
    """Test system info endpoint."""
    response = client.get("/api/v1/info")
    assert response.status_code == 200
    data = response.json()
    assert "cpu_percent" in data
    assert "memory_percent" in data
    assert "disk_percent" in data
    assert "hostname" in data
    assert "environment" in data


def test_metrics_endpoint():
    """Test Prometheus metrics endpoint."""
    response = client.get("/metrics")
    assert response.status_code == 200
    # Metrics should be in text format
    assert response.headers["content-type"].startswith("text/plain")
