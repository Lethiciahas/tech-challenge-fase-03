package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetDeterministicBucket(t *testing.T) {
	bucket := getDeterministicBucket("user1flagA")
	if bucket < 0 || bucket >= 100 {
		t.Errorf("bucket deveria estar entre 0-99, got: %d", bucket)
	}

	bucket2 := getDeterministicBucket("user1flagA")
	if bucket != bucket2 {
		t.Error("mesmo input deveria gerar mesmo bucket")
	}

	bucket3 := getDeterministicBucket("user2flagA")
	_ = bucket3
}

func TestRunEvaluationLogicFlagDisabled(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test", IsEnabled: false},
	}
	result := app.runEvaluationLogic(info, "user1")
	if result != false {
		t.Error("flag desabilitada deveria retornar false")
	}
}

func TestRunEvaluationLogicFlagNil(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{Flag: nil}
	result := app.runEvaluationLogic(info, "user1")
	if result != false {
		t.Error("flag nil deveria retornar false")
	}
}

func TestRunEvaluationLogicNoRule(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test", IsEnabled: true},
		Rule: nil,
	}
	result := app.runEvaluationLogic(info, "user1")
	if result != true {
		t.Error("flag habilitada sem regra deveria retornar true")
	}
}

func TestRunEvaluationLogicRuleDisabled(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test", IsEnabled: true},
		Rule: &TargetingRule{IsEnabled: false},
	}
	result := app.runEvaluationLogic(info, "user1")
	if result != true {
		t.Error("flag habilitada com regra desabilitada deveria retornar true")
	}
}

func TestRunEvaluationLogicPercentage100(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(100)},
		},
	}
	result := app.runEvaluationLogic(info, "any-user")
	if result != true {
		t.Error("porcentagem 100% deveria retornar true para qualquer user")
	}
}

func TestRunEvaluationLogicPercentage0(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(0)},
		},
	}
	result := app.runEvaluationLogic(info, "any-user")
	if result != false {
		t.Error("porcentagem 0% deveria retornar false para qualquer user")
	}
}

func TestHealthHandler(t *testing.T) {
	app := &App{}

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

func TestEvaluationHandlerMissingParams(t *testing.T) {
	app := &App{}

	req := httptest.NewRequest("GET", "/evaluate", nil)
	w := httptest.NewRecorder()

	app.evaluationHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("esperava status 400, got: %d", w.Code)
	}
}

func TestEvaluationHandlerMissingFlagName(t *testing.T) {
	app := &App{}

	req := httptest.NewRequest("GET", "/evaluate?user_id=u1", nil)
	w := httptest.NewRecorder()

	app.evaluationHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("esperava status 400, got: %d", w.Code)
	}
}

func TestNotFoundError(t *testing.T) {
	err := &NotFoundError{FlagName: "my-flag"}
	expected := "flag ou regra 'my-flag' não encontrada"
	if err.Error() != expected {
		t.Errorf("esperava '%s', got: '%s'", expected, err.Error())
	}
}
