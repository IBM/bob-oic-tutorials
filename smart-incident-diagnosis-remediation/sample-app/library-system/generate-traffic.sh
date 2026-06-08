#!/bin/bash

# Script to generate traffic and verify MongoDB discovery in Instana

set -e

NAMESPACE="library-system"

echo "================================================"
echo "Generating Traffic for MongoDB Discovery"
echo "================================================"
echo ""

# Check if namespace exists
if ! oc get namespace $NAMESPACE &> /dev/null; then
    echo "❌ Namespace $NAMESPACE does not exist."
    exit 1
fi

echo "✓ Namespace $NAMESPACE found"
echo ""

# Step 1: Check current load generator status
echo "Step 1: Checking load generator status..."
CURRENT_REPLICAS=$(oc get deployment load-generator -n $NAMESPACE -o jsonpath='{.spec.replicas}')
echo "Current replicas: $CURRENT_REPLICAS"
echo ""

# Step 2: Scale up load generator if needed
if [ "$CURRENT_REPLICAS" -eq 0 ]; then
    echo "Step 2: Scaling up load generator..."
    oc scale deployment/load-generator --replicas=1 -n $NAMESPACE
    echo "✓ Load generator scaled to 1 replica"
    echo ""
    
    echo "Waiting for load generator to be ready..."
    oc wait --for=condition=available --timeout=60s deployment/load-generator -n $NAMESPACE
    echo "✓ Load generator is ready"
    echo ""
else
    echo "Step 2: Load generator already running with $CURRENT_REPLICAS replica(s)"
    echo ""
fi

# Step 3: Verify all services are running
echo "Step 3: Verifying all services are running..."
echo ""
oc get pods -n $NAMESPACE
echo ""

# Step 4: Check load generator logs
echo "Step 4: Checking load generator logs (last 20 lines)..."
echo ""
LOAD_GEN_POD=$(oc get pods -n $NAMESPACE -l app=load-generator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "$LOAD_GEN_POD" ]; then
    echo "Load generator pod: $LOAD_GEN_POD"
    echo "Recent logs:"
    oc logs -n $NAMESPACE $LOAD_GEN_POD --tail=20
    echo ""
else
    echo "⚠️  Load generator pod not found yet, waiting..."
    sleep 5
    LOAD_GEN_POD=$(oc get pods -n $NAMESPACE -l app=load-generator -o jsonpath='{.items[0].metadata.name}')
    if [ -n "$LOAD_GEN_POD" ]; then
        echo "Load generator pod: $LOAD_GEN_POD"
        oc logs -n $NAMESPACE $LOAD_GEN_POD --tail=20
    fi
    echo ""
fi

# Step 5: Verify web-ui is receiving requests
echo "Step 5: Checking web-ui logs for incoming requests..."
WEB_UI_POD=$(oc get pods -n $NAMESPACE -l app=web-ui -o jsonpath='{.items[0].metadata.name}')
if [ -n "$WEB_UI_POD" ]; then
    echo "Web UI pod: $WEB_UI_POD"
    echo "Recent logs:"
    oc logs -n $NAMESPACE $WEB_UI_POD --tail=15
    echo ""
fi

# Step 6: Verify books-api is receiving requests
echo "Step 6: Checking books-api logs for MongoDB operations..."
BOOKS_POD=$(oc get pods -n $NAMESPACE -l app=books-api -o jsonpath='{.items[0].metadata.name}')
if [ -n "$BOOKS_POD" ]; then
    echo "Books API pod: $BOOKS_POD"
    echo "Recent logs:"
    oc logs -n $NAMESPACE $BOOKS_POD --tail=15
    echo ""
fi

# Step 7: Verify users-api is receiving requests
echo "Step 7: Checking users-api logs for MongoDB operations..."
USERS_POD=$(oc get pods -n $NAMESPACE -l app=users-api -o jsonpath='{.items[0].metadata.name}')
if [ -n "$USERS_POD" ]; then
    echo "Users API pod: $USERS_POD"
    echo "Recent logs:"
    oc logs -n $NAMESPACE $USERS_POD --tail=15
    echo ""
