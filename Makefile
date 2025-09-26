# 🚀 CICD360 Makefile
# Automated Golang Deployment Pipeline

# 📋 Variables
APP_NAME := cicd360
VERSION := 1.0.0
GO_VERSION := 1.24
DOCKER_IMAGE := $(APP_NAME):$(VERSION)
DOCKER_REGISTRY := ghcr.io/mrbardia72
PORT := 8080

# 🎨 Colors
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
BLUE := \033[34m
RESET := \033[0m

.PHONY: help deps build test run clean docker-build docker-run docker-push deploy health-check logs status restart

# 🆘 Help
help: ## Show this help message
	@echo "$(BLUE)🚀 CICD360 - Available Commands$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'

# 📦 Dependencies
deps: ## Install dependencies
	@echo "$(YELLOW)📦 Installing dependencies...$(RESET)"
	@go mod download
	@go mod tidy
	@echo "$(GREEN)✅ Dependencies installed!$(RESET)"

# 🏗️ Build
build: ## Build the application
	@echo "$(YELLOW)🏗️ Building $(APP_NAME)...$(RESET)"
	@CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bin/$(APP_NAME) .
	@echo "$(GREEN)✅ Build completed!$(RESET)"

# 🏗️ Build for current OS
build-local: ## Build for current OS
	@echo "$(YELLOW)🏗️ Building $(APP_NAME) for local OS...$(RESET)"
	@go build -o bin/$(APP_NAME) .
	@echo "$(GREEN)✅ Local build completed!$(RESET)"

# 🧪 Test
test: ## Run tests
	@echo "$(YELLOW)🧪 Running tests...$(RESET)"
	@go test -v ./...
	@echo "$(GREEN)✅ All tests passed!$(RESET)"

# 🧪 Test with coverage
test-coverage: ## Run tests with coverage
	@echo "$(YELLOW)🧪 Running tests with coverage...$(RESET)"
	@go test -v -race -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "$(GREEN)✅ Coverage report generated: coverage.html$(RESET)"

# 🚀 Run locally
run: build-local ## Run the application locally
	@echo "$(YELLOW)🚀 Starting $(APP_NAME) on port $(PORT)...$(RESET)"
	@./bin/$(APP_NAME)

# 🚀 Run with hot reload
dev: ## Run with hot reload (requires air)
	@echo "$(YELLOW)🔥 Starting development server with hot reload...$(RESET)"
	@which air > /dev/null || (echo "$(RED)❌ Air not installed. Run: go install github.com/cosmtrek/air@latest$(RESET)" && exit 1)
	@air

# 🧹 Clean
clean: ## Clean build artifacts
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(RESET)"
	@rm -rf bin/
	@rm -f coverage.out coverage.html
	@docker system prune -f 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup completed!$(RESET)"

# 🐳 Docker build
docker-build: ## Build Docker image
	@echo "$(YELLOW)🐳 Building Docker image...$(RESET)"
	@docker build -t $(DOCKER_IMAGE) .
	@docker tag $(DOCKER_IMAGE) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE)
	@echo "$(GREEN)✅ Docker image built: $(DOCKER_IMAGE)$(RESET)"

# 🐳 Docker run
docker-run: docker-build ## Run Docker container
	@echo "$(YELLOW)🐳 Starting Docker container...$(RESET)"
	@docker run --rm -p $(PORT):$(PORT) --name $(APP_NAME) $(DOCKER_IMAGE)

# 🐳 Docker run detached
docker-run-detached: docker-build ## Run Docker container in background
	@echo "$(YELLOW)🐳 Starting Docker container in background...$(RESET)"
	@docker run -d -p $(PORT):$(PORT) --name $(APP_NAME) $(DOCKER_IMAGE)
	@echo "$(GREEN)✅ Container started: $(APP_NAME)$(RESET)"

# 🐳 Docker stop
docker-stop: ## Stop Docker container
	@echo "$(YELLOW)🐳 Stopping Docker container...$(RESET)"
	@docker stop $(APP_NAME) 2>/dev/null || true
	@docker rm $(APP_NAME) 2>/dev/null || true
	@echo "$(GREEN)✅ Container stopped!$(RESET)"

# 🐳 Docker push
docker-push: docker-build ## Push Docker image to registry
	@echo "$(YELLOW)🐳 Pushing Docker image to registry...$(RESET)"
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE)
	@echo "$(GREEN)✅ Image pushed to registry!$(RESET)"

