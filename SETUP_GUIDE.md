# Complete Setup Guide - CI/CD Platform on Raspberry Pi 5

This guide provides step-by-step manual instructions for setting up the CI/CD and monitoring platform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial System Setup](#initial-system-setup)
3. [Network Configuration](#network-configuration)
4. [Starting Services](#starting-services)
5. [Jenkins Configuration](#jenkins-configuration)
6. [GitHub Integration](#github-integration)
7. [Building Applications](#building-applications)
8. [Grafana Setup](#grafana-setup)
9. [Jenkins Pipelines](#jenkins-pipelines)
10. [Verification](#verification)
11. [Daily Operations](#daily-operations)
12. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware
- Raspberry Pi 5 (8GB RAM recommended)
- 128GB+ microSD card or SSD (SSD strongly recommended)
- Active cooling (fan or heat sink)
- Ethernet cable for stable connection
- Official Raspberry Pi 5 power supply

### Software
- Raspberry Pi OS (64-bit) - Latest version
- Internet connection
- SSH access (if configuring remotely)

---

## Initial System Setup

### Step 1: Update System

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Reboot to apply updates
sudo reboot
```

Wait for the Pi to reboot, then reconnect.

### Step 2: Install Required Software

```bash
# Install Podman (container runtime)
sudo apt install -y podman

# Install podman-compose (orchestration tool)
sudo apt install -y podman-compose

# Install Git (version control)
sudo apt install -y git

# Install useful utilities
sudo apt install -y curl wget vim htop
```

### Step 3: Verify Installations

```bash
# Check Podman version
podman --version
# Expected: podman version 4.9.3 or higher

# Check podman-compose version
podman-compose --version
# Expected: podman-compose version 1.0.0 or higher

# Check Git version
git --version
# Expected: git version 2.30 or higher
```

### Step 4: Navigate to Project Directory

```bash
# Go to the project directory
cd /home/ritinder/developer/ci-cd-rpi

# List contents to verify files
ls -la
```

You should see:
- docker-compose.yaml
- backend/
- frontend/
- scripts/
- prometheus/
- grafana/

---

## Network Configuration

### Step 1: Add Registry Hostname

The local Docker registry needs to be accessible at `registry.lan:5000`.

```bash
# Add registry.lan to /etc/hosts
echo "127.0.0.1 registry.lan" | sudo tee -a /etc/hosts

# Verify it was added
grep registry.lan /etc/hosts
```

Expected output:
```
127.0.0.1 registry.lan
```

### Step 2: Configure Podman for Insecure Registry

Since our local registry uses HTTP (not HTTPS), we need to configure Podman to allow insecure connections.

```bash
# Create configuration directory
sudo mkdir -p /etc/containers/registries.conf.d/

# Create registry configuration file
cat | sudo tee /etc/containers/registries.conf.d/local-registry.conf << 'EOF'
[[registry]]
location = "registry.lan:5000"
insecure = true
EOF
```

### Step 3: Configure Podman Socket

Jenkins needs access to the Podman socket to build Docker images.

```bash
# Enable Podman socket for current user
systemctl --user enable --now podman.socket

# Verify socket exists
ls -l /run/podman/podman.sock
```

If the user service fails, try system-wide:

```bash
sudo systemctl enable --now podman.socket
```

Verify the socket is running:

```bash
systemctl status podman.socket
# or
sudo systemctl status podman.socket
```

---

## Starting Services

### Step 1: Start Docker Registry

The registry must start first as other services depend on it.

```bash
cd /home/ritinder/developer/ci-cd-rpi

# Start the registry service
podman-compose up -d registry

# Wait for it to initialize
sleep 5

# Verify registry is running
curl http://registry.lan:5000/v2/_catalog
```

Expected output:
```json
{"repositories":[]}
```

### Step 2: Start Monitoring Services

```bash
# Start Prometheus, Grafana, and cAdvisor
podman-compose up -d prometheus grafana cadvisor

# Check services are running
podman ps
```

You should see three new containers:
- prometheus
- grafana
- cadvisor

### Step 3: Start Jenkins

```bash
# Start Jenkins
podman-compose up -d jenkins

# Jenkins takes time to initialize
echo "Waiting for Jenkins to start..."
sleep 30
```

### Step 4: Verify All Services

```bash
# Check all containers
podman ps

# You should see 5 containers running:
# - jenkins
# - registry
# - prometheus
# - grafana
# - cadvisor
```

If any container is missing, check logs:

```bash
podman logs <container-name>
```

---

## Jenkins Configuration

### Step 1: Get Initial Password

```bash
# Extract Jenkins initial admin password
podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Copy this password - you'll need it in the next step.

Example output:
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

### Step 2: Access Jenkins Web Interface

1. Open a web browser
2. Navigate to:
   - If on the Pi: `http://localhost:8080/jenkins`
   - From another computer: `http://YOUR_PI_IP:8080/jenkins`
     (Find Pi IP with: `hostname -I`)

### Step 3: Complete Setup Wizard

**Getting Started**:
1. Paste the initial admin password
2. Click "Continue"

**Customize Jenkins**:
1. Click "Install suggested plugins"
2. Wait for plugins to install (3-5 minutes)

**Create First Admin User**:
1. Username: `admin` (or your choice)
2. Password: Choose a strong password **and save it**
3. Full name: Your name
4. Email: Your email address
5. Click "Save and Continue"

**Instance Configuration**:
1. Jenkins URL: Leave as default or set to `http://YOUR_PI_IP:8080/jenkins`
2. Click "Save and Finish"

**Start Using Jenkins**:
1. Click "Start using Jenkins"

### Step 4: Install Additional Plugins

From Jenkins Dashboard:

1. Click "Manage Jenkins"
2. Click "Plugins"
3. Click "Available plugins" tab
4. Search for "Prometheus metrics"
5. Check the box next to "Prometheus metrics plugin"
6. Click "Install"
7. Wait for installation to complete

**Verify existing plugins**:
1. Click "Installed plugins" tab
2. Verify these are installed:
   - Git plugin ✓
   - Pipeline ✓
   - Docker Pipeline ✓
   - GitHub ✓

If any are missing, install them from "Available plugins".

---

## GitHub Integration

### Step 1: Generate Personal Access Token

1. Go to https://github.com
2. Click your profile picture → Settings
3. Scroll down to "Developer settings"
4. Click "Personal access tokens" → "Tokens (classic)"
5. Click "Generate new token (classic)"
6. Configure token:
   - Note: "Raspberry Pi Jenkins"
   - Expiration: 90 days (or longer)
   - Select scopes:
     - ✅ repo (check all sub-options)
7. Click "Generate token"
8. **IMPORTANT**: Copy the token immediately
   - Format: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - Save it in a secure location

### Step 2: Add Credentials to Jenkins

From Jenkins Dashboard:

1. Click "Manage Jenkins"
2. Click "Credentials"
3. Click "(global)" under "Stores scoped to Jenkins"
4. Click "Add Credentials"
5. Fill in the form:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: Your GitHub username
   - **Password**: Paste the Personal Access Token (ghp_...)
   - **ID**: `github-credentials`
   - **Description**: GitHub Access Token
6. Click "Create"

**Verify**:
- You should see "github-credentials" in the credentials list

---

## Building Applications

### Step 1: Deploy Backend

```bash
cd /home/ritinder/developer/ci-cd-rpi

# Make sure script is executable
chmod +x scripts/deploy.sh

# Deploy backend
./scripts/deploy.sh backend
```

**What happens**:
1. Builds FastAPI backend Docker image
2. Tags image as `registry.lan:5000/backend:TIMESTAMP`
3. Pushes to local registry
4. Deploys via docker-compose
5. Verifies health check

**Expected output** (last few lines):
```
✅ Backend health check passed!
Backend deployed successfully!
Build: 20260108123456
```

**Time**: ~3-5 minutes

### Step 2: Deploy Frontend

```bash
# Deploy frontend
./scripts/deploy.sh frontend
```

**What happens**:
1. Builds Flutter web app inside Docker
2. Creates Nginx container to serve it
3. Pushes to local registry
4. Deploys via docker-compose
5. Verifies frontend and API proxy

**Expected output** (last few lines):
```
✅ Frontend health check passed!
✅ API proxy is working!
Frontend deployed successfully!
```

**Time**: ~5-10 minutes (first build is slower)

### Step 3: Verify Deployments

```bash
# Run health check
./scripts/health-check.sh
```

**Expected output**:
All services should show ✅ Healthy:
- ✅ Container backend: Running
- ✅ Container web: Running
- ✅ Backend: Healthy
- ✅ Frontend: Healthy

### Step 4: Test Applications

**Test Backend**:
```bash
# Health check
curl http://localhost:5001/health

# Hello endpoint
curl http://localhost:5001/api/v1/hello

# System info
curl http://localhost:5001/api/v1/info
```

**Test Frontend**:
```bash
# Access frontend
curl http://localhost/
```

**Test in Browser**:
1. Open browser to `http://localhost/`
2. You should see a dashboard with:
   - ✓ Green checkmark icon
   - "Hello from Raspberry Pi CI/CD Platform!"
   - System Information card showing:
     - CPU Usage: XX%
     - Memory Usage: XX%
     - Disk Usage: XX%
     - Environment: production
   - Refresh button

---

## Grafana Setup

### Step 1: Access Grafana

1. Open browser to: `http://localhost:3000`
2. Login:
   - Username: `admin`
   - Password: `admin123`
3. You'll be prompted to change password
   - Enter new password
   - Confirm password
   - Click "Submit"

### Step 2: Verify Prometheus Datasource

The Prometheus datasource should be auto-configured.

1. Click the gear icon (⚙️) on the left sidebar
2. Click "Data sources"
3. You should see "Prometheus" in the list
4. Click "Prometheus"
5. Scroll down and click "Test"
6. Should show: ✓ "Data source is working"

If not configured:

1. Click "Add data source"
2. Select "Prometheus"
3. Configure:
   - Name: `Prometheus`
   - URL: `http://prometheus:9090`
   - Access: `Server (default)`
4. Click "Save & test"

### Step 3: Import Docker Monitoring Dashboard

1. Click the dashboard icon (☷) on the left sidebar
2. Click "Import"
3. Enter Dashboard ID: `193`
4. Click "Load"
5. Configure:
   - Select datasource: **Prometheus**
   - Click "Import"

You should now see a dashboard with container metrics:
- CPU usage per container
- Memory usage per container
- Network I/O
- Disk I/O

### Step 4: Explore Metrics

Try these queries in the "Explore" section:

1. Click the compass icon (🧭) on the left sidebar
2. Enter query:
   ```promql
   up
   ```
3. Click "Run query"
4. Should show all services = 1 (up)

Other useful queries:
```promql
# Container CPU usage
rate(container_cpu_usage_seconds_total[5m]) * 100

# Container memory usage
container_memory_usage_bytes

# HTTP requests to backend
rate(http_requests_total[5m])
```

---

## Jenkins Pipelines

### Step 1: Create Backend Pipeline

From Jenkins Dashboard:

1. Click "New Item"
2. Enter name: `backend-pipeline`
3. Select "Pipeline"
4. Click "OK"

**Configure Pipeline**:

**General** section:
- Check ✅ "GitHub project"
- Project URL: `https://github.com/YOUR_USERNAME/YOUR_REPO`

**Build Triggers** section:
- Check ✅ "Poll SCM"
- Schedule: `H/5 * * * *`
  (This polls GitHub every 5 minutes)

**Pipeline** section:
- Definition: Select "Pipeline script from SCM"
- SCM: Select "Git"
- Repository URL: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
- Credentials: Select "github-credentials"
- Branch Specifier: `*/main` (or your default branch)
- Script Path: `backend/Jenkinsfile`

**Click "Save"**

### Step 2: Create Frontend Pipeline

Repeat the above process with these changes:
- Name: `frontend-pipeline`
- Script Path: `frontend/Jenkinsfile`
- Everything else the same

### Step 3: Test Backend Pipeline

From Jenkins Dashboard:

1. Click on "backend-pipeline"
2. Click "Build Now" in the left sidebar
3. Click on the build number (e.g., "#1") that appears
4. Click "Console Output" to watch progress

**Pipeline stages**:
1. Checkout - Pulls code from GitHub
2. Test - Runs pytest tests
3. Build Image - Builds Docker image
4. Push to Registry - Pushes to registry.lan:5000
5. Deploy - Updates container
6. Verify - Checks health endpoint

**Expected duration**: 3-5 minutes

**Success indicators**:
- Blue ball next to build number
- "✅ Backend deployment successful!"
- "Finished: SUCCESS"

### Step 4: Test Frontend Pipeline

From Jenkins Dashboard:

1. Click on "frontend-pipeline"
2. Click "Build Now"
3. Click on build number
4. Click "Console Output"

**Expected duration**: 5-10 minutes (first build)

**Success indicators**:
- Blue ball next to build number
- "✅ Frontend deployment successful!"
- "Finished: SUCCESS"

---

## Verification

### Full System Verification

Run the comprehensive health check:

```bash
cd /home/ritinder/developer/ci-cd-rpi
./scripts/health-check.sh
```

Expected output shows all green checkmarks:

```
====================================
CI/CD Platform Health Check
====================================

Container Status:
-----------------------------------
✅ Container jenkins: Running
✅ Container registry: Running
✅ Container backend: Running
✅ Container web: Running
✅ Container cadvisor: Running
✅ Container prometheus: Running
✅ Container grafana: Running

Service Health:
-----------------------------------
✅ Jenkins: Healthy
✅ Registry: Healthy
✅ Backend: Healthy
✅ Frontend: Healthy
✅ cAdvisor: Healthy
✅ Prometheus: Healthy
✅ Grafana: Healthy

System Resources:
-----------------------------------
CPU Usage: 25.3%
Memory Usage: 45.2%
Disk Usage: 35%
CPU Temperature: 45.2°C
```

### Test CI/CD End-to-End

**Make a code change**:

```bash
cd /home/ritinder/developer/ci-cd-rpi

# Edit backend message
nano backend/app/main.py
```

Find this line:
```python
"message": "Hello from Raspberry Pi CI/CD Platform!",
```

Change to:
```python
"message": "Hello from Raspberry Pi - CI/CD is working!",
```

Save and exit (Ctrl+X, Y, Enter)

**Commit and push**:

```bash
# Add the file
git add backend/app/main.py

# Commit
git commit -m "Test CI/CD pipeline"

# Push to GitHub
git push origin main
```

**Watch Jenkins**:

1. Wait up to 5 minutes for Jenkins to poll
2. Jenkins Dashboard should show "backend-pipeline" building
3. Build should:
   - Pull new code
   - Run tests
   - Build image
   - Deploy
   - Verify

**Verify change**:

```bash
curl http://localhost:5001/api/v1/hello
```

Should show:
```json
{
  "message": "Hello from Raspberry Pi - CI/CD is working!",
  "version": "1.0.0",
  "timestamp": "2026-01-08T..."
}
```

---

## Daily Operations

### Check System Health

```bash
cd /home/ritinder/developer/ci-cd-rpi
./scripts/health-check.sh
```

Run this daily or whenever you notice issues.

### View Service Logs

```bash
# View logs for specific service
podman logs backend

# Follow logs in real-time
podman logs -f backend

# View last 100 lines
podman logs --tail 100 jenkins

# View logs for multiple services
podman logs web
podman logs prometheus
```

### Restart a Service

```bash
# Restart single service
podman-compose restart backend

# Restart all services
podman-compose restart

# Stop all services
podman-compose stop

# Start all services
podman-compose start
```

### Check Prometheus Targets

1. Open browser to: `http://localhost:9090`
2. Click "Status" → "Targets"
3. Verify all targets show "UP"

If any target is "DOWN", check the service logs.

### View Grafana Dashboards

1. Open browser to: `http://localhost:3000`
2. Click dashboard icon (☷)
3. Select "Docker monitoring"
4. View real-time metrics

### Monitor Jenkins Builds

1. Open browser to: `http://localhost:8080`
2. View build history for each pipeline
3. Check for failed builds (red balls)
4. Review console output for failures

### Backup Data

```bash
cd /home/ritinder/developer/ci-cd-rpi
./scripts/backup.sh
```

**Schedule automatic backups**:

```bash
# Edit crontab
crontab -e

# Add this line to run daily at 2 AM
0 2 * * * /home/ritinder/developer/ci-cd-rpi/scripts/backup.sh
```

---

## Troubleshooting

### Problem: Jenkins Can't Build Images

**Symptoms**:
- Build fails with "docker: command not found"
- Build fails with "Cannot connect to Docker daemon"

**Solutions**:

1. Check Podman socket exists:
```bash
ls -l /run/podman/podman.sock
```

2. If not, start it:
```bash
systemctl --user start podman.socket
# or
sudo systemctl start podman.socket
```

3. Verify Jenkins can access it:
```bash
podman exec jenkins ls -l /var/run/docker.sock
```

4. Restart Jenkins:
```bash
podman-compose restart jenkins
```

---

### Problem: Registry Connection Refused

**Symptoms**:
- "connection refused" to registry.lan:5000
- Cannot push/pull images

**Solutions**:

1. Check /etc/hosts:
```bash
grep registry.lan /etc/hosts
```
Should show: `127.0.0.1 registry.lan`

2. Check registry is running:
```bash
podman ps | grep registry
```

3. Test registry:
```bash
curl http://registry.lan:5000/v2/_catalog
```

4. Verify Podman config:
```bash
cat /etc/containers/registries.conf.d/local-registry.conf
```

---

### Problem: Backend/Frontend Not Accessible

**Symptoms**:
- "Connection refused" to localhost:5001 or localhost:80
- Health check fails

**Solutions**:

1. Check containers are running:
```bash
podman ps
```

2. Check logs:
```bash
podman logs backend
podman logs web
```

3. Test health endpoints:
```bash
curl http://localhost:5001/health
curl http://localhost/
```

4. Restart services:
```bash
podman-compose restart backend web
```

---

### Problem: Prometheus Shows "No Data"

**Symptoms**:
- Grafana shows "No data"
- Empty graphs

**Solutions**:

1. Check Prometheus targets:
   - Open `http://localhost:9090/targets`
   - All should show "UP"

2. Check Prometheus logs:
```bash
podman logs prometheus
```

3. Verify scrape config:
```bash
cat prometheus/prometheus.yml
```

4. Restart Prometheus:
```bash
podman-compose restart prometheus
```

---

### Problem: High Disk Usage

**Symptoms**:
- "No space left on device"
- Slow performance

**Solutions**:

1. Check disk usage:
```bash
df -h
```

2. Check container storage:
```bash
podman system df
```

3. Clean up:
```bash
# Remove unused images
podman system prune -a

# Remove stopped containers
podman container prune

# Remove unused volumes
podman volume prune
```

4. In Jenkins UI:
   - Manage Jenkins → Disk Usage
   - Delete old builds

---

### Problem: Services Won't Start

**Symptoms**:
- `podman-compose up` fails
- Container immediately exits

**Solutions**:

1. Check logs:
```bash
podman-compose logs <service-name>
```

2. Check docker-compose.yaml:
```bash
podman-compose config
```

3. Restart all services:
```bash
podman-compose down
podman-compose up -d
```

4. Check system resources:
```bash
free -h  # Memory
df -h    # Disk
```

---

## Next Steps

Once everything is working:

1. **Customize Applications**:
   - Modify backend API endpoints
   - Update frontend UI
   - Add your own features

2. **Set Up Automated Backups**:
   ```bash
   crontab -e
   # Add: 0 2 * * * /path/to/scripts/backup.sh
   ```

3. **Add More Dashboards**:
   - Create custom Grafana dashboards
   - Import additional dashboard templates

4. **Secure for Production** (if needed):
   - Enable HTTPS
   - Add authentication to registry
   - Change default passwords
   - Set up firewall rules

5. **Add Tailscale** (for remote access):
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```

6. **Monitor Performance**:
   - Watch Grafana dashboards regularly
   - Review Jenkins build trends
   - Monitor system temperature

---

## Quick Reference

### Service URLs

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Frontend | http://localhost/ | None |
| Backend API | http://localhost:5001 | None |
| API Docs | http://localhost:5001/docs | None |
| Jenkins | http://localhost:8080 | (Set during setup) |
| Grafana | http://localhost:3000 | admin/admin123 |
| Prometheus | http://localhost:9090 | None |
| cAdvisor | http://localhost:8081 | None |
| Registry | http://registry.lan:5000 | None |

### Common Commands

```bash
# Health check
./scripts/health-check.sh

# Deploy applications
./scripts/deploy.sh backend
./scripts/deploy.sh frontend
./scripts/deploy.sh all

# Backup
./scripts/backup.sh

# View logs
podman logs backend
podman logs -f web

# Restart services
podman-compose restart backend
podman-compose restart

# Stop all
podman-compose down

# Start all
podman-compose up -d

# Clean up
podman system prune -a
```

### File Locations

- Project: `/home/ritinder/developer/ci-cd-rpi`
- Backups: `/home/ritinder/backups/ci-cd-rpi/`
- Logs: `podman logs <service>`
- Config: `docker-compose.yaml`, `.env`

---

## Summary

You've now completed the setup of a full CI/CD and monitoring platform on your Raspberry Pi 5!

**What you have**:
- ✅ Automated CI/CD with Jenkins
- ✅ FastAPI backend with metrics
- ✅ Flutter web frontend
- ✅ Comprehensive monitoring
- ✅ Local Docker registry
- ✅ Automated deployments
- ✅ Health monitoring

**What happens automatically**:
- Jenkins polls GitHub every 5 minutes
- Detects code changes
- Runs tests
- Builds Docker images
- Deploys to containers
- Monitors health

Enjoy your new platform! 🎉
