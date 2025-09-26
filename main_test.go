package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"
)

func TestHealthHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/health", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(healthHandler)

	handler.ServeHTTP(rr, req)

	// Check status code
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	// Check content type
	expected := "application/json"
	if contentType := rr.Header().Get("Content-Type"); contentType != expected {
		t.Errorf("handler returned wrong content type: got %v want %v",
			contentType, expected)
	}

	// Check response body
	var response HealthResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Could not parse response: %v", err)
	}

	if response.Status != "OK" {
		t.Errorf("Expected status 'OK', got %v", response.Status)
	}

	if response.Version != version {
		t.Errorf("Expected version '%v', got %v", version, response.Version)
	}
}

func TestInfoHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/info", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(infoHandler)

	handler.ServeHTTP(rr, req)

	// Check status code
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	// Check content type
	expected := "application/json"
	if contentType := rr.Header().Get("Content-Type"); contentType != expected {
		t.Errorf("handler returned wrong content type: got %v want %v",
			contentType, expected)
	}

	// Check response body
	var response InfoResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Could not parse response: %v", err)
	}

	if response.Application != appName {
		t.Errorf("Expected application name '%v', got %v", appName, response.Application)
	}

	if response.Version != version {
		t.Errorf("Expected version '%v', got %v", version, response.Version)
	}

	if response.Environment != environment {
		t.Errorf("Expected environment '%v', got %v", environment, response.Environment)
	}
}

func TestHomeHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(homeHandler)

	handler.ServeHTTP(rr, req)

	// Check status code
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	// Check content type
	expected := "application/json"
	if contentType := rr.Header().Get("Content-Type"); contentType != expected {
		t.Errorf("handler returned wrong content type: got %v want %v",
			contentType, expected)
	}

	// Check response body structure
	var response map[string]string
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Could not parse response: %v", err)
	}

	expectedKeys := []string{"message", "description", "endpoints", "version"}
	for _, key := range expectedKeys {
		if _, exists := response[key]; !exists {
			t.Errorf("Expected key '%v' not found in response", key)
		}
	}

	if response["version"] != version {
		t.Errorf("Expected version '%v', got %v", version, response["version"])
	}
}

func TestLoggingMiddleware(t *testing.T) {
	handler := loggingMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("test"))
	}))

	req, err := http.NewRequest("GET", "/test", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("middleware affected status code: got %v want %v",
			status, http.StatusOK)
	}

	if body := rr.Body.String(); body != "test" {
		t.Errorf("middleware affected response body: got %v want %v",
			body, "test")
	}
}

func TestCorsMiddleware(t *testing.T) {
	handler := corsMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("test"))
	}))

	req, err := http.NewRequest("GET", "/test", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	// Check CORS headers
	corsHeaders := map[string]string{
		"Access-Control-Allow-Origin":  "*",
		"Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
		"Access-Control-Allow-Headers": "Content-Type, Authorization",
	}

	for header, expectedValue := range corsHeaders {
		if actualValue := rr.Header().Get(header); actualValue != expectedValue {
			t.Errorf("CORS header %v: got %v want %v",
				header, actualValue, expectedValue)
		}
	}
}

func TestCorsOptionsRequest(t *testing.T) {
	handler := corsMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("Handler should not be called for OPTIONS request")
	}))

	req, err := http.NewRequest("OPTIONS", "/test", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("OPTIONS request returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}
}

func TestGetEnv(t *testing.T) {
	// Test with existing environment variable
	os.Setenv("TEST_VAR", "test_value")
	defer os.Unsetenv("TEST_VAR")

	result := getEnv("TEST_VAR", "default_value")
	if result != "test_value" {
		t.Errorf("getEnv failed: got %v want %v", result, "test_value")
	}

	// Test with non-existing environment variable
	result = getEnv("NON_EXISTING_VAR", "default_value")
	if result != "default_value" {
		t.Errorf("getEnv failed: got %v want %v", result, "default_value")
	}
}

func TestHealthResponseStruct(t *testing.T) {
	response := HealthResponse{
		Status:    "OK",
		Timestamp: time.Now().Format(time.RFC3339),
		Version:   "1.0.0",
		Uptime:    "1h30m",
	}

	// Test JSON marshaling
	jsonData, err := json.Marshal(response)
	if err != nil {
		t.Errorf("Failed to marshal HealthResponse: %v", err)
	}

	// Test JSON unmarshaling
	var unmarshaled HealthResponse
	if err := json.Unmarshal(jsonData, &unmarshaled); err != nil {
		t.Errorf("Failed to unmarshal HealthResponse: %v", err)
	}

	if unmarshaled.Status != response.Status {
		t.Errorf("Unmarshal failed for Status: got %v want %v",
			unmarshaled.Status, response.Status)
	}
}

func TestInfoResponseStruct(t *testing.T) {
	response := InfoResponse{
		Application: "CICD360",
		Version:     "1.0.0",
		GoVersion:   "go1.24",
		BuildTime:   time.Now().Format(time.RFC3339),
		Environment: "test",
	}

	// Test JSON marshaling
	jsonData, err := json.Marshal(response)
	if err != nil {
		t.Errorf("Failed to marshal InfoResponse: %v", err)
	}

	// Test JSON unmarshaling
	var unmarshaled InfoResponse
	if err := json.Unmarshal(jsonData, &unmarshaled); err != nil {
		t.Errorf("Failed to unmarshal InfoResponse: %v", err)
	}

	if unmarshaled.Application != response.Application {
		t.Errorf("Unmarshal failed for Application: got %v want %v",
			unmarshaled.Application, response.Application)
	}
}

// Benchmark tests
func BenchmarkHealthHandler(b *testing.B) {
	req, _ := http.NewRequest("GET", "/health", nil)
	handler := http.HandlerFunc(healthHandler)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)
	}
}

func BenchmarkInfoHandler(b *testing.B) {
	req, _ := http.NewRequest("GET", "/info", nil)
	handler := http.HandlerFunc(infoHandler)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)
	}
}

func BenchmarkHomeHandler(b *testing.B) {
	req, _ := http.NewRequest("GET", "/", nil)
	handler := http.HandlerFunc(homeHandler)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)
	}
}

// Test suite runner
func TestMain(m *testing.M) {
	// Setup test environment
	originalStartTime := startTime
	startTime = time.Now()

	// Run tests
	code := m.Run()

	// Cleanup
	startTime = originalStartTime

	os.Exit(code)
}
