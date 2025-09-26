#!/bin/bash

# 🚀 CICD360 Deployment Script
# This script handles the deployment of the application using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="cicd360"
DOCKER_IMAGE=${1:-"ghcr.io/mrbardia72/cicd360:latest"}
COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="/opt/${APP_NAME}/backups"
LOG_FILE="/var/log/${APP_NAME}/deploy.log"

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "${LOG_FILE}" 2>/dev/null || true
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "${LOG_FILE}" 2>/dev/null || true
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "${LOG_FILE}" 2>/dev/null || true
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "${LOG_FILE}" 2>/dev/null || true
}

create_directories() {
    log "Creating necessary directories..."
    mkdir -p "${BACKUP_DIR}"
    mkdir -p "$(dirname "${LOG_FILE}")"
    log_success "Directories created"
}

backup_current_deployment() {
    log "Creating backup of current deployment..."

    if docker-compose ps | grep -q "${APP_NAME}"; then
        BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

        # Backup docker-compose.yml
        if [ -f "${COMPOSE_FILE}" ]; then
            cp "${COMPOSE_FILE}" "${BACKUP_DIR}/${BACKUP_NAME}/"
            log_success "Docker compose file backed up"
        fi

        # Export current container state
        docker-compose config > "${BACKUP_DIR}/${BACKUP_NAME}/docker-compose-state.yml" || true

        log_success "Backup created: ${BACKUP_NAME}"
    else
        log_warning "No running deployment found to backup"
    fi
}

stop_current_deployment() {
    log "Stopping current deployment..."

    if docker-compose ps | grep -q "${APP_NAME}"; then
        docker-compose down --timeout 30 || {
            log_warning "Graceful shutdown failed, forcing stop..."
            docker-compose kill
            docker-compose down
        }
        log_success "Current deployment stopped"
    else
        log "No running deployment found"
    fi
}

pull_new_image() {
    log "Pulling new Docker image: ${DOCKER_IMAGE}"

    if docker pull "${DOCKER_IMAGE}"; then
        log_success "Image pulled successfully"
    else
        log_error "Failed to pull image: ${DOCKER_IMAGE}"
        exit 1
    fi
}

update_docker_compose() {
    log "Updating docker-compose.yml with new image..."

    # Update the image in docker-compose.yml
    if [ -f "${COMPOSE_FILE}" ]; then
        # Create a temporary file with updated image
        sed "s|image: .*|image: ${DOCKER_IMAGE}|g" "${COMPOSE_FILE}" > "${COMPOSE_FILE}.tmp"
        mv "${COMPOSE_FILE}.tmp" "${COMPOSE_FILE}"
        log_success "Docker compose updated with new image"
    else
        log_error "Docker compose file not found: ${COMPOSE_FILE}"
        exit 1
    fi
}

start_new_deployment() {
    log "Starting new deployment..."

    # Set environment variables
    export DOCKER_IMAGE="${DOCKER_IMAGE}"
    export APP_VERSION=$(echo "${DOCKER_IMAGE}" | cut -d':' -f2)

    # Start the new deployment
    if docker-compose up -d --remove-orphans; then
        log_success "New deployment started"
    else
        log_error "Failed to start new deployment"
        rollback_deployment
        exit 1
    fi
}

wait_for_container() {
    log "Waiting for container to be ready..."

    local timeout=120
    local counter=0

    while [ $counter -lt $timeout ]; do
        if docker-compose ps | grep -q "Up"; then
            log_success "Container is running"
            return 0
        fi

        sleep 2
        counter=$((counter + 2))

        if [ $((counter % 10)) -eq 0 ]; then
            log "Still waiting for container... (${counter}/${timeout}s)"
        fi
    done

    log_error "Container failed to start within ${timeout} seconds"
    return 1
}

rollback_deployment() {
    log_warning "Rolling back deployment..."

    # Find the latest backup
    LATEST_BACKUP=$(ls -t "${BACKUP_DIR}" | head -n1)

    if [ -n "${LATEST_BACKUP}" ] && [ -d "${BACKUP_DIR}/${LATEST_BACKUP}" ]; then
        log "Restoring from backup: ${LATEST_BACKUP}"

        # Stop current deployment
        docker-compose down --timeout 30 || true

        # Restore backup
        if [ -f "${BACKUP_DIR}/${LATEST_BACKUP}/${COMPOSE_FILE}" ]; then
            cp "${BACKUP_DIR}/${LATEST_BACKUP}/${COMPOSE_FILE}" .
            docker-compose up -d
            log_success "Rollback completed"
        else
            log_error "Backup file not found"
        fi
    else
        log_error "No backup found for rollback"
    fi
}

cleanup_old_backups() {
    log "Cleaning up old backups..."

    # Keep only the last 5 backups
    if [ -d "${BACKUP_DIR}" ]; then
        cd "${BACKUP_DIR}"
        ls -t | tail -n +6 | xargs -r rm -rf
        log_success "Old backups cleaned up"
    fi
}

show_deployment_status() {
    log "Deployment Status:"
    echo ""
    echo "🐳 Docker Containers:"
    docker-compose ps || true
    echo ""
    echo "📊 Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" || true
    echo ""
    echo "🌐 Application URL: http://localhost:8080"
    echo "🏥 Health Check: http://localhost:8080/health"
    echo "ℹ️  Info Endpoint: http://localhost:8080/info"
}

# Main deployment process
main() {
    log "🚀 Starting deployment of ${APP_NAME}"
    log "📦 Using image: ${DOCKER_IMAGE}"

    # Check if docker-compose is available
    if ! command -v docker-compose &> /dev/null; then
        log_error "docker-compose is not installed"
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi

    # Create necessary directories
    create_directories

    # Backup current deployment
    backup_current_deployment

    # Pull new image
    pull_new_image

    # Stop current deployment
    stop_current_deployment

    # Update docker-compose file
    update_docker_compose

    # Start new deployment
    start_new_deployment

    # Wait for container to be ready
    if ! wait_for_container; then
        rollback_deployment
        exit 1
    fi

    # Clean up old backups
    cleanup_old_backups

    # Show deployment status
    show_deployment_status

    log_success "🎉 Deployment completed successfully!"
    log "📝 Logs are available at: ${LOG_FILE}"
}

# Handle script interruption
trap 'log_error "Deployment interrupted"; exit 130' INT TERM

# Run main function
main "$@"
