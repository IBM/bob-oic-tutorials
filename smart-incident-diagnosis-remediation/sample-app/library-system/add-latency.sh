#!/bin/bash

# Script to add artificial latency to services for testing Instana monitoring

set -e

NAMESPACE="library-system"

echo "================================================"
echo "Adding Latency to Services"
echo "================================================"
echo ""

# Function to display menu
show_menu() {
    echo "Select latency level:"
    echo "1) Low Latency (100-300ms)"
    echo "2) Medium Latency (500-1000ms)"
    echo "3) High Latency (1000-2000ms)"
    echo "4) Very High Latency (2000-5000ms)"
    echo "5) Custom Latency"
    echo "6) Remove All Latency"
    echo "0) Exit"
    echo ""
}

# Function to add latency to books-api
add_books_latency() {
    local min_delay=$1
    local max_delay=$2
    
    echo "Adding latency to books-api (${min_delay}-${max_delay}ms)..."
    oc set env deployment/books-api \
        LATENCY_MIN_MS=$min_delay \
        LATENCY_MAX_MS=$max_delay \
        -n $NAMESPACE
    echo "✓ books-api latency configured"
}

# Function to add latency to users-api
add_users_latency() {
    local min_delay=$1
    local max_delay=$2
    
    echo "Adding latency to users-api (${min_delay}-${max_delay}ms)..."
    oc set env deployment/users-api \
        LATENCY_MIN_MS=$min_delay \
        LATENCY_MAX_MS=$max_delay \
        -n $NAMESPACE
    echo "✓ users-api latency configured"
}

# Function to add latency to web-ui
add_webui_latency() {
    local min_delay=$1
    local max_delay=$2
    
    echo "Adding latency to web-ui (${min_delay}-${max_delay}ms)..."
    oc set env deployment/web-ui \
        LATENCY_MIN_MS=$min_delay \
        LATENCY_MAX_MS=$max_delay \
        -n $NAMESPACE
    echo "✓ web-ui latency configured"
}

# Function to remove all latency
remove_latency() {
    echo "Removing latency from all services..."
    
    oc set env deployment/books-api LATENCY_MIN_MS- LATENCY_MAX_MS- -n $NAMESPACE 2>/dev/null || true
    oc set env deployment/users-api LATENCY_MIN_MS- LATENCY_MAX_MS- -n $NAMESPACE 2>/dev/null || true
    oc set env deployment/web-ui LATENCY_MIN_MS- LATENCY_MAX_MS- -n $NAMESPACE 2>/dev/null || true
    
    echo "✓ All latency removed"
}

# Function to apply latency
apply_latency() {
    local min_delay=$1
    local max_delay=$2
    
    echo ""
    echo "Applying latency: ${min_delay}-${max_delay}ms"
    echo ""
    
    add_books_latency $min_delay $max_delay
    add_users_latency $min_delay $max_delay
    add_webui_latency $min_delay $max_delay
    
    echo ""
    echo "Waiting for deployments to restart..."
    sleep 5
    
    echo ""
    echo "✅ Latency applied successfully!"
    echo ""
    echo "Services will now have ${min_delay}-${max_delay}ms artificial delay"
    echo ""
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice: " choice
    
    case $choice in
        1)
            apply_latency 100 300
            ;;
        2)
            apply_latency 500 1000
            ;;
        3)
            apply_latency 1000 2000
            ;;
        4)
            apply_latency 2000 5000
            ;;
        5)
            read -p "Enter minimum latency (ms): " min_delay
            read -p "Enter maximum latency (ms): " max_delay
            apply_latency $min_delay $max_delay
            ;;
        6)
            remove_latency
            echo ""
            echo "✅ All latency removed"
            echo ""
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            echo ""
            ;;
    esac
    
    echo "Press Enter to continue..."
    read
    echo ""
done

# Made with Bob