# 🚀 Deploy with Docker Compose
deploy: ## Deploy using Docker Compose
	@echo "$(YELLOW)🚀 Deploying $(APP_NAME)...$(RESET)"
	@docker-compose down 2>/dev/null || true
	@docker-compose up -d --build
	@echo "$(GREEN)✅ Deployment completed!$(RESET)"
	@make health-check

# 🏥 Health check
health-check: ## Check application health
	@echo "$(YELLOW)🏥 Performing health check...$(RESET)"
	@sleep 5
	@curl -f http://localhost:$(PORT)/health > /dev/null 2>&1 && \
		echo "$(GREEN)✅ Application is healthy!$(RESET)" || \
		echo "$(RED)❌ Health check failed!$(RESET)"

# 📊 Status
status: ## Show application status
	@echo "$(YELLOW)📊 Application Status:$(RESET)"
	@docker-compose ps 2>/dev/null || echo "$(RED)❌ Docker Compose not running$(RESET)"
	@echo ""
	@echo "$(YELLOW)🐳 Docker Containers:$(RESET)"
	@docker ps --filter "name=$(APP_NAME)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true

# 📋 Logs
logs: ## View application logs
	@echo "$(YELLOW)📋 Application Logs:$(RESET)"
	@docker-compose logs -f --tail=50 app 2>/dev/null || docker logs -f $(APP_NAME) 2>/dev/null || echo "$(RED)❌ No logs available$(RESET)"

# 📋 Detailed logs
logs-detailed: ## View detailed logs
	@echo "$(YELLOW)📋 Detailed Application Logs:$(RESET)"
	@docker-compose logs --tail=100 app 2>/dev/null || docker logs $(APP_NAME) 2>/dev/null || echo "$(RED)❌ No logs available$(RESET)"

# 🔄 Restart
restart: ## Restart the application
	@echo "$(YELLOW)🔄 Restarting $(APP_NAME)...$(RESET)"
	@docker-compose restart app 2>/dev/null || (docker stop $(APP_NAME) && docker start $(APP_NAME)) 2>/dev/null || echo "$(RED)❌ Failed to restart$(RESET)"
	@echo "$(GREEN)✅ Application restarted!$(RESET)"
	@make health-check

# 🔧 Install tools
install-tools: ## Install development tools
	@echo "$(YELLOW)🔧 Installing development tools...$(RESET)"
	@go install github.com/cosmtrek/air@latest
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@echo "$(GREEN)✅ Development tools installed!$(RESET)"

# 🔍 Lint
lint: ## Run linter
	@echo "$(YELLOW)🔍 Running linter...$(RESET)"
	@which golangci-lint > /dev/null || (echo "$(RED)❌ golangci-lint not installed. Run: make install-tools$(RESET)" && exit 1)
	@golangci-lint run
	@echo "$(GREEN)✅ Linting completed!$(RESET)"

# 🔧 Format
fmt: ## Format code
	@echo "$(YELLOW)🔧 Formatting code...$(RESET)"
	@go fmt ./...
	@echo "$(GREEN)✅ Code formatted!$(RESET)"

# 🏷️ Version
version: ## Show version information
	@echo "$(BLUE)🏷️ Version Information:$(RESET)"
	@echo "App Name: $(APP_NAME)"
	@echo "Version: $(VERSION)"
	@echo "Go Version: $(GO_VERSION)"
	@echo "Docker Image: $(DOCKER_IMAGE)"

# 🧹 Deep clean
deep-clean: clean ## Deep clean (remove Docker images and volumes)
	@echo "$(YELLOW)🧹 Performing deep clean...$(RESET)"
	@docker-compose down -v --rmi all 2>/dev/null || true
	@docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	@docker rmi $(DOCKER_REGISTRY)/$(DOCKER_IMAGE) 2>/dev/null || true
	@docker system prune -af --volumes 2>/dev/null || true
	@echo "$(GREEN)✅ Deep cleanup completed!$(RESET)"

# 🚀 Quick start
start: deps build docker-build deploy ## Quick start (deps + build + deploy)
	@echo "$(GREEN)🎉 $(APP_NAME) is ready!$(RESET)"
	@echo "$(BLUE)🌐 Access your application at: http://localhost:$(PORT)$(RESET)"

# 📈 Benchmark
bench: ## Run benchmarks
	@echo "$(YELLOW)📈 Running benchmarks...$(RESET)"
	@go test -bench=. -benchmem ./...
	@echo "$(GREEN)✅ Benchmarks completed!$(RESET)"
