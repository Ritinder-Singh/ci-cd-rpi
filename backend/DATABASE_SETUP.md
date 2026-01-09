# Database Setup Guide

## Overview

The backend uses PostgreSQL for storing:
- Test results and coverage reports
- Approval workflow data
- Deployment history
- Security scan results
- Notification logs

## Database Configuration

Databases are configured in `docker-compose.yaml`:

- **Production**: `postgres:5432` (cicd_production)
- **Staging**: `postgres-staging:5433` (cicd_staging)

## Running Migrations

### Initial Setup (First Time)

1. Ensure databases are running:
```bash
podman-compose up -d postgres postgres-staging
```

2. Create initial migration:
```bash
cd backend
alembic revision --autogenerate -m "Initial schema"
```

3. Apply migrations:
```bash
# Production
DATABASE_URL="postgresql://cicd_user:cicd_password_prod@localhost:5432/cicd_production" alembic upgrade head

# Staging
DATABASE_URL="postgresql://cicd_user:cicd_password_staging@localhost:5433/cicd_staging" alembic upgrade head
```

### After Model Changes

1. Generate migration:
```bash
alembic revision --autogenerate -m "Description of changes"
```

2. Review the generated migration in `alembic/versions/`

3. Apply migration:
```bash
alembic upgrade head
```

### Useful Commands

```bash
# Show current migration version
alembic current

# Show migration history
alembic history

# Rollback one migration
alembic downgrade -1

# Rollback to specific version
alembic downgrade <revision_id>

# See SQL without applying
alembic upgrade head --sql
```

## Database Models

### TestResult
Stores individual test results (unit, integration, E2E)

### TestSummary
Aggregated test metrics per build (pass/fail counts, coverage)

### SecurityScan
Security vulnerability scan results (Trivy)

### ApprovalRequest
Staging-to-production approval workflow

### Deployment
Deployment history for both environments

### NotificationLog
Audit log of notifications sent

## API Endpoints

- `GET /api/v1/approvals` - List approval requests
- `GET /api/v1/approvals/{id}` - Get approval details with test results
- `GET /api/v1/deployments` - List deployments
- `GET /api/v1/deployments?environment=production` - Filter by environment

## Environment Variables

```bash
DATABASE_URL=postgresql://cicd_user:cicd_password_prod@postgres:5432/cicd_production
REDIS_URL=redis://redis:6379/0
APP_ENV=production
LOG_LEVEL=info
```

## Troubleshooting

### Can't connect to database
```bash
# Check if PostgreSQL is running
podman ps | grep postgres

# Test connection
podman exec -it postgres psql -U cicd_user -d cicd_production
```

### Migration fails
```bash
# Check current version
alembic current

# Force to specific version (careful!)
alembic stamp head
```

### Reset database (DESTRUCTIVE)
```bash
# Drop all tables
alembic downgrade base

# Reapply all migrations
alembic upgrade head
```
