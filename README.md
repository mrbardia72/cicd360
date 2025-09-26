# 🚀 CICD360 - Automated Golang Deployment Pipeline

A comprehensive CI/CD solution for automatically deploying Golang applications from GitHub to your server when merging to the main branch.

## 📋 Overview

This project provides a complete automated deployment pipeline that:
- 🔄 Automatically triggers on merge to `main` branch
- 🏗️ Builds your Golang application
- 🐳 Creates Docker containers
- 🚀 Deploys to your production server
- ✅ Runs health checks and tests

## 🏗️ Project Structure

```
cicd360/
├── .github/
│   └── workflows/
│       └── docker-deploy.yml     # GitHub Actions workflow
├── scripts/
│   ├── deploy.sh                 # Deployment script
│   └── health-check.sh          # Health check script
├── main.go                      # Simple API application
├── Makefile                     # Build and deployment commands
├── Dockerfile                   # Docker configuration
├── docker-compose.yml           # Docker Compose setup
└── README.md                    # This file
```

## 🚀 Quick Start

### Prerequisites

- Go 1.24+ installed
- Docker and Docker Compose
- SSH access to your production server
- GitHub repository with Actions enabled

### Local Development

1. **Clone the repository:**
   ```bash
   git clone https://github.com/mrbardia72/cicd360.git
   cd cicd360
   ```

2. **Install dependencies:**
   ```bash
   make deps
   ```

3. **Run locally:**
   ```bash
   make run
   ```

4. **Test the API:**
   ```bash
   curl http://localhost:8080/health
   ```

## 🔧 Configuration

### GitHub Secrets

Add these secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SERVER_HOST` | Your production server IP/domain | `192.168.1.100` |
| `SERVER_USER` | SSH username | `ubuntu` |
| `SSH_PRIVATE_KEY` | Private SSH key for server access | `-----BEGIN RSA PRIVATE KEY-----...` |
| `DOCKER_HUB_USERNAME` | Docker Hub username (optional) | `yourusername` |
| `DOCKER_HUB_TOKEN` | Docker Hub access token (optional) | `dckr_pat_...` |

### Server Setup

1. **Ensure Docker is installed on your server:**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   ```

2. **Create deployment directory:**
   ```bash
   mkdir -p /opt/cicd360
   ```

3. **Configure SSH key access** for the deployment user

## 🔄 CI/CD Workflow

### Automatic Deployment Trigger

The deployment automatically triggers when:
- Code is pushed to the `main` branch
- Pull request is merged into `main`

### Deployment Process

1. **Build Stage:**
   - 🏗️ Compile Go application
   - 🧪 Run unit tests
   - 📦 Create Docker image

2. **Deploy Stage:**
   - 🚀 Push image to server
   - 🔄 Update running containers
   - ✅ Perform health checks

3. **Verification:**
   - 🏥 Check application health
   - 📊 Verify API endpoints
   - 📧 Send deployment notifications

## 🛠️ Available Commands

```bash
# Development
make run          # Run application locally
make test         # Run tests
make build        # Build binary
make clean        # Clean build artifacts

# Docker
make docker-build    # Build Docker image
make docker-run      # Run Docker container
make docker-push     # Push to registry

# Deployment
make deploy          # Deploy to production
make health-check    # Check application health
make logs           # View application logs
```

## 📡 API Endpoints

### Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "OK",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "uptime": "2h30m15s"
}
```

### Application Info
```http
GET /info
```

**Response:**
```json
{
  "application": "CICD360",
  "version": "1.0.0",
  "go_version": "go1.24.6",
  "build_time": "2024-01-15T08:00:00Z"
}
```

## 🔍 Monitoring and Logs

### View Application Logs
```bash
# Local development
make logs

# Production server
docker-compose logs -f app
```

### Health Monitoring
The application includes built-in health checks accessible at `/health` endpoint.

## 🚨 Troubleshooting

### Common Issues

1. **Deployment fails with SSH errors:**
   - Verify SSH private key in GitHub secrets
   - Ensure server allows SSH key authentication
   - Check server firewall settings

2. **Docker build fails:**
   - Verify Go modules are properly configured
   - Check Dockerfile syntax
   - Ensure sufficient disk space on server

3. **Application doesn't start:**
   - Check application logs: `make logs`
   - Verify port 8080 is available
   - Check environment variables

### Debug Commands
```bash
# Check deployment status
make status

# Restart application
make restart

# View detailed logs
make logs-detailed
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📧 Email: support@cicd360.com
- 🐛 Issues: [GitHub Issues](https://github.com/mrbardia72/cicd360/issues)
- 📖 Documentation: [Wiki](https://github.com/mrbardia72/cicd360/wiki)

---

Made with ❤️ by [Bardia](https://github.com/mrbardia72)