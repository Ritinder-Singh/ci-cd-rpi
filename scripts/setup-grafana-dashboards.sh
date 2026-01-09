#!/bin/bash

  GRAFANA_URL="http://localhost:3000"
  GRAFANA_USER="admin"
  GRAFANA_PASS="C6jxE5&Yx6#z$4A"

  echo "Setting up Grafana dashboards..."

  # Create CI/CD Platform Overview Dashboard
  curl -X POST "$GRAFANA_URL/api/dashboards/db" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -H "Content-Type: application/json" \
    -d '{
    "dashboard": {
      "title": "CI/CD Platform Overview",
      "tags": ["cicd", "platform"],
      "timezone": "browser",
      "refresh": "10s",
      "panels": [
        {
          "id": 1,
          "type": "stat",
          "title": "Service Status",
          "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
          "targets": [{
            "expr": "up{service!=\"\"}",
            "legendFormat": "{{service}}"
          }],
          "options": {
            "colorMode": "value",
            "graphMode": "none",
            "textMode": "value_and_name"
          },
          "fieldConfig": {
            "defaults": {
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {"value": 0, "color": "red"},
                  {"value": 1, "color": "green"}
                ]
              },
              "mappings": [
                {"type": "value", "value": "0", "text": "DOWN"},
                {"type": "value", "value": "1", "text": "UP"}
              ]
            }
          }
        },
        {
          "id": 2,
          "type": "timeseries",
          "title": "Container CPU Usage (%)",
          "gridPos": {"h": 8, "w": 9, "x": 6, "y": 0},
          "targets": [{
            "expr": "rate(container_cpu_usage_seconds_total{name=~\"backend|web|jenkins|prometheus|grafana\"}[5m]) * 100",
            "legendFormat": "{{name}}"
          }],
          "fieldConfig": {
            "defaults": {
              "unit": "percent",
              "min": 0,
              "max": 100
            }
          }
        },
        {
          "id": 3,
          "type": "timeseries",
          "title": "Container Memory Usage (MB)",
          "gridPos": {"h": 8, "w": 9, "x": 15, "y": 0},
          "targets": [{
            "expr": "container_memory_usage_bytes{name=~\"backend|web|jenkins|prometheus|grafana\"} / 1024 / 1024",
            "legendFormat": "{{name}}"
          }],
          "fieldConfig": {
            "defaults": {
              "unit": "decmbytes"
            }
          }
        },
        {
          "id": 4,
          "type": "timeseries",
          "title": "Backend API Requests/sec",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
          "targets": [{
            "expr": "rate(http_requests_total{service=\"backend\"}[5m])",
            "legendFormat": "{{method}} {{path}}"
          }],
          "fieldConfig": {
            "defaults": {
              "unit": "reqps"
            }
          }
        },
        {
          "id": 5,
          "type": "timeseries",
          "title": "Network Traffic (bytes/sec)",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
          "targets": [
            {
              "expr": "rate(container_network_receive_bytes_total{name=~\"backend|web\"}[5m])",
              "legendFormat": "{{name}} RX"
            },
            {
              "expr": "rate(container_network_transmit_bytes_total{name=~\"backend|web\"}[5m])",
              "legendFormat": "{{name}} TX"
            }
          ],
          "fieldConfig": {
            "defaults": {
              "unit": "Bps"
            }
          }
        }
      ]
    },
    "overwrite": true
  }'

  echo ""
  echo "✅ CI/CD Platform Overview dashboard created!"

  # Import Docker Monitoring Dashboard (ID 193)
  curl -X POST "$GRAFANA_URL/api/dashboards/import" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -H "Content-Type: application/json" \
    -d '{
    "dashboard": {
      "id": null,
      "uid": null,
      "title": "Docker Monitoring"
    },
    "overwrite": true,
    "inputs": [{
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "Prometheus"
    }],
    "folderId": 0
  }'

  echo ""
  echo "✅ Docker Monitoring dashboard imported!"

  echo ""
  echo "================================================"
  echo "Grafana dashboards setup complete!"
  echo "================================================"
  echo ""
  echo "Access Grafana at: http://192.168.1.9:3000"
  echo ""
  echo "Available dashboards:"
  echo "  1. CI/CD Platform Overview"
  echo "  2. Docker Monitoring"
  echo ""
