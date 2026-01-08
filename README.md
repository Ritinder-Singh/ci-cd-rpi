# CI/CD & Monitoring Platform for Raspberry Pi 5

A complete continuous integration, deployment, and monitoring solution running on Raspberry Pi 5.

## Features

- **Jenkins CI/CD**: Automated build and deployment pipelines
- **Local Docker Registry**: Private container image storage
- **FastAPI Backend**: Python REST API with health checks and metrics
- **Flutter Web Frontend**: Responsive web dashboard displaying system metrics
- **Comprehensive Monitoring**: Prometheus + Grafana + cAdvisor
- **Automated Workflows**: Scripts for deployment, backup, and health checks
- **Container-based**: All services run in containers using Podman

## Architecture

```
GitHub → Jenkins → Build → Test → Push to Registry → Deploy → Monitor
                                                    ↓
                                       Prometheus + Grafana + cAdvisor
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| Jenkins | 8080 | CI/CD automation server |
| Registry | 5000 | Local Docker image registry |
| Backend API | 5001 | FastAPI REST API |
| Frontend | 80 | Flutter web dashboard |
| cAdvisor | 8081 | Container metrics collector |
| Prometheus | 9090 | Metrics storage and queries |
| Grafana | 3000 | Metrics visualization |

## Requirements

### Hardware
- Raspberry Pi 5 (8GB RAM recommended)
- 128GB+ microSD card or SSD
- Active cooling recommended
- Network connection

### Software
- Raspberry Pi OS (64-bit)
- Podman v4.9.3+
- Docker Compose v5.0.1+ (or podman-compose)
- Git

## Quick Start

See [blueprint.md](./blueprint.md) for detailed setup instructions.

### 1. Clone this repository
```bash
git clone <your-repo-url>
cd ci-cd-rpi
```

### 2. Prerequisites Setup
```bash
# Install Podman if not installed
sudo apt update
sudo apt install -y podman

# Install podman-compose
sudo apt install -y podman-compose

# Verify installations
podman --version
podman-compose --version
```

### 3. Initial Configuration
```bash
# Add registry.lan to /etc/hosts
echo "127.0.0.1 registry.lan" | sudo tee -a /etc/hosts

# Configure Podman for insecure local registry
sudo mkdir -p /etc/containers/registries.conf.d/
cat | sudo tee /etc/containers/registries.conf.d/local-registry.conf << 'EOF'
[[registry]]
location = "registry.lan:5000"
insecure = true
EOF
```

### 4. Start Infrastructure Services
```bash
# Start registry first
podman-compose up -d registry

# Start monitoring stack
podman-compose up -d prometheus grafana cadvisor

# Start Jenkins
podman-compose up -d jenkins
```

### 5. Get Jenkins Initial Password
```bash
# Wait for Jenkins to initialize (~30 seconds)
sleep 30

# Get the initial admin password
podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 6. Complete Jenkins Setup
- Open http://localhost:8080
- Enter the initial admin password
- Install suggested plugins
- Create admin user
- Configure Jenkins URL

### 7. Build and Deploy Applications
```bash
# Deploy backend
./scripts/deploy.sh backend

# Deploy frontend
./scripts/deploy.sh frontend

# Or deploy both
./scripts/deploy.sh all
```

### 8. Access Services
- **Frontend Dashboard**: http://localhost/
- **Backend API**: http://localhost:5001
- **API Documentation**: http://localhost:5001/docs
- **Jenkins**: http://localhost:8080
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090

## Project Structure

```
ci-cd-rpi/
├── backend/                 # FastAPI backend application
├── frontend/                # Flutter Web frontend
├── prometheus/              # Prometheus configuration
├── grafana/                 # Grafana configuration
├── scripts/                 # Utility scripts
│   ├── deploy.sh           # Build and deploy applications
│   ├── backup.sh           # Backup all data
│   └── health-check.sh     # System health check
├── docker-compose.yaml      # Service orchestration
├── .env                     # Environment variables
├── README.md               # This file
└── blueprint.md            # Detailed setup guide
```

## Utility Scripts

### Deploy Applications
```bash
# Deploy backend only
./scripts/deploy.sh backend

# Deploy frontend only
./scripts/deploy.sh frontend

# Deploy both
./scripts/deploy.sh all
```

### Health Check
```bash
# Check status of all services
./scripts/health-check.sh
```

### Backup
```bash
# Backup all data and configurations
./scripts/backup.sh

# Backups are stored in /home/ritinder/backups/ci-cd-rpi/
```

## Development

