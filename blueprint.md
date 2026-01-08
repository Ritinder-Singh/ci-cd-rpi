# Raspberry Pi CI/CD & Monitoring Platform

## Overview

This document outlines a complete CI/CD and monitoring setup on a **Raspberry Pi 5 (8GB RAM, 128GB+ storage)** for a Python backend and Flutter web frontend. It leverages **Docker, docker-compose, Jenkins, Prometheus, Grafana, and cAdvisor** to provide a full local development and deployment environment with monitoring, alerting, and optional remote access via Tailscale.

---

## Architecture Overview

```mermaid
flowchart TD
    A[GitHub Repo] -->|Webhook / Polling| B[Jenkins (CI/CD)]
    B --> C[Test & Build]
    C --> D[Local Docker Registry]
    D --> E[Docker Deployment]
    E --> F[Containers on Raspberry Pi]
    F --> G[Monitoring & Control Dashboard]

    subgraph Containers on Pi
        backend[Backend API (Python)]
        web[Web UI (Flutter Web)]
        jenkins[Jenkins CI/CD]
        registry[Local Docker Registry]
        cadvisor[cAdvisor]
        prometheus[Prometheus]
        grafana[Grafana]
    end

    F -->|Metrics & Alerts| G
    F -->|Container Control| G
