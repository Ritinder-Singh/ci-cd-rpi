# Prometheus Monitoring

Prometheus configuration for monitoring the CI/CD platform on Raspberry Pi.

## Overview

Prometheus collects metrics from various services:
- **Prometheus itself**: Internal metrics
- **cAdvisor**: Container metrics (CPU, memory, network, disk I/O)
- **Backend API**: Application metrics (requests, latency, errors)
- **Jenkins**: CI/CD pipeline metrics (with Prometheus plugin)

## Configuration

### prometheus.yml

The main configuration file defines:
- **Scrape interval**: 15 seconds
- **Evaluation interval**: 15 seconds
- **Retention**: 15 days (configured in docker-compose.yaml)
- **Scrape targets**: All monitored services

### Scrape Targets

| Job Name | Target | Metrics |
|----------|--------|---------|
| prometheus | localhost:9090 | Prometheus internal metrics |
| cadvisor | cadvisor:8080 | Container CPU, memory, network, disk |
| backend | backend:5001/metrics | HTTP requests, latency, custom metrics |
| jenkins | jenkins:8080/prometheus | Build metrics, job status |

## Access Prometheus

Open your browser and navigate to:
```
http://localhost:9090
```

Or from another machine:
```
http://<raspberry-pi-ip>:9090
```

## Useful PromQL Queries

### Container Metrics

**CPU Usage by Container:**
```promql
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100
```

**Memory Usage by Container:**
```promql
container_memory_usage_bytes{name!=""}
```

**Container Memory as Percentage of Limit:**
```promql
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100
```

**Network Receive Rate:**
```promql
rate(container_network_receive_bytes_total[5m])
```

**Network Transmit Rate:**
```promql
rate(container_network_transmit_bytes_total[5m])
```

### Backend API Metrics

**Request Rate (requests per second):**
```promql
rate(http_requests_total[5m])
```

**Average Response Time:**
```promql
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

**Error Rate:**
```promql
rate(http_requests_total{status=~"5.."}[5m])
```

**95th Percentile Response Time:**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### System Metrics

**Total CPU Usage:**
```promql
sum(rate(container_cpu_usage_seconds_total[5m])) * 100
```

**Total Memory Usage:**
```promql
sum(container_memory_usage_bytes) / 1024 / 1024 / 1024
```

**Available Services (up/down):**
```promql
up
```

## Monitoring Best Practices

### 1. Check Targets
Navigate to **Status → Targets** in Prometheus UI to ensure all targets are UP.

### 2. Set Up Alerts
Create `alerts.yml` for important conditions:
```yaml
groups:
  - name: example
    rules:
      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Container memory usage is high"
```

### 3. Data Retention
Current retention: 15 days
- Adjust in docker-compose.yaml: `--storage.tsdb.retention.time=15d`
- Monitor disk usage regularly

### 4. Scrape Interval
Current interval: 15 seconds
- Good balance between data granularity and resource usage
- Adjust in prometheus.yml if needed

## Troubleshooting

### Target is DOWN

1. Check if service is running:
```bash
podman ps
```

2. Check service logs:
```bash
podman logs <service-name>
```

3. Verify network connectivity:
```bash
podman exec prometheus wget -O- http://backend:5001/metrics
```

### No metrics showing up

1. Check Prometheus logs:
```bash
podman logs prometheus
```

2. Verify configuration:
```bash
cat prometheus/prometheus.yml
```

3. Restart Prometheus:
```bash
podman-compose restart prometheus
```

### Jenkins metrics not available

1. Install Prometheus Metrics Plugin in Jenkins:
   - Manage Jenkins → Plugin Manager
   - Search for "Prometheus metrics plugin"
   - Install and restart Jenkins

2. Verify endpoint:
```bash
curl http://localhost:8080/prometheus
```

### High disk usage

1. Check data directory size:
```bash
podman exec prometheus du -sh /prometheus
```

2. Reduce retention period in docker-compose.yaml

3. Clean up old data:
```bash
podman-compose stop prometheus
podman volume rm cicd-rpi_prometheus_data
podman-compose up -d prometheus
```

## Extending Monitoring

### Add Node Exporter (Host Metrics)

1. Add to docker-compose.yaml:
```yaml
node-exporter:
  image: prom/node-exporter:latest
  container_name: node-exporter
  restart: unless-stopped
  ports:
    - "9100:9100"
  volumes:
    - /proc:/host/proc:ro
    - /sys:/host/sys:ro
    - /:/rootfs:ro
  command:
    - '--path.procfs=/host/proc'
    - '--path.sysfs=/host/sys'
    - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
```

2. Uncomment node exporter job in prometheus.yml

### Add Custom Metrics

In your backend code:
```python
from prometheus_client import Counter, Histogram

# Custom counter
custom_counter = Counter('custom_operations_total', 'Total custom operations')

# Custom histogram
custom_duration = Histogram('custom_operation_duration_seconds', 'Custom operation duration')

@app.get("/custom")
async def custom_endpoint():
    custom_counter.inc()
    with custom_duration.time():
        # Your code here
        pass
```

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [cAdvisor Metrics](https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md)
