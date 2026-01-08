# Backend API

FastAPI backend application for the CI/CD platform running on Raspberry Pi.

## Features

- RESTful API with automatic OpenAPI documentation
- Health check endpoint for monitoring
- System information endpoint (CPU, memory, disk usage)
- Prometheus metrics integration
- CORS enabled for frontend access
- Comprehensive test coverage

## Endpoints

### Health Check
```
GET /health
```
Returns service health status and timestamp.

### Root
```
GET /
```
Returns API information and available endpoints.

### Hello
```
GET /api/v1/hello
```
Returns a welcome message with version and timestamp.

### System Info
```
GET /api/v1/info
```
Returns system metrics:
- CPU usage percentage
- Memory usage percentage
- Disk usage percentage
- Hostname
- Environment

### Metrics
```
GET /metrics
```
Prometheus metrics endpoint (auto-generated).

### API Documentation
```
GET /docs
```
Interactive Swagger UI documentation.

```
GET /redoc
```
Alternative ReDoc documentation.

## Local Development

### Prerequisites
- Python 3.11+
- pip

### Setup

1. Create virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the application:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 5001
```

The API will be available at http://localhost:5001

### Running Tests

```bash
pytest tests/ -v
```

With coverage:
```bash
pytest tests/ --cov=app --cov-report=html
```

## Docker Build

Build the Docker image:
```bash
docker build -t registry.lan:5000/backend:latest .
```

Run the container:
```bash
docker run -d -p 5001:5001 --name backend registry.lan:5000/backend:latest
```

## Environment Variables

- `APP_ENV`: Application environment (default: "development")
- `LOG_LEVEL`: Logging level (default: "info")

## CI/CD Pipeline

The Jenkins pipeline (`Jenkinsfile`) performs:
1. Checkout code
2. Run tests with pytest
3. Build Docker image
4. Tag with build number and latest
5. Push to local registry
6. Deploy via docker-compose
7. Verify health check

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py          # FastAPI application
│   └── core/
│       ├── __init__.py
│       └── config.py    # Configuration settings
├── tests/
│   ├── __init__.py
│   └── test_api.py      # API tests
├── Dockerfile           # Container image definition
├── requirements.txt     # Python dependencies
├── Jenkinsfile         # CI/CD pipeline
└── README.md           # This file
```

## Monitoring

The application is automatically instrumented with Prometheus metrics including:
- HTTP request count
- HTTP request duration
- HTTP request size
- HTTP response size

Access metrics at: http://localhost:5001/metrics

## Troubleshooting

### Port already in use
```bash
# Find process using port 5001
lsof -i :5001
# Or with netstat
netstat -tlnp | grep 5001
```

### Import errors
Make sure you're in the backend directory and the virtual environment is activated:
```bash
cd backend
source venv/bin/activate
```

### Docker build fails
Check that you're in the backend directory:
```bash
cd backend
podman build -t registry.lan:5000/backend:latest .
```

## License

MIT
