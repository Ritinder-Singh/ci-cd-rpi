"""FastAPI application main entry point."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
import os
import psutil
from datetime import datetime

app = FastAPI(
    title="CI/CD Backend API",
    description="Sample FastAPI backend for Raspberry Pi CI/CD platform",
    version="1.0.0",
)

# CORS middleware - allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics instrumentation
Instrumentator().instrument(app).expose(app)


@app.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring.

    Returns:
        dict: Health status with timestamp
    """
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "backend",
    }


@app.get("/api/v1/hello")
async def hello():
    """
    Simple hello endpoint.

    Returns:
        dict: Welcome message with version and timestamp
    """
    return {
        "message": "Hello from Raspberry Pi CI/CD Platform - Automated Deployment!",
        "version": "1.0.1",
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/api/v1/info")
async def system_info():
    """
    System information endpoint.

    Returns:
        dict: System metrics including CPU, memory, and disk usage
    """
    return {
        "cpu_percent": round(psutil.cpu_percent(interval=1), 2),
        "memory_percent": round(psutil.virtual_memory().percent, 2),
        "disk_percent": round(psutil.disk_usage('/').percent, 2),
        "hostname": os.getenv("HOSTNAME", "unknown"),
        "environment": os.getenv("APP_ENV", "development"),
    }


@app.get("/")
async def root():
    """
    Root endpoint.

    Returns:
        dict: API information
    """
    return {
        "name": "CI/CD Backend API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)
