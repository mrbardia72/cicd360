#!/bin/bash

# 🚀 CICD360 Server Setup Script
# This script prepares a fresh Linux server for CICD360 deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="cicd360"
DEPLOY_USER="root"
DEPLOY_DIR="/opt/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run this script as root (use sudo)"
        exit 1
    fi
}

# System update
update_system() {
    log "Updating system packages..."

    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        apt-get update -y
        # apt-get upgrade -y
        apt-get install -y curl wget git unzip software-properties-common
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        yum update -y
        yum install -y curl wget git unzip
    elif command -v dnf &> /dev/null; then
        # Fedora
        dnf update -y
        dnf install -y curl wget git unzip
    else
        log_error "Unsupported package manager. Please install Docker manually."
        exit 1
    fi

    log_success "System updated successfully"
}

# Install Docker
# install_docker() {
#     log "Installing Docker..."

#     if command -v docker &> /dev/null; then
#         log_warning "Docker is already installed"
#         docker --version
#     else
#         # Download and install Docker
#         curl -fsSL https://get.docker.com -o get-docker.sh
#         sh get-docker.sh
#         rm get-docker.sh

#         # Start and enable Docker service
#         systemctl start docker
#         systemctl enable docker

#         log_success "Docker installed successfully"
#         docker --version
#     fi
# }

# Install Docker Compose
# install_docker_compose() {
#     log "Installing Docker Compose..."

#     if command -v docker-compose &> /dev/null; then
#         log_warning "Docker Compose is already installed"
#         docker-compose --version
#     else
#         # Get latest version
#         DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')

#         # Download and install
#         curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#         chmod +x /usr/local/bin/docker-compose

#         # Create symlink for easier access
#         ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

#         log_success "Docker Compose installed successfully"
#         docker-compose --version
#     fi
# }

# Create deployment user
create_deploy_user() {
    log "Creating deployment user: ${DEPLOY_USER}"

    if id "${DEPLOY_USER}" &>/dev/null; then
        log_warning "User ${DEPLOY_USER} already exists"
    else
        # Create user with home directory
        useradd -m -s /bin/bash "${DEPLOY_USER}"

        # Add user to docker group
        usermod -aG docker "${DEPLOY_USER}"

        # Create .ssh directory
        mkdir -p "/home/${DEPLOY_USER}/.ssh"
        chmod 700 "/home/${DEPLOY_USER}/.ssh"
        chown "${DEPLOY_USER}:${DEPLOY_USER}" "/home/${DEPLOY_USER}/.ssh"

        log_success "User ${DEPLOY_USER} created successfully"
    fi
}

# Setup SSH access
setup_ssh() {
    log "Setting up SSH access..."

    SSH_DIR="/home/${DEPLOY_USER}/.ssh"

    # Create authorized_keys file if it doesn't exist
    if [ ! -f "${SSH_DIR}/authorized_keys" ]; then
        touch "${SSH_DIR}/authorized_keys"
        chmod 600 "${SSH_DIR}/authorized_keys"
        chown "${DEPLOY_USER}:${DEPLOY_USER}" "${SSH_DIR}/authorized_keys"
    fi

    log "📋 SSH Setup Instructions:"
    echo "1. Add your public key to: ${SSH_DIR}/authorized_keys"
    echo "2. Or run: echo 'YOUR_PUBLIC_KEY' >> ${SSH_DIR}/authorized_keys"
    echo "3. Test connection: ssh ${DEPLOY_USER}@$(hostname -I | awk '{print $1}')"
}

# Create application directories
create_app_directories() {
    log "Creating application directories..."

    # Create deployment directory
    mkdir -p "${DEPLOY_DIR}"
    mkdir -p "${DEPLOY_DIR}/backups"
    mkdir -p "${DEPLOY_DIR}/scripts"

    # Create log directory
    mkdir -p "${LOG_DIR}"

    # Set proper ownership
    chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_DIR}"
    chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${LOG_DIR}"

    # Set proper permissions
    chmod 755 "${DEPLOY_DIR}"
    chmod 755 "${LOG_DIR}"

    log_success "Application directories created"
    log "📁 Deployment directory: ${DEPLOY_DIR}"
    log "📋 Log directory: ${LOG_DIR}"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."

    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian - UFW
        ufw --force enable
        ufw allow ssh
        ufw allow 22/tcp
        ufw allow 8080/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw status
        log_success "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL - firewalld
        systemctl start firewalld
        systemctl enable firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --reload
        firewall-cmd --list-all
        log_success "Firewalld configured"
    else
        log_warning "No supported firewall found. Please configure ports manually:"
        log "📝 Required ports: 22 (SSH), 8080 (App), 80 (HTTP), 443 (HTTPS)"
    fi
}

