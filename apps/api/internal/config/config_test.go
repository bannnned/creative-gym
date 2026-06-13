package config

import "testing"

func TestLoadUsesDefaults(t *testing.T) {
	t.Setenv("APP_ENV", "")
	t.Setenv("HTTP_ADDR", "")
	t.Setenv("DATABASE_URL", "")
	t.Setenv("DEV_USER_ID", "")

	cfg := Load()

	if cfg.AppEnv != defaultAppEnv {
		t.Fatalf("AppEnv = %q, want %q", cfg.AppEnv, defaultAppEnv)
	}

	if cfg.HTTPAddr != defaultHTTPAddr {
		t.Fatalf("HTTPAddr = %q, want %q", cfg.HTTPAddr, defaultHTTPAddr)
	}

	if cfg.DatabaseURL != defaultDBURL {
		t.Fatalf("DatabaseURL = %q, want %q", cfg.DatabaseURL, defaultDBURL)
	}

	if cfg.DevUserID != defaultDevUserID {
		t.Fatalf("DevUserID = %q, want %q", cfg.DevUserID, defaultDevUserID)
	}
}

func TestLoadUsesEnvironment(t *testing.T) {
	t.Setenv("APP_ENV", "test")
	t.Setenv("HTTP_ADDR", ":9090")
	t.Setenv("DATABASE_URL", "postgres://example")
	t.Setenv("DEV_USER_ID", "11111111-1111-1111-1111-111111111111")

	cfg := Load()

	if cfg.AppEnv != "test" {
		t.Fatalf("AppEnv = %q, want test", cfg.AppEnv)
	}

	if cfg.HTTPAddr != ":9090" {
		t.Fatalf("HTTPAddr = %q, want :9090", cfg.HTTPAddr)
	}

	if cfg.DatabaseURL != "postgres://example" {
		t.Fatalf("DatabaseURL = %q, want postgres://example", cfg.DatabaseURL)
	}

	if cfg.DevUserID != "11111111-1111-1111-1111-111111111111" {
		t.Fatalf("DevUserID = %q, want custom value", cfg.DevUserID)
	}
}

func TestValidateRequiresValues(t *testing.T) {
	cfg := Config{}

	if err := cfg.Validate(); err == nil {
		t.Fatal("Validate() error = nil, want error")
	}
}
