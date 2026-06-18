package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"creative-gym/apps/api/internal/config"
	"creative-gym/apps/api/internal/db"
	"creative-gym/apps/api/internal/httpapi"
)

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	logger.Info("api process starting")

	cfg := config.Load()
	if err := cfg.Validate(); err != nil {
		logger.Error("invalid config", "error", err)
		os.Exit(1)
	}
	logger.Info(
		"config loaded",
		"addr",
		cfg.HTTPAddr,
		"env",
		cfg.AppEnv,
		"web_static_dir_set",
		cfg.WebStaticDir != "",
		"s3_enabled",
		cfg.S3.Enabled(),
		"s3_complete",
		cfg.S3.Complete(),
	)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	dbPool, err := db.Connect(ctx, cfg)
	if err != nil {
		logger.Error("database connection failed", "error", err)
		os.Exit(1)
	}
	defer dbPool.Close()

	server := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           httpapi.NewRouter(cfg, logger, dbPool),
		ReadHeaderTimeout: 5 * time.Second,
	}

	go func() {
		logger.Info("api server starting", "addr", cfg.HTTPAddr, "env", cfg.AppEnv)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("api server stopped unexpectedly", "error", err)
			os.Exit(1)
		}
	}()

	<-ctx.Done()

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		logger.Error("api server shutdown failed", "error", err)
		os.Exit(1)
	}

	logger.Info("api server stopped")
}
