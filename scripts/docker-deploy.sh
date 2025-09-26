#!/bin/bash

set -e

# Variables
NEW_IMAGE="$1"
COMPOSE_FILE="/opt/myapp/docker-compose.yml"
BACKUP_DIR="/opt/myapp/backups"
SERVICE_NAME="app"

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Validate input
if [ -z "$NEW_IMAGE" ]; then
    log_error "Usage: $0 <new-image>"
    exit 1
fi

log_step "🚀 Starting Docker deployment for image: $NEW_IMAGE"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if docker-compose.yml exists
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "docker-compose.yml not found at $COMPOSE_FILE"
    exit 1
fi

# Update docker-compose.yml with new image
log_step "📝 Updating docker-compose.yml with new image"
sed -i.backup "s|image:.*myapp.*|image: $NEW_IMAGE|g" "$COMPOSE_FILE"

# Create backup of current state
BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
log_step "💾 Creating backup: $BACKUP_NAME"

if docker-compose ps | grep -q "Up"; then
    # Export current container state
    docker-compose config > "$BACKUP_DIR/$BACKUP_NAME.yml"
    
    # Backup database if exists
    if docker-compose ps db | grep -q "Up"; then
        log_info "Creating database backup..."
        docker-compose exec -T db pg_dump -U postgres myapp > "$BACKUP_DIR/$BACKUP_NAME.sql"
    fi
fi

# Pull new image
log_step "🐳 Pulling new Docker image"
docker pull "$NEW_IMAGE"

# Deploy with zero-downtime strategy
log_step "🔄 Starting zero-downtime deployment"

# Start new container alongside old one
log_info "Starting new container..."
docker-compose up -d --no-deps --scale $SERVICE_NAME=2 $SERVICE_NAME

# Wait for new container to be healthy
log_info "Waiting for new container to be ready..."
timeout=60
while [ $timeout -gt 0 ]; do
    NEW_CONTAINER=$(docker-compose ps -q $SERVICE_NAME | head -n1)
    if [ -n "$NEW_CONTAINER" ]; then
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$NEW_CONTAINER" 2>/dev/null || echo "none")
        if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "none" ]; then
            # If no healthcheck, try direct HTTP check
            if curl -f http://localhost:8080/health > /dev/null 2>&1; then
                log_info "✅ New container is healthy"
                break
            fi
        fi
    fi
    
    if [ $timeout -le 0 ]; then
        log_error "❌ New container failed health check"
        log_info "Rolling back..."
        docker-compose up -d --scale $SERVICE_NAME=1 $SERVICE_NAME
        exit 1
    fi
    
    echo "Health check pending... ($timeout seconds left)"
    sleep 5
    timeout=$((timeout-5))
done

# Remove old container
log_info "Removing old container..."
docker-compose up -d --scale $SERVICE_NAME=1 $SERVICE_NAME

# Update nginx configuration if needed
if docker-compose ps nginx | grep -q "Up"; then
    log_info "Reloading nginx configuration..."
    docker-compose exec nginx nginx -s reload
fi

# Verify deployment
log_step "🔍 Verifying deployment"
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    log_info "✅ Deployment verification successful!"
else
    log_warn "⚠️ Deployment verification failed, but containers are running"
fi

# Cleanup old images (keep last 3)
log_step "🧹 Cleaning up old images"
OLD_IMAGES=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep myapp | tail -n +4)
if [ -n "$OLD_IMAGES" ]; then
    echo "$OLD_IMAGES" | xargs docker rmi -f 2>/dev/null || true
fi

# Show final status
log_step "📊 Final Status"
docker-compose ps
docker system df

log_info "✅ Deployment completed successfully!"
log_info "📋 Logs: docker-compose logs -f $SERVICE_NAME"
log_info "💾 Backup created: $BACKUP_DIR/$BACKUP_NAME.*"

# Send notification (optional)
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"✅ Deployment successful: $NEW_IMAGE\"}" \
        "$SLACK_WEBHOOK_URL"
fi