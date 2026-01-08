#!/bin/bash

echo "===================================="
echo "CI/CD Platform Health Check"
echo "===================================="
echo ""
echo "Timestamp: $(date)"
echo ""

# Determine which docker command to use
if command -v podman >/dev/null 2>&1; then
    DOCKER_CMD="podman"
else
    DOCKER_CMD="docker"
fi

check_service() {
    local name=$1
    local url=$2

    if curl -sf "$url" > /dev/null 2>&1; then
        echo "✅ $name: Healthy"
        return 0
    else
        echo "❌ $name: Unhealthy or not responding"
        return 1
    fi
}

check_container() {
    local name=$1

    if $DOCKER_CMD ps --format '{{.Names}}' | grep -q "^${name}$"; then
        echo "✅ Container $name: Running"
        return 0
    else
        echo "❌ Container $name: Not running"
        return 1
    fi
}

# Check containers
echo "Container Status:"
echo "-----------------------------------"
check_container "jenkins"
check_container "registry"
check_container "backend"
check_container "web"
check_container "cadvisor"
check_container "prometheus"
check_container "grafana"
echo ""

# Check services
echo "Service Health:"
echo "-----------------------------------"
check_service "Jenkins" "http://localhost:8080"
check_service "Registry" "http://registry.lan:5000/v2/_catalog"
check_service "Backend" "http://localhost:5001/health"
check_service "Frontend" "http://localhost/"
check_service "cAdvisor" "http://localhost:8081"
check_service "Prometheus" "http://localhost:9090/-/healthy"
check_service "Grafana" "http://localhost:3000/api/health"
echo ""

# System resources
echo "System Resources:"
echo "-----------------------------------"

# CPU usage
if command -v mpstat >/dev/null 2>&1; then
    CPU_IDLE=$(mpstat 1 1 | awk '/Average/ {print $NF}')
    CPU_USED=$(echo "100 - $CPU_IDLE" | bc)
    echo "CPU Usage: ${CPU_USED}%"
elif command -v top >/dev/null 2>&1; then
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "CPU Usage: ${CPU}%"
fi

# Memory usage
if command -v free >/dev/null 2>&1; then
    MEMORY=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')
    echo "Memory Usage: $MEMORY"
fi

# Disk usage
if command -v df >/dev/null 2>&1; then
    DISK=$(df -h / | awk 'NR==2 {print $5}')
    echo "Disk Usage: $DISK"
fi

# Temperature (Raspberry Pi specific)
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP_C=$(echo "scale=1; $TEMP / 1000" | bc)
    echo "CPU Temperature: ${TEMP_C}°C"
fi

# Load average
if command -v uptime >/dev/null 2>&1; then
    LOAD=$(uptime | awk -F'load average:' '{print $2}')
    echo "Load Average:$LOAD"
fi

echo ""

# Docker/Podman stats
echo "Container Resource Usage:"
echo "-----------------------------------"
$DOCKER_CMD stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo ""

# Check for any stopped containers
echo "Recent Container Issues:"
echo "-----------------------------------"
STOPPED=$($DOCKER_CMD ps -a --filter "status=exited" --format "{{.Names}}" | wc -l)
if [ "$STOPPED" -gt 0 ]; then
    echo "⚠️  Found $STOPPED stopped container(s):"
    $DOCKER_CMD ps -a --filter "status=exited" --format "  - {{.Names}} (exited {{.Status}})"
else
    echo "✅ No stopped containers"
fi
echo ""

# Check disk space
echo "Volume Disk Usage:"
echo "-----------------------------------"
if command -v du >/dev/null 2>&1; then
    $DOCKER_CMD volume ls --format "{{.Name}}" | while read volume; do
        if [ -n "$volume" ]; then
            # Note: This is an approximation, actual path may vary
            echo "  - $volume"
        fi
    done
fi
echo ""

echo "===================================="
echo "Health Check Complete"
echo "===================================="
echo ""
echo "Tips:"
echo "  - View logs: podman logs <container-name>"
echo "  - Restart service: podman-compose restart <service-name>"
echo "  - Check Prometheus targets: http://localhost:9090/targets"
echo "  - View Grafana dashboards: http://localhost:3000"
echo ""