# Install additional tools
# install_tools() {
#     log "Installing additional tools..."

#     # Install useful tools
#     if command -v apt-get &> /dev/null; then
#         apt-get install -y htop nano vim curl wget jq netcat-openbsd
#     elif command -v yum &> /dev/null; then
#         yum install -y htop nano vim curl wget jq nc
#     elif command -v dnf &> /dev/null; then
#         dnf install -y htop nano vim curl wget jq nc
#     fi

#     log_success "Additional tools installed"
# }

# Setup log rotation
setup_log_rotation() {
    log "Setting up log rotation..."

    cat > /etc/logrotate.d/${APP_NAME} << EOF
${LOG_DIR}/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
    su ${DEPLOY_USER} ${DEPLOY_USER}
}
EOF

    log_success "Log rotation configured"
}

# Create systemd service (optional)
create_systemd_service() {
    log "Creating systemd service..."

    cat > /etc/systemd/system/${APP_NAME}.service << EOF
[Unit]
Description=CICD360 Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${DEPLOY_DIR}
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=${DEPLOY_USER}
Group=${DEPLOY_USER}

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ${APP_NAME}.service

    log_success "Systemd service created and enabled"
}

# Security hardening
security_hardening() {
    log "Applying basic security hardening..."

    # Disable root SSH login (optional)
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config || true

    # Enable password authentication (can be disabled after key setup)
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config || true

    # Restart SSH service
    systemctl restart sshd || systemctl restart ssh || true

    log_success "Basic security hardening applied"
    log_warning "Consider disabling password authentication after SSH key setup"
}

# System information
show_system_info() {
    log "📊 System Information:"
    echo "========================"
    echo "🖥️  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "💾 RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "💿 Disk: $(df -h / | awk 'NR==2 {print $4}')"
    echo "🌐 IP: $(hostname -I | awk '{print $1}')"
    echo "🐳 Docker: $(docker --version)"
    echo "🐙 Docker Compose: $(docker-compose --version)"
    echo "👤 Deploy User: ${DEPLOY_USER}"
    echo "📁 Deploy Dir: ${DEPLOY_DIR}"
    echo "📋 Log Dir: ${LOG_DIR}"
    echo "========================"
}

# Final instructions
show_final_instructions() {
    log "🎉 Server setup completed successfully!"
    echo ""
    log "📋 Next Steps:"
    echo "1. Add your SSH public key to the server:"
    echo "   ssh-copy-id ${DEPLOY_USER}@$(hostname -I | awk '{print $1}')"
    echo ""
    echo "2. Test SSH connection:"
    echo "   ssh ${DEPLOY_USER}@$(hostname -I | awk '{print $1}')"
    echo ""
    echo "3. Update your GitHub repository secrets:"
    echo "   - SERVER_HOST: $(hostname -I | awk '{print $1}')"
    echo "   - SERVER_USER: ${DEPLOY_USER}"
    echo "   - SSH_PRIVATE_KEY: [Your private SSH key content]"
    echo ""
    echo "4. Push your code to 'main' branch to trigger deployment"
    echo ""
    log "🔗 Application will be accessible at:"
    echo "   http://$(hostname -I | awk '{print $1}'):8080"
    echo ""
    log_success "Ready for deployment! 🚀"
}

# Main execution
main() {
    log "🚀 Starting CICD360 server setup..."

    check_root
    update_system
    # install_docker
    # install_docker_compose
    create_deploy_user
    setup_ssh
    create_app_directories
    configure_firewall
    # install_tools
    setup_log_rotation
    create_systemd_service
    security_hardening
    show_system_info
    show_final_instructions
}

# Run main function
main "$@"
