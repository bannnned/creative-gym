package config

import (
	"errors"
	"os"
)

const (
	defaultAppEnv    = "local"
	defaultHTTPAddr  = ":8080"
	defaultDevUserID = "00000000-0000-0000-0000-000000000001"
)

type Config struct {
	AppEnv    string
	HTTPAddr  string
	DevUserID string
}

func Load() Config {
	return Config{
		AppEnv:    getEnv("APP_ENV", defaultAppEnv),
		HTTPAddr:  getEnv("HTTP_ADDR", defaultHTTPAddr),
		DevUserID: getEnv("DEV_USER_ID", defaultDevUserID),
	}
}

func (c Config) Validate() error {
	if c.AppEnv == "" {
		return errors.New("APP_ENV is required")
	}

	if c.HTTPAddr == "" {
		return errors.New("HTTP_ADDR is required")
	}

	if c.DevUserID == "" {
		return errors.New("DEV_USER_ID is required")
	}

	return nil
}

func getEnv(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	return value
}
