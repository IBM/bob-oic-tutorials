#!/bin/bash

# Deployment script for Library System using Docker Hub images
# This script deploys the application using pre-built images from Docker Hub

set -e

NAMESPACE="library-system"
DOCKER_USERNAME="${DOCKER_USERNAME:-dikamath}"
IMAGE_TAG="${IMAGE_TAG:-v1.0.2}"

echo "=========================================="
echo "Library System Deployment (Docker Hub)"
echo "=========================================="
echo ""

# Check prerequisites
if ! command -v oc &> /dev/null; then
    echo "❌ Error: oc CLI is not installed"
    exit 1
fi

if ! oc whoami &> /dev/null; then
    echo "❌ Error: Not logged in to OpenShift"
    exit 1
fi

echo "✓ Logged in as: $(oc whoami)"
echo "✓ Docker Hub username: $DOCKER_USERNAME"
echo "✓ Image tag: $IMAGE_TAG"
echo ""

# Step 1: Create namespace
echo "Step 1: Creating namespace..."
oc new-project $NAMESPACE 2>/dev/null || oc project $NAMESPACE
echo "✓ Namespace ready"
echo ""

# Step 2: Verify images are accessible
echo "Step 2: Verifying Docker Hub images..."
echo "Images to be used:"
echo "  - $DOCKER_USERNAME/library-books-api:$IMAGE_TAG"
echo "  - $DOCKER_USERNAME/library-users-api:$IMAGE_TAG"
echo "  - $DOCKER_USERNAME/library-web-ui:$IMAGE_TAG"
echo "  - $DOCKER_USERNAME/library-load-generator:$IMAGE_TAG"
echo ""

read -p "Are these images available on Docker Hub? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please build and push images first using:"
    echo "  cd library-system"
    echo "  ./build-and-push-dockerhub.sh"
    exit 1
fi

# Step 3: Deploy all resources
echo ""
echo "Step 3: Deploying all resources..."
oc apply -f k8s-manifests/all-in-one.yaml
echo "✓ Resources deployed"
echo ""

# Step 4: Wait for MongoDB
echo "Step 4: Waiting for MongoDB to be ready..."
sleep 10
oc wait --for=condition=available --timeout=180s deployment/mongodb -n $NAMESPACE || true
echo "✓ MongoDB ready"
echo ""

# Step 5: Wait for application services
echo "Step 5: Waiting for application services to be ready..."
sleep 10

for service in books-api users-api web-ui; do
    echo "Waiting for $service..."
    oc rollout status deployment/$service -n $NAMESPACE --timeout=3m || true
done

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""

# Get the route
ROUTE=$(oc get route web-ui -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null)

echo "📚 Library System is ready!"
echo ""
echo "Access the application:"
echo "  http://$ROUTE"
echo ""
echo "Check pod status:"
echo "  oc get pods -n $NAMESPACE"
echo ""
echo "View logs:"
echo "  oc logs -f deployment/web-ui -n $NAMESPACE"
echo "  oc logs -f deployment/books-api -n $NAMESPACE"
echo "  oc logs -f deployment/users-api -n $NAMESPACE"
echo ""
echo "Start load generator:"
echo "  oc scale deployment/load-generator --replicas=1 -n $NAMESPACE"
echo ""
echo "Generate traffic and verify Instana:"
echo "  ./generate-traffic.sh"
echo ""
echo "Add latency for testing:"
echo "  ./add-latency.sh"
echo ""
echo "Images used:"
echo "  ✓ $DOCKER_USERNAME/library-books-api:$IMAGE_TAG"
echo "  ✓ $DOCKER_USERNAME/library-users-api:$IMAGE_TAG"
echo "  ✓ $DOCKER_USERNAME/library-web-ui:$IMAGE_TAG"
echo "  ✓ $DOCKER_USERNAME/library-load-generator:$IMAGE_TAG"
echo ""

# Made with Bob