fi

# Step 8: Test direct API calls to verify MongoDB connectivity
echo "Step 8: Testing direct API calls to verify MongoDB..."
echo ""

if [ -n "$BOOKS_POD" ]; then
    echo "Testing books-api health endpoint:"
    oc exec -n $NAMESPACE $BOOKS_POD -- curl -s http://localhost:8081/health
    echo ""
    echo ""
    
    echo "Testing books-api /books endpoint (should query MongoDB):"
    oc exec -n $NAMESPACE $BOOKS_POD -- curl -s http://localhost:8081/books | head -c 200
    echo "..."
    echo ""
fi

if [ -n "$USERS_POD" ]; then
    echo "Testing users-api health endpoint:"
    oc exec -n $NAMESPACE $USERS_POD -- curl -s http://localhost:8082/health
    echo ""
    echo ""
    
    echo "Testing users-api /users endpoint (should query MongoDB):"
    oc exec -n $USERS_POD -- curl -s http://localhost:8082/users | head -c 200
    echo "..."
    echo ""
fi

# Step 9: Check MongoDB pod
echo "Step 9: Checking MongoDB status..."
MONGO_POD=$(oc get pods -n $NAMESPACE -l app=mongodb -o jsonpath='{.items[0].metadata.name}')
if [ -n "$MONGO_POD" ]; then
    echo "MongoDB pod: $MONGO_POD"
    echo "Pod status:"
    oc get pod $MONGO_POD -n $NAMESPACE
    echo ""
fi

# Step 10: Verify Instana annotations
echo "Step 10: Verifying Instana annotations..."
echo ""

echo "MongoDB deployment annotations:"
oc get deployment mongodb -n $NAMESPACE -o jsonpath='{.metadata.annotations.instana\.io/monitored}' && echo " ✓" || echo " ❌"

echo "Books API deployment annotations:"
oc get deployment books-api -n $NAMESPACE -o jsonpath='{.metadata.annotations.instana\.io/monitored}' && echo " ✓" || echo " ❌"

echo "Users API deployment annotations:"
oc get deployment users-api -n $NAMESPACE -o jsonpath='{.metadata.annotations.instana\.io/monitored}' && echo " ✓" || echo " ❌"

echo ""

# Step 11: Check for Instana initialization in logs
echo "Step 11: Checking for Instana initialization..."
echo ""

if [ -n "$BOOKS_POD" ]; then
    echo "Books API Instana initialization:"
    oc logs -n $NAMESPACE $BOOKS_POD | grep -i "instana" || echo "  No Instana logs found (may need to restart pod)"
    echo ""
fi

if [ -n "$USERS_POD" ]; then
    echo "Users API Instana initialization:"
    oc logs -n $NAMESPACE $USERS_POD | grep -i "instana" || echo "  No Instana logs found (may need to restart pod)"
    echo ""
fi

echo "================================================"
echo "✅ Traffic Generation Active"
echo "================================================"
echo ""
echo "Current Status:"
echo "- Load generator is running and sending requests"
echo "- Requests flow: Load Generator → Web UI → Books/Users API → MongoDB"
echo ""
echo "To monitor traffic in real-time:"
echo "  oc logs -f deployment/load-generator -n $NAMESPACE"
echo ""
echo "To check Instana Dashboard (wait 2-3 minutes):"
echo "1. Navigate to Infrastructure → Databases"
echo "2. Look for MongoDB instance"
echo "3. Check Service Map for connections:"
echo "   - web-ui → books-api → mongodb"
echo "   - web-ui → users-api → mongodb"
echo ""
echo "To increase traffic:"
echo "  oc set env deployment/load-generator REQUESTS_PER_MINUTE=60 -n $NAMESPACE"
echo ""
echo "To stop traffic:"
echo "  oc scale deployment/load-generator --replicas=0 -n $NAMESPACE"
echo ""

# Made with Bob
