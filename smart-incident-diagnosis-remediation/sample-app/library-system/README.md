# Library System - Build and Deployment Guide

## Overview

This guide explains how to build Docker images and deploy the Library System application to OpenShift using Docker Hub as the container registry.

## Prerequisites

### Required Tools

1. **OpenShift CLI (oc)**
   - Install: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html
   - Verify: `oc version`

2. **Docker (for local builds)**
   - Install: https://docs.docker.com/get-docker/
   - Verify: `docker --version`

3. **Docker Hub Account**
   - Sign up: https://hub.docker.com/signup
   - Free tier is sufficient

4. **OpenShift Cluster Access**
   - Must be logged in: `oc login`
   - Verify: `oc whoami`

---

## Quick Start

### Step 1: Build and Push Images to Docker Hub
**Note**: If you are planning to just deploy the application without making changes, you can skip this step and go directly to [Step 2: Deploy to OpenShift](#step-2-deploy-to-openShift).

```bash
cd library-system

# Login to Docker Hub
docker login

# Set your Docker Hub username
export DOCKER_USERNAME=your-dockerhub-username

# Build and push all images
chmod +x build-and-push-dockerhub.sh
./build-and-push-dockerhub.sh
```

The script will build and push:
- `your-username/library-books-api:latest`
- `your-username/library-users-api:latest`
- `your-username/library-web-ui:latest`
- `your-username/library-load-generator:latest`


### Step 2: Deploy to OpenShift
```
# Set your Docker Hub username (These variables have to be set only if you have built docker images and pulling from your docker registry)
export DOCKER_USERNAME=<your-dockerhub-username>
export IMAGE_TAG=<your-dockerimage-tag>
```

```bash
cd library-system

# Login to OpenShift
oc login

# Deploy the application
chmod +x deploy-dockerhub.sh
./deploy-dockerhub.sh
```

The deployment script will:
1. Create the `library-system` namespace
2. Deploy MongoDB with persistent storage and secret for accessing MongoDB
3. Deploy Books API, Users API, and Web UI
4. Create routes for external access
5. Deploy load generator (scaled to 0 initially)

### Step 3: Verify Deployment

```bash
# Check all pods are running
oc get pods -n library-system

# Get the application URL
oc get route web-ui -n library-system

# Check logs
oc logs -f deployment/books-api -n library-system
oc logs -f deployment/users-api -n library-system
oc logs -f deployment/web-ui -n library-system
```

### Step 4: Generate Traffic

```bash
cd library-system

# Start generating traffic
chmod +x generate-traffic.sh
./generate-traffic.sh
```

This will:
- Scale up the load generator to 1 replica
- Start sending requests to the application
- Verify all services are receiving traffic
- Check MongoDB connectivity
- Display real-time logs

### Step 5: Invalidate the secret (Optional)
To generate erroneous calls in Instana dashboard for the library-system application following steps can be performed:

- In the OpenShift Console, switch to `library-system` namespace where application is deployed
- Go to Workloads -> Secrets -> Edit secret `mongodb-credentials` by clicking on 3 dots against it and selecting "Edit Secret" option
- Invalidate the key value of `password` by changing the originial value of `SecurePassword123!` to any other value.
- Click on **Save**
- Go to Workloads -> Pods and delete pods related to users-api and books-api deployments.

These pods will get into CrashLoopBackOff and Error state as the password being used for authenticating to mongo db is incorrect now, leading to high erroneous calls in library-system application dashboard in Instana. 

### Step 6: Add Latency (Optional)

To test performance monitoring and Instana:

```bash
cd library-system

# Add artificial latency
chmod +x add-latency.sh
./add-latency.sh
```

Choose from:
1. **Low Latency** (100-300ms) - Simulate normal network delays
2. **Medium Latency** (500-1000ms) - Simulate slow responses
3. **High Latency** (1000-2000ms) - Simulate performance issues
4. **Very High Latency** (2000-5000ms) - Simulate severe problems
5. **Custom Latency** - Set your own values
6. **Remove All Latency** - Return to normal operation

---

## Detailed Instructions

### Building Images with Docker

#### Prerequisites Check

```bash
# Check Docker is installed and running
docker --version
docker info

# Login to Docker Hub
docker login
# Enter your username and password
```

#### Build Script Usage

```bash
cd library-system

# Interactive mode (will prompt for username)
./build-and-push-dockerhub.sh

# With environment variables
export DOCKER_USERNAME=myusername
export IMAGE_TAG=v1.0.0
./build-and-push-dockerhub.sh

# Inline variables
DOCKER_USERNAME=myusername IMAGE_TAG=latest ./build-and-push-dockerhub.sh
```

#### What Gets Built

| Service | Image Name | Description |
|---------|------------|-------------|
| books-api | `username/library-books-api:tag` | Python Flask API for books management |
| users-api | `username/library-users-api:tag` | Python Flask API for user management |
| web-ui | `username/library-web-ui:tag` | Node.js Express frontend |
| load-generator | `username/library-load-generator:tag` | Python traffic generator |

#### Build Output

```
==========================================
Docker Hub Build and Push Script
==========================================

✓ Docker is running
✓ Docker Hub username: myusername
✓ Image tag: latest

This script will build and push the following images:
  - myusername/library-books-api:latest
  - myusername/library-users-api:latest
  - myusername/library-web-ui:latest
  - myusername/library-load-generator:latest

Continue? (y/n) y

==========================================
Building and Pushing Images
==========================================

==========================================
Processing books-api
==========================================
Building myusername/library-books-api:latest...
✓ Build successful

Pushing myusername/library-books-api:latest to Docker Hub...
✓ Push successful

[... similar output for other services ...]

==========================================
✅ All Images Built and Pushed!
==========================================
```

### Deploying to OpenShift

#### Prerequisites Check

```bash
# Check OpenShift CLI is installed
oc version

# Check you're logged in
oc whoami

# Check cluster info
oc cluster-info
```

#### Deployment Script Usage

```bash
cd library-system

# Basic deployment (uses default username: dikamath)
./deploy-dockerhub.sh

# With custom Docker Hub username
export DOCKER_USERNAME=myusername
./deploy-dockerhub.sh

# With custom image tag
export DOCKER_USERNAME=myusername
export IMAGE_TAG=v1.0.0
./deploy-dockerhub.sh
```

#### Deployment Output

```
==========================================
Library System Deployment (Docker Hub)
==========================================

✓ Logged in as: developer
✓ Docker Hub username: myusername
✓ Image tag: latest

Step 1: Creating namespace...
✓ Namespace ready

Step 2: Verifying Docker Hub images...
Images to be used:
  - myusername/library-books-api:latest
  - myusername/library-users-api:latest
  - myusername/library-web-ui:latest
  - myusername/library-load-generator:latest

Are these images available on Docker Hub? (y/n) y

Step 3: Deploying all resources...
✓ Resources deployed

Step 4: Waiting for MongoDB to be ready...
✓ MongoDB ready

Step 5: Waiting for application services to be ready...
Waiting for books-api...
Waiting for users-api...
Waiting for web-ui...

==========================================
✅ Deployment Complete!
==========================================

📚 Library System is ready!

Access the application:
  http://web-ui-library-system.apps.your-cluster.com

Check pod status:
  oc get pods -n library-system

View logs:
  oc logs -f deployment/web-ui -n library-system
  oc logs -f deployment/books-api -n library-system
  oc logs -f deployment/users-api -n library-system

Start load generator:
  oc scale deployment/load-generator --replicas=1 -n library-system

Generate traffic and verify Instana:
  ./generate-traffic.sh

Add latency for testing:
  ./add-latency.sh
```

### Generating Traffic

The `generate-traffic.sh` script helps you:
- Start the load generator
- Verify traffic flow through all services
- Check MongoDB connectivity
- Monitor Instana integration

```bash
cd library-system
./generate-traffic.sh
```

**What it does:**
1. Checks load generator status
2. Scales up load generator if needed (to 1 replica)
3. Verifies all services are running
4. Shows load generator logs
5. Checks web-ui, books-api, and users-api logs
6. Tests direct API calls to verify MongoDB
7. Checks MongoDB pod status
8. Verifies Instana annotations
9. Checks for Instana initialization in logs

**Traffic Flow:**
```
Load Generator → Web UI → Books API → MongoDB
                       → Users API → MongoDB
```

**Monitoring Traffic:**

```bash
# Watch load generator in real-time
oc logs -f deployment/load-generator -n library-system

# Watch books-api
oc logs -f deployment/books-api -n library-system

# Watch users-api
oc logs -f deployment/users-api -n library-system

# Increase traffic
oc set env deployment/load-generator REQUESTS_PER_MINUTE=60 -n library-system

# Stop traffic
oc scale deployment/load-generator --replicas=0 -n library-system
```

### Adding Latency

The `add-latency.sh` script adds artificial delays to test performance monitoring:

```bash
cd library-system
./add-latency.sh
```

**Interactive Menu:**
```
================================================
Adding Latency to Services
================================================

Select latency level:
1) Low Latency (100-300ms)
2) Medium Latency (500-1000ms)
3) High Latency (1000-2000ms)
4) Very High Latency (2000-5000ms)
5) Custom Latency
6) Remove All Latency
0) Exit

Enter your choice:
```

**Use Cases:**
- **Low Latency**: Simulate normal network conditions
- **Medium Latency**: Test how application handles slow responses
- **High Latency**: Identify performance bottlenecks
- **Very High Latency**: Test timeout handling and error recovery
- **Custom**: Set specific latency ranges for testing

**Affected Services:**
- books-api
- users-api
- web-ui

**Monitoring Latency Impact:**

Check Instana dashboard for:
- Increased response times
- Service dependency graphs
- Error rates
- Database query performance

---


*Made with Bob*
