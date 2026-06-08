#!/bin/bash

# Script to build Docker images locally and push to Docker Hub
# Prerequisites:
#   - Docker installed and running
#   - Logged in to Docker Hub: docker login

set -e

# Configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-your-dockerhub-username}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=========================================="
echo "Docker Hub Build and Push Script"
echo "=========================================="
echo ""

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Error: Docker daemon is not running"
    echo "Please start Docker"
    exit 1
fi

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    echo "⚠️  Warning: You may not be logged in to Docker Hub"
    echo "Please run: docker login"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Prompt for Docker Hub username if not set
if [ "$DOCKER_USERNAME" = "your-dockerhub-username" ]; then
    echo "Docker Hub username not set."
    read -p "Enter your Docker Hub username: " DOCKER_USERNAME
    if [ -z "$DOCKER_USERNAME" ]; then
        echo "❌ Error: Docker Hub username is required"
        exit 1
    fi
fi

echo "✓ Docker is running"
echo "✓ Docker Hub username: $DOCKER_USERNAME"
echo "✓ Image tag: $IMAGE_TAG"
echo ""

# Confirm before proceeding
echo "This script will build and push the following images:"
echo "  - $DOCKER_USERNAME/library-books-api:$IMAGE_TAG"
echo "  - $DOCKER_USERNAME/library-users-api:$IMAGE_TAG"
echo "  - $DOCKER_USERNAME/library-web-ui:$IMAGE_TAG"
echo "  - $DOCKER_USERNAME/library-load-generator:$IMAGE_TAG"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "=========================================="
echo "Building and Pushing Images"
echo "=========================================="
echo ""

# Array of services
services=("books-api" "users-api" "web-ui" "load-generator")

# Build and push each service
for service in "${services[@]}"; do
    echo "=========================================="
    echo "Processing $service"
    echo "=========================================="
    
    # Set image name
    IMAGE_NAME="$DOCKER_USERNAME/library-$service:$IMAGE_TAG"
    
    echo "Building $IMAGE_NAME..."
    docker build -t $IMAGE_NAME ./$service
    
    if [ $? -eq 0 ]; then
        echo "✓ Build successful"
        echo ""
        
        echo "Pushing $IMAGE_NAME to Docker Hub..."
        docker push $IMAGE_NAME
        
        if [ $? -eq 0 ]; then
            echo "✓ Push successful"
        else
            echo "❌ Failed to push $IMAGE_NAME"
            exit 1
        fi
    else
        echo "❌ Failed to build $IMAGE_NAME"
        exit 1
    fi
    
    echo ""
done

echo "=========================================="
echo "✅ All Images Built and Pushed!"
echo "=========================================="
echo ""
echo "Images pushed to Docker Hub:"
for service in "${services[@]}"; do
    echo "  ✓ $DOCKER_USERNAME/library-$service:$IMAGE_TAG"
done
echo ""
echo "To pull these images:"
for service in "${services[@]}"; do
    echo "  docker pull $DOCKER_USERNAME/library-$service:$IMAGE_TAG"
done
echo ""
echo "To use in Kubernetes/OpenShift, update image references to:"
for service in "${services[@]}"; do
    echo "  image: $DOCKER_USERNAME/library-$service:$IMAGE_TAG"
done
echo ""

# Made with Bob