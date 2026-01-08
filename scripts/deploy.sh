#!/bin/bash
set -e

SERVICE=$1

if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <backend|frontend|all>"
    echo ""
    echo "Examples:"
    echo "  $0 backend   - Deploy only backend"
    echo "  $0 frontend  - Deploy only frontend"
    echo "  $0 all       - Deploy both backend and frontend"
    exit 1
fi

# Get project directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$PROJECT_DIR"

REGISTRY="registry.lan:5000"
BUILD_NUMBER=$(date +%Y%m%d%H%M%S)

# Determine which compose command to use
if command -v podman-compose >/dev/null 2>&1; then
    COMPOSE_CMD="podman-compose"
    DOCKER_CMD="podman"
else
    COMPOSE_CMD="docker-compose"
    DOCKER_CMD="docker"
fi

deploy_backend() {
    echo "===================================="
    echo "Deploying Backend"
    echo "===================================="
    echo ""

    # Build image
    echo "Building backend image..."
    cd backend
    $DOCKER_CMD build -t ${REGISTRY}/backend:${BUILD_NUMBER} .
    $DOCKER_CMD tag ${REGISTRY}/backend:${BUILD_NUMBER} ${REGISTRY}/backend:latest

    # Push to registry
    echo ""
    echo "Pushing to registry..."
    $DOCKER_CMD push ${REGISTRY}/backend:${BUILD_NUMBER}
    $DOCKER_CMD push ${REGISTRY}/backend:latest

    # Deploy
    echo ""
    echo "Deploying backend service..."
    cd ..
    $COMPOSE_CMD pull backend
    $COMPOSE_CMD up -d backend

    # Verify
    echo ""
    echo "Verifying deployment..."
    sleep 5

    if curl -sf http://localhost:5001/health > /dev/null 2>&1; then
        echo "✅ Backend health check passed!"
    else
        echo "❌ Backend health check failed!"
        echo "Check logs with: podman logs backend"
        exit 1
    fi

    echo ""
    echo "Backend deployed successfully!"
    echo "Build: $BUILD_NUMBER"
    echo "Image: ${REGISTRY}/backend:$BUILD_NUMBER"
}

deploy_frontend() {
    echo "===================================="
    echo "Deploying Frontend"
    echo "===================================="
    echo ""

    # Build image
    echo "Building frontend image..."
    echo "Note: This may take several minutes..."
    cd frontend
    $DOCKER_CMD build -t ${REGISTRY}/web:${BUILD_NUMBER} .
    $DOCKER_CMD tag ${REGISTRY}/web:${BUILD_NUMBER} ${REGISTRY}/web:latest

    # Push to registry
    echo ""
    echo "Pushing to registry..."
    $DOCKER_CMD push ${REGISTRY}/web:${BUILD_NUMBER}
    $DOCKER_CMD push ${REGISTRY}/web:latest

    # Deploy
    echo ""
    echo "Deploying frontend service..."
    cd ..
    $COMPOSE_CMD pull web
    $COMPOSE_CMD up -d web

    # Verify
    echo ""
    echo "Verifying deployment..."
    sleep 5

    if curl -sf http://localhost/ > /dev/null 2>&1; then
        echo "✅ Frontend health check passed!"
    else
        echo "❌ Frontend health check failed!"
        echo "Check logs with: podman logs web"
        exit 1
    fi

    # Test API proxy
    if curl -sf http://localhost/api/v1/hello > /dev/null 2>&1; then
        echo "✅ API proxy is working!"
    else
        echo "⚠️  API proxy test failed"
    fi

    echo ""
    echo "Frontend deployed successfully!"
    echo "Build: $BUILD_NUMBER"
    echo "Image: ${REGISTRY}/web:$BUILD_NUMBER"
    echo "Access at: http://localhost/"
}

case $SERVICE in
    backend)
        deploy_backend
        ;;
    frontend)
        deploy_frontend
        ;;
    all)
        deploy_backend
        echo ""
        deploy_frontend
        ;;
    *)
        echo "Unknown service: $SERVICE"
        echo "Usage: $0 <backend|frontend|all>"
        exit 1
        ;;
esac

echo ""
echo "===================================="
echo "Deployment Complete!"
echo "===================================="
echo ""
echo "Build Number: $BUILD_NUMBER"
echo ""
echo "Services:"
echo "  Backend:  http://localhost:5001"
echo "  Frontend: http://localhost/"
echo "  API Docs: http://localhost:5001/docs"
echo ""