### Backend Development
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 5001
```

See [backend/README.md](./backend/README.md) for details.

### Frontend Development
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

See [frontend/README.md](./frontend/README.md) for details.

## CI/CD Pipeline

### Jenkins Pipeline Workflow
1. **Checkout**: Pull code from GitHub
2. **Test**: Run unit tests (pytest for backend, flutter test for frontend)
3. **Build**: Build Docker image
4. **Tag**: Tag with build number and 'latest'
5. **Push**: Push to local registry
6. **Deploy**: Update and restart service via docker-compose
7. **Verify**: Health check to confirm deployment

### Setting Up Pipelines

#### 1. Add GitHub Credentials
- Jenkins → Manage Jenkins → Credentials
- Add Username with password
- Username: Your GitHub username
- Password: GitHub Personal Access Token
- ID: `github-credentials`

#### 2. Create Backend Pipeline
- New Item → Name: `backend-pipeline` → Pipeline
- Pipeline from SCM → Git
- Repository URL: Your GitHub repo
- Credentials: github-credentials
- Branch: */main
- Script Path: `backend/Jenkinsfile`
- Poll SCM: `H/5 * * * *` (every 5 minutes)

#### 3. Create Frontend Pipeline
- Same as above with Script Path: `frontend/Jenkinsfile`

## Monitoring

### Prometheus
- Access: http://localhost:9090
- Monitors: cAdvisor, Backend, Jenkins
- Retention: 15 days
- Scrape interval: 15 seconds

### Grafana
- Access: http://localhost:3000
- Default credentials: admin/admin123
- Datasource: Prometheus (auto-configured)
- Recommended dashboards:
  - Dashboard ID 193: Docker and system monitoring

### cAdvisor
- Access: http://localhost:8081
- Provides real-time container metrics
- Integrated with Prometheus

## Troubleshooting

### Services not starting
```bash
# Check service logs
podman logs <service-name>

# Examples:
podman logs jenkins
podman logs backend
podman logs web
```

### Registry connection issues
```bash
# Verify registry.lan is in /etc/hosts
grep registry.lan /etc/hosts

# Should output: 127.0.0.1 registry.lan

# Test registry
curl http://registry.lan:5000/v2/_catalog
```

### Jenkins can't build images
```bash
# Check Podman socket
ls -l /run/podman/podman.sock

# Start Podman socket if needed
systemctl --user start podman.socket
```

### Port 80 permission denied
```bash
# Run with sudo or change frontend port in docker-compose.yaml
# Example: Change "80:80" to "8080:80"
```

### High disk usage
```bash
# Clean up old images
podman system prune -a

# Check volume usage
podman volume ls
du -sh /var/lib/containers/storage/volumes/*
```

## Maintenance

### Daily
- Run health check: `./scripts/health-check.sh`
- Monitor Grafana dashboards

### Weekly
- Check Jenkins build history
- Review Prometheus metrics
- Clean up old Docker images

### Monthly
- Run backup: `./scripts/backup.sh`
- Update container images: `podman-compose pull && podman-compose up -d`
- Review and rotate logs

### Schedule Automated Backups
```bash
# Add to crontab
crontab -e

# Add this line (runs daily at 2 AM)
0 2 * * * /home/ritinder/developer/ci-cd-rpi/scripts/backup.sh
```

## Security Considerations

### Current Setup (Development)
- Insecure local registry (acceptable for local network)
- Basic authentication for Grafana and Jenkins
- No TLS/HTTPS

### Production Recommendations
1. Enable TLS for the registry
2. Add authentication to Docker registry
3. Use secrets management (HashiCorp Vault, etc.)
4. Enable Grafana OAuth or LDAP
5. Configure firewall rules
6. Use Tailscale for secure remote access
7. Regular security updates
8. Enable audit logging

### Remote Access with Tailscale
```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Connect to Tailscale network
sudo tailscale up

# Get your Tailscale IP
tailscale ip

# Access services remotely
# http://<tailscale-ip>:8080 (Jenkins)
# http://<tailscale-ip>:3000 (Grafana)
# http://<tailscale-ip>/ (Frontend)
```

## Performance Tips

### Raspberry Pi Optimization
- Use SSD instead of microSD for better I/O
- Enable active cooling
- Increase swap space for large builds
- Monitor temperature during builds
- Consider overclocking with proper cooling

### Container Optimization
- Limit container resources in docker-compose.yaml
- Use multi-stage Docker builds (already implemented)
- Clean up unused images regularly
- Monitor disk space

## Documentation

- [blueprint.md](./blueprint.md) - Complete architecture and detailed setup guide
- [backend/README.md](./backend/README.md) - Backend API documentation
- [frontend/README.md](./frontend/README.md) - Frontend app documentation
- [prometheus/README.md](./prometheus/README.md) - Monitoring guide

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT

## Support

For issues and questions:
1. Check [blueprint.md](./blueprint.md) troubleshooting section
2. Review service logs: `podman logs <service>`
3. Run health check: `./scripts/health-check.sh`
4. Check Prometheus targets: http://localhost:9090/targets

## Acknowledgments

- FastAPI for the excellent Python web framework
- Flutter for cross-platform UI development
- Prometheus and Grafana for monitoring
- Jenkins for CI/CD automation
- The Raspberry Pi community
