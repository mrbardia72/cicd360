#!/bin/bash

# 🏥 CICD360 Health Check Script
# This script performs comprehensive health checks on the deployed application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="cicd360"
HOST="localhost"
PORT="8080"
HEALTH_ENDPOINT="/health"
INFO_ENDPOINT="/info"
TIMEOUT=60
RETRY_INTERVAL=5
LOG_FILE="/var/log/${APP_NAME}/health-check.log"

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

check_docker_container() {
    log "Checking Docker container status..."

    if docker-compose ps | grep -q "Up"; then
        log_success "Docker container is running"
        return 0
    else
        log_error "Docker container is not running"
        docker-compose ps || true
        return 1
    fi
}

check_port_accessibility() {
    log "Checking if port ${PORT} is accessible..."

    if nc -z ${HOST} ${PORT} 2>/dev/null; then
        log_success "Port ${PORT} is accessible"
        return 0
    else
        log_error "Port ${PORT} is not accessible"
        return 1
    fi
}

check_health_endpoint() {
    log "Checking health endpoint: http://${HOST}:${PORT}${HEALTH_ENDPOINT}"

    local response
    local http_code

    response=$(curl -s -w "HTTPSTATUS:%{http_code}" "http://${HOST}:${PORT}${HEALTH_ENDPOINT}" || echo "HTTPSTATUS:000")
    http_code=$(echo "${response}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

    if [ "${http_code}" -eq 200 ]; then
        local body=$(echo "${response}" | sed -E 's/HTTPSTATUS:[0-9]{3}$//')
        log_success "Health endpoint responded with HTTP 200"

        # Parse JSON response to check status
        if command -v jq &> /dev/null; then
            local status=$(echo "${body}" | jq -r '.status' 2>/dev/null || echo "unknown")
            if [ "${status}" = "OK" ]; then
                log_success "Application health status: ${status}"
                return 0
            else
                log_error "Application health status: ${status}"
                return 1
            fi
        else
            # Basic check without jq
            if echo "${body}" | grep -q '"status":"OK"'; then
                log_success "Application health status: OK"
                return 0
            else
                log_error "Application health status: Not OK"
                return 1
            fi
        fi
    else
        log_error "Health endpoint responded with HTTP ${http_code}"
        return 1
    fi
}

check_info_endpoint() {
    log "Checking info endpoint: http://${HOST}:${PORT}${INFO_ENDPOINT}"

    local response
    local http_code

    response=$(curl -s -w "HTTPSTATUS:%{http_code}" "http://${HOST}:${PORT}${INFO_ENDPOINT}" || echo "HTTPSTATUS:000")
    http_code=$(echo "${response}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

    if [ "${http_code}" -eq 200 ]; then
        log_success "Info endpoint responded with HTTP 200"

        # Display application info
        local body=$(echo "${response}" | sed -E 's/HTTPSTATUS:[0-9]{3}$//')
        if command -v jq &> /dev/null; then
            echo ""
            log "📋 Application Information:"
            echo "${body}" | jq . 2>/dev/null || echo "${body}"
            echo ""
        fi
        return 0
    else
        log_warning "Info endpoint responded with HTTP ${http_code}"
        return 1
    fi
}

check_resource_usage() {
    log "Checking resource usage..."

    # Check Docker container resources
    if docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | grep -q "${APP_NAME}"; then
        echo ""
        log "📊 Resource Usage:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | head -1
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | grep "${APP_NAME}" || true
        echo ""
        log_success "Resource usage checked"
    else
        log_warning "Could not retrieve resource usage"
    fi
}

check_logs_for_errors() {
    log "Checking recent logs for errors..."

    local error_count
    error_count=$(docker-compose logs --tail=50 app 2>/dev/null | grep -i "error\|fatal\|panic" | wc -l || echo "0")

    if [ "${error_count}" -eq 0 ]; then
        log_success "No errors found in recent logs"
        return 0
    else
        log_warning "Found ${error_count} error(s) in recent logs"
        echo ""
        log "🔍 Recent errors:"
        docker-compose logs --tail=20 app 2>/dev/null | grep -i "error\|fatal\|panic" | tail -5 || true
        echo ""
        return 1
    fi
}

perform_load_test() {
    log "Performing basic load test..."

    local success_count=0
    local total_requests=5

    for i in $(seq 1 ${total_requests}); do
        if curl -s -f "http://${HOST}:${PORT}${HEALTH_ENDPOINT}" > /dev/null; then
            success_count=$((success_count + 1))
        fi
        sleep 0.5
    done

    if [ "${success_count}" -eq "${total_requests}" ]; then
        log_success "Load test passed (${success_count}/${total_requests} requests successful)"
        return 0
    else
        log_warning "Load test partial success (${success_count}/${total_requests} requests successful)"
        return 1
    fi
}

wait_for_application() {
    log "Waiting for application to be ready..."

    local counter=0
    while [ ${counter} -lt ${TIMEOUT} ]; do
        if curl -s -f "http://${HOST}:${PORT}${HEALTH_ENDPOINT}" > /dev/null 2>&1; then
            log_success "Application is ready"
            return 0
        fi

        sleep ${RETRY_INTERVAL}
        counter=$((counter + RETRY_INTERVAL))

        if [ $((counter % 15)) -eq 0 ]; then
            log "Still waiting for application... (${counter}/${TIMEOUT}s)"
        fi
    done

    log_error "Application failed to respond within ${TIMEOUT} seconds"
    return 1
}

# Main health check process
main() {
    log "🏥 Starting comprehensive health check for ${APP_NAME}"

    # Create log directory
    mkdir -p "$(dirname "${LOG_FILE}")"

    local exit_code=0
    local checks_passed=0
    local total_checks=7

    # Wait for application to be ready
    if wait_for_application; then
        checks_passed=$((checks_passed + 1))
    else
        exit_code=1
    fi

    # Check Docker container status
    if check_docker_container; then
        checks_passed=$((checks_passed + 1))
    else
        exit_code=1
    fi

    # Check port accessibility
    if check_port_accessibility; then
        checks_passed=$((checks_passed + 1))
    else
        exit_code=1
    fi

    # Check health endpoint
    if check_health_endpoint; then
        checks_passed=$((checks_passed + 1))
    else
        exit_code=1
    fi

    # Check info endpoint (non-critical)
    if check_info_endpoint; then
        checks_passed=$((checks_passed + 1))
    fi

    # Check resource usage (non-critical)
    if check_resource_usage; then
        checks_passed=$((checks_passed + 1))
    fi

    # Check logs for errors (non-critical)
    if check_logs_for_errors; then
        checks_passed=$((checks_passed + 1))
    fi

    # Perform load test (non-critical)
    if perform_load_test; then
        checks_passed=$((checks_passed + 1))
    fi

    echo ""
    log "📊 Health Check Summary:"
    log "✅ Checks passed: ${checks_passed}/${total_checks}"

    if [ ${exit_code} -eq 0 ]; then
        log_success "🎉 All critical health checks passed!"
        echo ""
        echo "🌐 Application is healthy and accessible at:"
        echo "   • Health Check: http://${HOST}:${PORT}${HEALTH_ENDPOINT}"
        echo "   • Info: http://${HOST}:${PORT}${INFO_ENDPOINT}"
        echo "   • Main App: http://${HOST}:${PORT}/"
    else
        log_error "💥 Some critical health checks failed!"
        echo ""
        echo "🔍 Troubleshooting:"
        echo "   • Check container logs: docker-compose logs app"
        echo "   • Check container status: docker-compose ps"
        echo "   • Check port binding: netstat -tlnp | grep ${PORT}"
    fi

    echo ""
    log "📝 Detailed logs available at: ${LOG_FILE}"

    exit ${exit_code}
}

# Handle script interruption
trap 'log_error "Health check interrupted"; exit 130' INT TERM

# Run main function
main "$@"
