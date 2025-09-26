# 🚀 Multi-stage build for CICD360
FROM golang:1.24-alpine AS builder

# 📦 Install dependencies
RUN apk add --no-cache git ca-certificates tzdata

# 🔧 Set working directory
WORKDIR /app

# 📁 Copy all source files
COPY . .

# 📦 Download dependencies
RUN go mod download && go mod tidy

# 🏗️ Build arguments
ARG VERSION=dev
ARG BUILD_TIME=unknown

# 🏗️ Build the application with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -a -installsuffix cgo \
    -ldflags="-w -s -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME}" \
    -o cicd360 .

# 🐳 Final stage - minimal runtime image
FROM alpine:3.19

# 📦 Install runtime dependencies
RUN apk --no-cache add \
    ca-certificates \
    tzdata \
    curl \
    && rm -rf /var/cache/apk/*

# 👤 Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 📁 Set working directory
WORKDIR /app

# 📋 Copy binary from builder stage
COPY --from=builder /app/cicd360 .

# 🔐 Set proper ownership and permissions
RUN chown -R appuser:appgroup /app && \
    chmod +x cicd360

# 👤 Switch to non-root user
USER appuser

# 🌐 Expose port
EXPOSE 8080

# 🏥 Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 🏷️ Labels for better image management
LABEL maintainer="Bardia <bardia@example.com>"
LABEL app.name="CICD360"
LABEL app.version="${VERSION}"
LABEL app.build-time="${BUILD_TIME}"
LABEL app.description="Automated Golang Deployment Pipeline"

# 🚀 Run the application
CMD ["./cicd360"]
