#!/bin/bash
set -e

echo "===================================="
echo "CI/CD Platform Setup for Raspberry Pi"
echo "===================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."
command -v podman >/dev/null 2>&1 || { echo "Error: Podman not installed. Please install podman first."; exit 1; }
command -v podman-compose >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1 || { echo "Error: podman-compose or docker-compose not installed"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Error: git not installed. Please install git first."; exit 1; }

echo "✓ Podman: $(podman --version)"
if command -v podman-compose >/dev/null 2>&1; then
    echo "✓ podman-compose: $(podman-compose --version)"
else
    echo "✓ docker-compose: $(docker-compose --version)"
fi
echo "✓ Git: $(git --version)"
echo ""

# Check if running on Raspberry Pi (optional warning)
if [ -f /proc/device-tree/model ]; then
    MODEL=$(cat /proc/device-tree/model)
    echo "Detected device: $MODEL"
    if [[ ! $MODEL =~ "Raspberry Pi" ]]; then
        echo "Warning: Not running on Raspberry Pi"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi
echo ""

# Get project directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$PROJECT_DIR"
echo "Project directory: $PROJECT_DIR"
echo ""

# Add registry.lan to /etc/hosts
echo "Configuring registry.lan..."
if ! grep -q "registry.lan" /etc/hosts; then
    echo "Adding registry.lan to /etc/hosts (requires sudo)..."
    echo "127.0.0.1 registry.lan" | sudo tee -a /etc/hosts > /dev/null
    echo "✓ Added registry.lan to /etc/hosts"
else
    echo "✓ registry.lan already in /etc/hosts"
fi
echo ""

# Configure Podman for insecure registry
echo "Configuring Podman for local registry..."
sudo mkdir -p /etc/containers/registries.conf.d/
if [ ! -f /etc/containers/registries.conf.d/local-registry.conf ]; then
    cat | sudo tee /etc/containers/registries.conf.d/local-registry.conf > /dev/null << 'EOF'
[[registry]]
location = "registry.lan:5000"
insecure = true
EOF
    echo "✓ Created Podman registry configuration"
else
    echo "✓ Podman registry configuration already exists"
fi
echo ""

# Verify Podman socket exists
echo "Verifying Podman socket..."
if [ ! -S /run/podman/podman.sock ]; then
    echo "Warning: Podman socket not found at /run/podman/podman.sock"
    echo "Starting Podman socket service..."
    systemctl --user enable --now podman.socket || sudo systemctl enable --now podman.socket
    sleep 2
fi

if [ -S /run/podman/podman.sock ]; then
    echo "✓ Podman socket available"
else
    echo "Warning: Podman socket still not available. Jenkins may not be able to build images."
    echo "You may need to run: systemctl --user start podman.socket"
fi
echo ""

# Create prometheus config directory if it doesn't exist
echo "Creating configuration directories..."
mkdir -p prometheus grafana/provisioning/datasources
echo "✓ Configuration directories created"
echo ""

# Check if prometheus.yml exists
if [ ! -f prometheus/prometheus.yml ]; then
    echo "Warning: prometheus/prometheus.yml not found. Please create it before starting services."
    echo "You can continue, but Prometheus will fail to start without this file."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Start infrastructure services
echo "Starting infrastructure services..."
echo "This may take a few minutes on first run (pulling images)..."
echo ""

# Determine which compose command to use
if command -v podman-compose >/dev/null 2>&1; then
    COMPOSE_CMD="podman-compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Start registry first
echo "Starting Docker Registry..."
$COMPOSE_CMD up -d registry
sleep 5

# Verify registry
echo "Verifying Docker Registry..."
if curl -sf http://registry.lan:5000/v2/_catalog > /dev/null 2>&1; then
    echo "✓ Registry is running and accessible"
else
    echo "✗ Registry health check failed"
    echo "  Try: curl http://registry.lan:5000/v2/_catalog"
fi
echo ""

# Start monitoring services
echo "Starting monitoring services (Prometheus, Grafana, cAdvisor)..."
$COMPOSE_CMD up -d prometheus grafana cadvisor

# Wait for services
echo "Waiting for services to be ready..."
sleep 10
echo ""

# Start Jenkins
echo "Starting Jenkins..."
$COMPOSE_CMD up -d jenkins
echo "Jenkins is starting (this may take 1-2 minutes)..."
echo ""

# Show service status
echo "Checking service status..."
$COMPOSE_CMD ps
echo ""

# Get Jenkins initial password
echo "Waiting for Jenkins to initialize..."
sleep 15

if podman ps | grep -q jenkins; then
    echo "Getting Jenkins initial admin password..."
    JENKINS_PASSWORD=$(podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Not yet available")
    if [ "$JENKINS_PASSWORD" != "Not yet available" ]; then
        echo ""
        echo "===================================="
        echo "Jenkins Initial Admin Password:"
        echo "$JENKINS_PASSWORD"
        echo "===================================="
        echo ""
        echo "IMPORTANT: Save this password! You'll need it for initial setup."
    else
        echo "Jenkins is still initializing. Get the password later with:"
        echo "  podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
    fi
fi
echo ""

echo "===================================="
echo "Setup Complete!"
echo "===================================="
echo ""
echo "Services are now running:"
echo ""
echo "  Jenkins:    http://localhost:8080"
echo "              (or http://$(hostname -I | awk '{print $1}'):8080)"
echo ""
echo "  Grafana:    http://localhost:3000"
echo "              Default credentials: admin/admin123"
echo ""
echo "  Prometheus: http://localhost:9090"
echo ""
echo "  cAdvisor:   http://localhost:8081"
echo ""
echo "  Registry:   http://registry.lan:5000"
echo ""
echo "Next steps:"
echo ""
echo "1. Complete Jenkins setup:"
echo "   - Open http://localhost:8080"
echo "   - Enter the admin password shown above"
echo "   - Install suggested plugins"
echo "   - Create admin user"
echo ""
echo "2. Configure Grafana:"
echo "   - Open http://localhost:3000"
echo "   - Login with admin/admin123"
echo "   - Import dashboard (ID: 193 for Docker monitoring)"
echo ""
echo "3. Build and deploy applications:"
echo "   - Backend:  cd backend && podman build -t registry.lan:5000/backend:latest ."
echo "   - Frontend: cd frontend && podman build -t registry.lan:5000/web:latest ."
echo "   - Or use:   ./scripts/deploy.sh all"
echo ""
echo "4. Set up Jenkins pipelines:"
echo "   - Add GitHub credentials in Jenkins"
echo "   - Create backend-pipeline job"
echo "   - Create frontend-pipeline job"
echo ""
echo "For more details, see README.md and blueprint.md"
echo ""
echo "===================================="
