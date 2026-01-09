"""FastAPI application main entry point."""
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy.ext.asyncio import AsyncSession
import os
import psutil
from datetime import datetime

from .database import init_db, get_db
# Import models so they are registered with SQLAlchemy
from . import models

app = FastAPI(
    title="CI/CD Backend API",
    description="Sample FastAPI backend for Raspberry Pi CI/CD platform",
    version="1.0.1",
)


@app.on_event("startup")
async def startup_event():
    """Initialize database on startup."""
    await init_db()
    print("✅ Database initialized successfully")

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
        "version": "1.0.1",
        "docs": "/docs",
        "health": "/health",
        "database": "connected" if os.getenv("DATABASE_URL") else "not configured",
    }


# ============================================
# CI/CD Platform API Endpoints
# ============================================

@app.get("/api/v1/approvals")
async def list_approvals(
    status: str = None,
    limit: int = 10,
    db: AsyncSession = Depends(get_db)
):
    """
    List approval requests.

    Args:
        status: Filter by status (pending, approved, rejected)
        limit: Max number of results
        db: Database session

    Returns:
        list: Approval requests
    """
    from sqlalchemy import select
    from .models import ApprovalRequest

    query = select(ApprovalRequest).order_by(ApprovalRequest.requested_at.desc()).limit(limit)

    if status:
        query = query.where(ApprovalRequest.status == status)

    result = await db.execute(query)
    approvals = result.scalars().all()

    return {
        "count": len(approvals),
        "approvals": [
            {
                "id": a.id,
                "build_number": a.build_number,
                "job_name": a.job_name,
                "status": a.status,
                "git_commit": a.git_commit,
                "requested_at": a.requested_at.isoformat() if a.requested_at else None,
                "staging_frontend_url": a.staging_frontend_url,
                "staging_backend_url": a.staging_backend_url,
            }
            for a in approvals
        ]
    }


@app.get("/api/v1/approvals/{approval_id}")
async def get_approval(
    approval_id: int,
    db: AsyncSession = Depends(get_db)
):
    """
    Get approval request details.

    Args:
        approval_id: Approval ID
        db: Database session

    Returns:
        dict: Approval details with test results
    """
    from sqlalchemy import select
    from .models import ApprovalRequest, TestSummary, SecurityScan

    # Get approval
    result = await db.execute(
        select(ApprovalRequest).where(ApprovalRequest.id == approval_id)
    )
    approval = result.scalar_one_or_none()

    if not approval:
        return {"error": "Approval not found"}, 404

    # Get test summary
    result = await db.execute(
        select(TestSummary).where(TestSummary.approval_id == approval_id)
    )
    test_summary = result.scalar_one_or_none()

    # Get security scan
    result = await db.execute(
        select(SecurityScan).where(SecurityScan.approval_id == approval_id)
    )
    security_scan = result.scalar_one_or_none()

    return {
        "id": approval.id,
        "build_number": approval.build_number,
        "job_name": approval.job_name,
        "status": approval.status,
        "git_commit": approval.git_commit,
        "git_branch": approval.git_branch,
        "requested_by": approval.requested_by,
        "requested_at": approval.requested_at.isoformat() if approval.requested_at else None,
        "staging_frontend_url": approval.staging_frontend_url,
        "staging_backend_url": approval.staging_backend_url,
        "staging_api_docs_url": approval.staging_api_docs_url,
        "test_summary": {
            "total": test_summary.total_tests if test_summary else 0,
            "passed": test_summary.passed_tests if test_summary else 0,
            "failed": test_summary.failed_tests if test_summary else 0,
            "coverage": test_summary.overall_coverage if test_summary else None,
            "report_url": test_summary.html_report_url if test_summary else None,
        } if test_summary else None,
        "security_scan": {
            "critical": security_scan.critical_count if security_scan else 0,
            "high": security_scan.high_count if security_scan else 0,
            "medium": security_scan.medium_count if security_scan else 0,
            "low": security_scan.low_count if security_scan else 0,
        } if security_scan else None,
        "manual_tests": approval.manual_tests,
        "approval_notes": approval.approval_notes,
        "rejection_reason": approval.rejection_reason,
    }


@app.get("/api/v1/deployments")
async def list_deployments(
    environment: str = None,
    limit: int = 20,
    db: AsyncSession = Depends(get_db)
):
    """
    List deployments.

    Args:
        environment: Filter by environment (staging, production)
        limit: Max number of results
        db: Database session

    Returns:
        list: Deployments
    """
    from sqlalchemy import select
    from .models import Deployment

    query = select(Deployment).order_by(Deployment.started_at.desc()).limit(limit)

    if environment:
        query = query.where(Deployment.environment == environment)

    result = await db.execute(query)
    deployments = result.scalars().all()

    return {
        "count": len(deployments),
        "deployments": [
            {
                "id": d.id,
                "build_number": d.build_number,
                "job_name": d.job_name,
                "environment": d.environment,
                "status": d.status,
                "version_tag": d.version_tag,
                "deployed_by": d.deployed_by,
                "started_at": d.started_at.isoformat() if d.started_at else None,
                "completed_at": d.completed_at.isoformat() if d.completed_at else None,
                "is_rollback": d.is_rollback,
            }
            for d in deployments
        ]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)
