package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"runtime"
	"time"
)

// HealthResponse represents the health check response
type HealthResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
	Version   string `json:"version"`
	Uptime    string `json:"uptime"`
}

// InfoResponse represents the application info response
type InfoResponse struct {
	Application string `json:"application"`
	Version     string `json:"version"`
	GoVersion   string `json:"go_version"`
	BuildTime   string `json:"build_time"`
	Environment string `json:"environment"`
}

var (
	startTime   = time.Now()
	version     = "1.0.0"
	buildTime   = time.Now().Format(time.RFC3339)
	appName     = "CICD360"
	environment = getEnv("ENVIRONMENT", "development")
)

// getEnv gets environment variable with fallback
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

// healthHandler handles health check requests
func healthHandler(w http.ResponseWriter, r *http.Request) {
	uptime := time.Since(startTime)

	response := HealthResponse{
		Status:    "OK",
		Timestamp: time.Now().Format(time.RFC3339),
		Version:   version,
		Uptime:    uptime.String(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding health response: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
}

// infoHandler handles application info requests
func infoHandler(w http.ResponseWriter, r *http.Request) {
	response := InfoResponse{
		Application: appName,
		Version:     version,
		GoVersion:   runtime.Version(),
		BuildTime:   buildTime,
		Environment: environment,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding info response: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
}

// homeHandler handles root path requests
func homeHandler(w http.ResponseWriter, r *http.Request) {
	message := map[string]string{
		"message":     "Welcome to CICD360! 🚀",
		"description": "Automated Golang Deployment Pipeline",
		"endpoints":   "/health, /info",
		"version":     version,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	if err := json.NewEncoder(w).Encode(message); err != nil {
		log.Printf("Error encoding home response: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
}

// loggingMiddleware logs HTTP requests
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Call the next handler
		next.ServeHTTP(w, r)

		// Log the request
		log.Printf(
			"%s %s %s %v",
			r.Method,
			r.RequestURI,
			r.RemoteAddr,
			time.Since(start),
		)
	})
}

// corsMiddleware adds CORS headers
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	// Get port from environment variable or use default
	port := getEnv("PORT", "8080")

	// Create a new ServeMux
	mux := http.NewServeMux()

	// Register handlers
	mux.HandleFunc("/", homeHandler)
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/info", infoHandler)

	// Apply middleware
	handler := loggingMiddleware(corsMiddleware(mux))

	// Create server
	server := &http.Server{
		Addr:         ":" + port,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Log startup information
	log.Printf("🚀 Starting %s v%s", appName, version)
	log.Printf("🌍 Environment: %s", environment)
	log.Printf("🔧 Go version: %s", runtime.Version())
	log.Printf("📅 Build time: %s", buildTime)
	log.Printf("🌐 Server starting on port %s", port)
	log.Printf("🔗 Health check: http://localhost:%s/health", port)
	log.Printf("ℹ️  App info: http://localhost:%s/info", port)

	// Start the server
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("❌ Server failed to start: %v", err)
	}
}
