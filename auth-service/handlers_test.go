package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestGenerateAPIKey(t *testing.T) {
	key, err := generateAPIKey()
	if err != nil {
		t.Fatalf("erro ao gerar chave: %v", err)
	}
	if !strings.HasPrefix(key, "tm_key_") {
		t.Errorf("chave deveria ter prefixo 'tm_key_', got: %s", key)
	}
	if len(key) != 71 {
		t.Errorf("chave deveria ter 71 chars (7 prefixo + 64 hex), got: %d", len(key))
	}
}

func TestGenerateAPIKeyUniqueness(t *testing.T) {
	key1, _ := generateAPIKey()
	key2, _ := generateAPIKey()
	if key1 == key2 {
		t.Error("duas chaves geradas não deveriam ser iguais")
	}
}

func TestHashAPIKey(t *testing.T) {
	hash := hashAPIKey("test-key")
	if len(hash) != 64 {
		t.Errorf("hash deveria ter 64 chars, got: %d", len(hash))
	}

	hash2 := hashAPIKey("test-key")
	if hash != hash2 {
		t.Error("hash deveria ser determinístico")
	}

	hash3 := hashAPIKey("different-key")
	if hash == hash3 {
		t.Error("chaves diferentes deveriam gerar hashes diferentes")
	}
}

func TestHealthHandler(t *testing.T) {
	app := &App{MasterKey: "test"}

	req := httptest.NewRequest("GET", "/health", nil)
	w := httptest.NewRecorder()

	app.healthHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("esperava status 200, got: %d", w.Code)
	}

	var body map[string]string
	json.NewDecoder(w.Body).Decode(&body)
	if body["status"] != "ok" {
		t.Errorf("esperava status 'ok', got: %s", body["status"])
	}
}

func TestMasterKeyMiddlewareReject(t *testing.T) {
	app := &App{MasterKey: "secret-master"}

	handler := app.masterKeyAuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest("POST", "/admin/keys", nil)
	req.Header.Set("Authorization", "Bearer wrong-key")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusForbidden {
		t.Errorf("esperava status 403, got: %d", w.Code)
	}
}

func TestMasterKeyMiddlewareAccept(t *testing.T) {
	app := &App{MasterKey: "secret-master"}

	handler := app.masterKeyAuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest("POST", "/admin/keys", nil)
	req.Header.Set("Authorization", "Bearer secret-master")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("esperava status 200, got: %d", w.Code)
	}
}

func TestCreateKeyHandlerMethodNotAllowed(t *testing.T) {
	app := &App{MasterKey: "test"}

	req := httptest.NewRequest("GET", "/admin/keys", nil)
	w := httptest.NewRecorder()

	app.createKeyHandler(w, req)

	if w.Code != http.StatusMethodNotAllowed {
		t.Errorf("esperava status 405, got: %d", w.Code)
	}
}

func TestCreateKeyHandlerEmptyName(t *testing.T) {
	app := &App{MasterKey: "test"}

	body := strings.NewReader(`{"name":""}`)
	req := httptest.NewRequest("POST", "/admin/keys", body)
	w := httptest.NewRecorder()

	app.createKeyHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("esperava status 400, got: %d", w.Code)
	}
}

func TestValidateKeyHandlerNoAuth(t *testing.T) {
	app := &App{MasterKey: "test"}

	req := httptest.NewRequest("GET", "/validate", nil)
	w := httptest.NewRecorder()

	app.validateKeyHandler(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("esperava status 401, got: %d", w.Code)
	}
}
