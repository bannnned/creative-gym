package config

import "testing"

func TestLoadUsesDefaults(t *testing.T) {
	t.Setenv("APP_ENV", "")
	t.Setenv("HTTP_ADDR", "")
	t.Setenv("PORT", "")
	t.Setenv("DATABASE_URL", "")
	t.Setenv("DATABASE_URL_HEX", "")
	t.Setenv("DEV_USER_ID", "")
	t.Setenv("CORS_ALLOWED_ORIGINS", "")
	t.Setenv("WEB_STATIC_DIR", "")
	t.Setenv("S3_ENDPOINT", "")
	t.Setenv("S3_REGION", "")
	t.Setenv("S3_BUCKET", "")
	t.Setenv("S3_ACCESS_KEY", "")
	t.Setenv("S3_SECRET_KEY", "")
	t.Setenv("S3_ACCESS_KEY_HEX", "")
	t.Setenv("S3_SECRET_KEY_HEX", "")

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

	if len(cfg.CORSAllowedOrigins) != 0 {
		t.Fatalf("CORSAllowedOrigins = %v, want empty", cfg.CORSAllowedOrigins)
	}

	if cfg.WebStaticDir != "" {
		t.Fatalf("WebStaticDir = %q, want empty", cfg.WebStaticDir)
	}

	if cfg.S3.Enabled() {
		t.Fatalf("S3.Enabled() = true, want false")
	}
}

func TestLoadUsesEnvironment(t *testing.T) {
	t.Setenv("APP_ENV", "test")
	t.Setenv("HTTP_ADDR", ":9090")
	t.Setenv("PORT", "8081")
	t.Setenv("DATABASE_URL", "postgres://example")
	t.Setenv("DATABASE_URL_HEX", "")
	t.Setenv("DEV_USER_ID", "11111111-1111-1111-1111-111111111111")
	t.Setenv("CORS_ALLOWED_ORIGINS", "https://app.example.com, http://localhost:3000")
	t.Setenv("WEB_STATIC_DIR", "/app/web")
	t.Setenv("S3_ENDPOINT", "https://s3.example.com")
	t.Setenv("S3_REGION", "ru-1")
	t.Setenv("S3_BUCKET", "creative-gym-media")
	t.Setenv("S3_ACCESS_KEY", "access-key")
	t.Setenv("S3_SECRET_KEY", "secret-key")
	t.Setenv("S3_ACCESS_KEY_HEX", "")
	t.Setenv("S3_SECRET_KEY_HEX", "")

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

	if len(cfg.CORSAllowedOrigins) != 2 {
		t.Fatalf("CORSAllowedOrigins = %v, want 2 origins", cfg.CORSAllowedOrigins)
	}

	if cfg.CORSAllowedOrigins[0] != "https://app.example.com" {
		t.Fatalf("first origin = %q, want https://app.example.com", cfg.CORSAllowedOrigins[0])
	}

	if cfg.WebStaticDir != "/app/web" {
		t.Fatalf("WebStaticDir = %q, want /app/web", cfg.WebStaticDir)
	}

	if cfg.S3.Endpoint != "https://s3.example.com" {
		t.Fatalf("S3.Endpoint = %q, want https://s3.example.com", cfg.S3.Endpoint)
	}

	if cfg.S3.Bucket != "creative-gym-media" {
		t.Fatalf("S3.Bucket = %q, want creative-gym-media", cfg.S3.Bucket)
	}
}

func TestLoadUsesHexEncodedDatabaseURL(t *testing.T) {
	t.Setenv("DATABASE_URL", "")
	t.Setenv("DATABASE_URL_HEX", "706f7374677265733a2f2f6578616d706c65")

	cfg := Load()

	if cfg.DatabaseURL != "postgres://example" {
		t.Fatalf("DatabaseURL = %q, want postgres://example", cfg.DatabaseURL)
	}
}

func TestLoadUsesHexEncodedS3Keys(t *testing.T) {
	t.Setenv("S3_ACCESS_KEY", "")
	t.Setenv("S3_SECRET_KEY", "")
	t.Setenv("S3_ACCESS_KEY_HEX", "6163636573732d6b6579")
	t.Setenv("S3_SECRET_KEY_HEX", "7365637265742d6b6579")

	cfg := Load()

	if cfg.S3.AccessKey != "access-key" {
		t.Fatalf("S3.AccessKey = %q, want access-key", cfg.S3.AccessKey)
	}

	if cfg.S3.SecretKey != "secret-key" {
		t.Fatalf("S3.SecretKey = %q, want secret-key", cfg.S3.SecretKey)
	}
}

func TestLoadUsesPortWhenHTTPAddrIsMissing(t *testing.T) {
	t.Setenv("HTTP_ADDR", "")
	t.Setenv("PORT", "9091")

	cfg := Load()

	if cfg.HTTPAddr != ":9091" {
		t.Fatalf("HTTPAddr = %q, want :9091", cfg.HTTPAddr)
	}
}

func TestValidateRequiresValues(t *testing.T) {
	cfg := Config{}

	if err := cfg.Validate(); err == nil {
		t.Fatal("Validate() error = nil, want error")
	}
}

func TestValidateAllowsPartialS3Config(t *testing.T) {
	cfg := Config{
		AppEnv:      "test",
		HTTPAddr:    ":8080",
		DatabaseURL: "postgres://example",
		DevUserID:   "11111111-1111-1111-1111-111111111111",
		S3: S3Config{
			Endpoint: "https://s3.example.com",
		},
	}

	if err := cfg.Validate(); err != nil {
		t.Fatalf("Validate() error = %v, want nil", err)
	}

	if !cfg.S3.Enabled() {
		t.Fatal("S3.Enabled() = false, want true")
	}

	if cfg.S3.Complete() {
		t.Fatal("S3.Complete() = true, want false")
	}
}
