"""Database models for CI/CD platform."""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, JSON, Enum, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import enum

from .database import Base


class TestStatus(str, enum.Enum):
    """Test execution status."""
    PENDING = "pending"
    RUNNING = "running"
    PASSED = "passed"
    FAILED = "failed"
    SKIPPED = "skipped"
    ERROR = "error"


class ApprovalStatus(str, enum.Enum):
    """Approval request status."""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    CANCELLED = "cancelled"


class DeploymentStatus(str, enum.Enum):
    """Deployment status."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    SUCCESS = "success"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


class Environment(str, enum.Enum):
    """Deployment environment."""
    STAGING = "staging"
    PRODUCTION = "production"


class TestResult(Base):
    """Test execution results."""
    __tablename__ = "test_results"

    id = Column(Integer, primary_key=True, index=True)
    build_number = Column(String(50), nullable=False, index=True)
    job_name = Column(String(100), nullable=False, index=True)
    test_suite = Column(String(100), nullable=False)  # pytest, flutter, e2e, etc.
    test_name = Column(String(255), nullable=False)
    status = Column(Enum(TestStatus), nullable=False, default=TestStatus.PENDING)
    duration = Column(Integer)  # Duration in milliseconds
    error_message = Column(Text)
    stack_trace = Column(Text)

    # Coverage data
    coverage_percent = Column(Integer)  # Overall coverage percentage

    # Timestamps
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    approval_id = Column(Integer, ForeignKey("approval_requests.id"))

    def __repr__(self):
        return f"<TestResult {self.job_name}#{self.build_number} - {self.test_name}: {self.status}>"


class TestSummary(Base):
    """Aggregated test summary per build."""
    __tablename__ = "test_summaries"

    id = Column(Integer, primary_key=True, index=True)
    build_number = Column(String(50), nullable=False, index=True)
    job_name = Column(String(100), nullable=False, index=True)

    # Test counts
    total_tests = Column(Integer, default=0)
    passed_tests = Column(Integer, default=0)
    failed_tests = Column(Integer, default=0)
    skipped_tests = Column(Integer, default=0)
    error_tests = Column(Integer, default=0)

    # Coverage
    overall_coverage = Column(Integer)

    # Duration
    total_duration = Column(Integer)  # Total test duration in milliseconds

    # Report links
    html_report_url = Column(String(500))
    allure_report_url = Column(String(500))

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    approval_id = Column(Integer, ForeignKey("approval_requests.id"))

    def __repr__(self):
        return f"<TestSummary {self.job_name}#{self.build_number}: {self.passed_tests}/{self.total_tests} passed>"


class SecurityScan(Base):
    """Security scan results."""
    __tablename__ = "security_scans"

    id = Column(Integer, primary_key=True, index=True)
    build_number = Column(String(50), nullable=False, index=True)
    job_name = Column(String(100), nullable=False, index=True)
    scanner = Column(String(50), nullable=False)  # trivy, etc.

    # Vulnerability counts
    critical_count = Column(Integer, default=0)
    high_count = Column(Integer, default=0)
    medium_count = Column(Integer, default=0)
    low_count = Column(Integer, default=0)

    # Details
    vulnerabilities = Column(JSON)  # Full vulnerability list
    report_url = Column(String(500))

    # Timestamps
    scanned_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    approval_id = Column(Integer, ForeignKey("approval_requests.id"))

    def __repr__(self):
        return f"<SecurityScan {self.job_name}#{self.build_number}: {self.critical_count}C {self.high_count}H>"


class ApprovalRequest(Base):
    """Approval requests for staging to production promotion."""
    __tablename__ = "approval_requests"

    id = Column(Integer, primary_key=True, index=True)
    build_number = Column(String(50), nullable=False, index=True)
    job_name = Column(String(100), nullable=False, index=True)

    # Request details
    status = Column(Enum(ApprovalStatus), nullable=False, default=ApprovalStatus.PENDING)
    requested_by = Column(String(100), nullable=False)  # Jenkins user or system

    # Deployment info
    git_commit = Column(String(40), nullable=False)
    git_branch = Column(String(100), nullable=False)
    version_tag = Column(String(50))

    # Environment URLs
    staging_backend_url = Column(String(500))
    staging_frontend_url = Column(String(500))
    staging_api_docs_url = Column(String(500))

    # Approval details
    approved_by = Column(String(100))
    approval_notes = Column(Text)
    rejection_reason = Column(Text)

    # Manual test checklist (JSON array of test items)
    manual_tests = Column(JSON)  # [{"name": "Login works", "passed": true, "notes": "OK"}]

    # Timestamps
    requested_at = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_at = Column(DateTime(timezone=True))

    # Relationships
    test_results = relationship("TestResult", backref="approval")
    test_summary = relationship("TestSummary", backref="approval")
    security_scans = relationship("SecurityScan", backref="approval")
    deployments = relationship("Deployment", backref="approval")

    def __repr__(self):
        return f"<ApprovalRequest #{self.id} {self.job_name}#{self.build_number}: {self.status}>"


class Deployment(Base):
    """Deployment history."""
    __tablename__ = "deployments"

    id = Column(Integer, primary_key=True, index=True)
    build_number = Column(String(50), nullable=False, index=True)
    job_name = Column(String(100), nullable=False, index=True)

    # Deployment details
    environment = Column(Enum(Environment), nullable=False)
    status = Column(Enum(DeploymentStatus), nullable=False, default=DeploymentStatus.PENDING)

    # Version info
    git_commit = Column(String(40), nullable=False)
    git_branch = Column(String(100), nullable=False)
    version_tag = Column(String(50))
    image_tag = Column(String(100))  # Docker image tag

    # Deployment metadata
    deployed_by = Column(String(100), nullable=False)
    deployment_notes = Column(Text)

    # Rollback info
    is_rollback = Column(Boolean, default=False)
    previous_deployment_id = Column(Integer, ForeignKey("deployments.id"))

    # URLs after deployment
    backend_url = Column(String(500))
    frontend_url = Column(String(500))

    # Timestamps
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True))

    # Relationships
    approval_id = Column(Integer, ForeignKey("approval_requests.id"))
    previous_deployment = relationship("Deployment", remote_side=[id], backref="rollbacks")

    def __repr__(self):
        return f"<Deployment {self.job_name}#{self.build_number} to {self.environment}: {self.status}>"


class NotificationLog(Base):
    """Log of notifications sent."""
    __tablename__ = "notification_logs"

    id = Column(Integer, primary_key=True, index=True)

    # Notification details
    notification_type = Column(String(50), nullable=False)  # email, slack, telegram
    recipient = Column(String(200), nullable=False)
    subject = Column(String(500))
    message = Column(Text, nullable=False)

    # Related entities
    approval_id = Column(Integer, ForeignKey("approval_requests.id"))
    deployment_id = Column(Integer, ForeignKey("deployments.id"))

    # Status
    sent_successfully = Column(Boolean, default=False)
    error_message = Column(Text)

    # Timestamps
    sent_at = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<NotificationLog {self.notification_type} to {self.recipient}: {'✓' if self.sent_successfully else '✗'}>"
