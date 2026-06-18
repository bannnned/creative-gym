package config

import (
	"errors"
	"os"
	"strings"
)

const (
	defaultAppEnv    = "local"
	defaultHTTPAddr  = ":8080"
	defaultDBURL     = "postgres://creative_gym:creative_gym@localhost:5432/creative_gym?sslmode=disable"
	defaultDevUserID = "00000000-0000-0000-0000-000000000001"
)

type Config struct {
	AppEnv             string
	HTTPAddr           string
	DatabaseURL        string
	DevUserID          string
	CORSAllowedOrigins []string
	WebStaticDir       string
	S3                 S3Config
}

type S3Config struct {
	Endpoint  string
	Region    string
	Bucket    string
	AccessKey string
	SecretKey string
}

func Load() Config {
	return Config{
		AppEnv:             getEnv("APP_ENV", defaultAppEnv),
		HTTPAddr:           getHTTPAddr(),
		DatabaseURL:        getEnv("DATABASE_URL", defaultDBURL),
		DevUserID:          getEnv("DEV_USER_ID", defaultDevUserID),
		CORSAllowedOrigins: splitCSV(os.Getenv("CORS_ALLOWED_ORIGINS")),
		WebStaticDir:       os.Getenv("WEB_STATIC_DIR"),
		S3: S3Config{
			Endpoint:  os.Getenv("S3_ENDPOINT"),
			Region:    os.Getenv("S3_REGION"),
			Bucket:    os.Getenv("S3_BUCKET"),
			AccessKey: os.Getenv("S3_ACCESS_KEY"),
			SecretKey: os.Getenv("S3_SECRET_KEY"),
		},
	}
}

func (c Config) Validate() error {
	if c.AppEnv == "" {
		return errors.New("APP_ENV is required")
	}

	if c.HTTPAddr == "" {
		return errors.New("HTTP_ADDR is required")
	}

	if c.DatabaseURL == "" {
		return errors.New("DATABASE_URL is required")
	}

	if c.DevUserID == "" {
		return errors.New("DEV_USER_ID is required")
	}

	return nil
}

func (c S3Config) Enabled() bool {
	return c.Endpoint != "" ||
		c.Region != "" ||
		c.Bucket != "" ||
		c.AccessKey != "" ||
		c.SecretKey != ""
}

func (c S3Config) Complete() bool {
	return c.Endpoint != "" &&
		c.Region != "" &&
		c.Bucket != "" &&
		c.AccessKey != "" &&
		c.SecretKey != ""
}

func getEnv(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	return value
}

func getHTTPAddr() string {
	if value := os.Getenv("HTTP_ADDR"); value != "" {
		return value
	}

	if port := os.Getenv("PORT"); port != "" {
		return ":" + port
	}

	return defaultHTTPAddr
}

func splitCSV(value string) []string {
	if value == "" {
		return nil
	}

	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			result = append(result, part)
		}
	}

	return result
}
