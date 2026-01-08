#!/bin/bash
set -e

BACKUP_DIR="${BACKUP_DIR:-/home/ritinder/backups/ci-cd-rpi}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/backup_${TIMESTAMP}"

# Determine which docker command to use
if command -v podman >/dev/null 2>&1; then
    DOCKER_CMD="podman"
else
    DOCKER_CMD="docker"
fi

echo "===================================="
echo "CI/CD Platform Backup"
echo "===================================="
echo ""
echo "Timestamp: $(date)"
echo "Backup location: $BACKUP_PATH"
echo ""

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Backup Jenkins home
echo "Backing up Jenkins data..."
if $DOCKER_CMD ps --format '{{.Names}}' | grep -q "^jenkins$"; then
    $DOCKER_CMD exec jenkins tar czf /tmp/jenkins-backup.tar.gz -C /var/jenkins_home . 2>/dev/null || \
        echo "Warning: Some Jenkins files could not be backed up (this is normal)"
    $DOCKER_CMD cp jenkins:/tmp/jenkins-backup.tar.gz "$BACKUP_PATH/" 2>/dev/null
    $DOCKER_CMD exec jenkins rm /tmp/jenkins-backup.tar.gz 2>/dev/null || true
    echo "✅ Jenkins backup complete"
else
    echo "⚠️  Jenkins container not running, skipping..."
fi
echo ""

# Backup Registry data
echo "Backing up Docker Registry..."
if $DOCKER_CMD ps --format '{{.Names}}' | grep -q "^registry$"; then
    $DOCKER_CMD exec registry tar czf /tmp/registry-backup.tar.gz -C /var/lib/registry . 2>/dev/null
    $DOCKER_CMD cp registry:/tmp/registry-backup.tar.gz "$BACKUP_PATH/" 2>/dev/null
    $DOCKER_CMD exec registry rm /tmp/registry-backup.tar.gz 2>/dev/null || true
    echo "✅ Registry backup complete"
else
    echo "⚠️  Registry container not running, skipping..."
fi
echo ""

# Backup Grafana data
echo "Backing up Grafana data..."
if $DOCKER_CMD ps --format '{{.Names}}' | grep -q "^grafana$"; then
    $DOCKER_CMD exec grafana tar czf /tmp/grafana-backup.tar.gz -C /var/lib/grafana . 2>/dev/null
    $DOCKER_CMD cp grafana:/tmp/grafana-backup.tar.gz "$BACKUP_PATH/" 2>/dev/null
    $DOCKER_CMD exec grafana rm /tmp/grafana-backup.tar.gz 2>/dev/null || true
    echo "✅ Grafana backup complete"
else
    echo "⚠️  Grafana container not running, skipping..."
fi
echo ""

# Backup Prometheus data
echo "Backing up Prometheus data..."
if $DOCKER_CMD ps --format '{{.Names}}' | grep -q "^prometheus$"; then
    $DOCKER_CMD exec prometheus tar czf /tmp/prometheus-backup.tar.gz -C /prometheus . 2>/dev/null || \
        echo "Warning: Some Prometheus files could not be backed up (this is normal)"
    $DOCKER_CMD cp prometheus:/tmp/prometheus-backup.tar.gz "$BACKUP_PATH/" 2>/dev/null
    $DOCKER_CMD exec prometheus rm /tmp/prometheus-backup.tar.gz 2>/dev/null || true
    echo "✅ Prometheus backup complete"
else
    echo "⚠️  Prometheus container not running, skipping..."
fi
echo ""

# Backup configuration files
echo "Backing up configuration files..."
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$PROJECT_DIR"

tar czf "$BACKUP_PATH/config-backup.tar.gz" \
    docker-compose.yaml \
    .env \
    prometheus/ \
    grafana/ \
    scripts/ \
    2>/dev/null || true

echo "✅ Configuration backup complete"
echo ""

# Calculate backup size
BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)

echo "===================================="
echo "Backup Complete!"
echo "===================================="
echo ""
echo "Location: $BACKUP_PATH"
echo "Size: $BACKUP_SIZE"
echo ""
echo "Backup contents:"
ls -lh "$BACKUP_PATH"
echo ""

# Cleanup old backups (keep last 7 days by default)
RETENTION_DAYS=${RETENTION_DAYS:-7}
echo "Cleaning up backups older than $RETENTION_DAYS days..."
if [ -d "$BACKUP_DIR" ]; then
    DELETED=$(find "$BACKUP_DIR" -name "backup_*" -type d -mtime +$RETENTION_DAYS 2>/dev/null | wc -l)
    find "$BACKUP_DIR" -name "backup_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true
    if [ "$DELETED" -gt 0 ]; then
        echo "✅ Deleted $DELETED old backup(s)"
    else
        echo "✅ No old backups to delete"
    fi
else
    echo "✅ No old backups to clean up"
fi
echo ""

echo "===================================="
echo "Backup Summary"
echo "===================================="
echo ""
echo "All backups are stored in: $BACKUP_DIR"
if [ -d "$BACKUP_DIR" ]; then
    TOTAL_BACKUPS=$(ls -d "$BACKUP_DIR"/backup_* 2>/dev/null | wc -l)
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo "Total backups: $TOTAL_BACKUPS"
    echo "Total size: $TOTAL_SIZE"
else
    echo "No previous backups found"
fi
echo ""

echo "To restore from this backup:"
echo "  1. Stop services: podman-compose down"
echo "  2. Extract backup: tar xzf $BACKUP_PATH/<backup-file>.tar.gz"
echo "  3. Start services: podman-compose up -d"
echo ""

echo "To schedule automatic backups, add to crontab:"
echo "  0 2 * * * $PROJECT_DIR/scripts/backup.sh"
echo "  (This runs daily at 2 AM)"
echo ""
