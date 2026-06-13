package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"creative-gym/apps/api/internal/config"
	"github.com/jackc/pgx/v5"
)

const migrationsTableSQL = `
CREATE TABLE IF NOT EXISTS schema_migrations (
  version text PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now()
);`

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	if len(os.Args) < 2 {
		printUsage()
		os.Exit(2)
	}

	cfg := config.Load()
	if err := cfg.Validate(); err != nil {
		logger.Error("invalid config", "error", err)
		os.Exit(1)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	connConfig, err := pgx.ParseConfig(cfg.DatabaseURL)
	if err != nil {
		logger.Error("database config parse failed", "error", err)
		os.Exit(1)
	}
	connConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol

	conn, err := pgx.ConnectConfig(ctx, connConfig)
	if err != nil {
		logger.Error("database connection failed", "error", err)
		os.Exit(1)
	}
	defer conn.Close(context.Background())

	switch os.Args[1] {
	case "migrate":
		err = migrate(ctx, conn, logger, "migrations")
	case "seed":
		err = seed(ctx, conn, logger, "seeds")
	default:
		printUsage()
		os.Exit(2)
	}

	if err != nil {
		logger.Error("db command failed", "command", os.Args[1], "error", err)
		os.Exit(1)
	}
}

func migrate(ctx context.Context, conn *pgx.Conn, logger *slog.Logger, dir string) error {
	if _, err := conn.Exec(ctx, migrationsTableSQL); err != nil {
		return fmt.Errorf("create schema_migrations table: %w", err)
	}

	files, err := sqlFiles(dir, ".up.sql")
	if err != nil {
		return err
	}

	for _, file := range files {
		version := strings.TrimSuffix(filepath.Base(file), ".up.sql")

		applied, err := migrationApplied(ctx, conn, version)
		if err != nil {
			return err
		}

		if applied {
			logger.Info("migration already applied", "version", version)
			continue
		}

		sqlBytes, err := os.ReadFile(file)
		if err != nil {
			return fmt.Errorf("read migration %s: %w", file, err)
		}

		tx, err := conn.Begin(ctx)
		if err != nil {
			return fmt.Errorf("begin migration %s: %w", version, err)
		}

		if _, err := tx.Exec(ctx, string(sqlBytes)); err != nil {
			rollback(ctx, tx)
			return fmt.Errorf("apply migration %s: %w", version, err)
		}

		if _, err := tx.Exec(ctx, "INSERT INTO schema_migrations (version) VALUES ($1)", version); err != nil {
			rollback(ctx, tx)
			return fmt.Errorf("record migration %s: %w", version, err)
		}

		if err := tx.Commit(ctx); err != nil {
			return fmt.Errorf("commit migration %s: %w", version, err)
		}

		logger.Info("migration applied", "version", version)
	}

	return nil
}

func seed(ctx context.Context, conn *pgx.Conn, logger *slog.Logger, dir string) error {
	files, err := sqlFiles(dir, ".sql")
	if err != nil {
		return err
	}

	for _, file := range files {
		sqlBytes, err := os.ReadFile(file)
		if err != nil {
			return fmt.Errorf("read seed %s: %w", file, err)
		}

		if _, err := conn.Exec(ctx, string(sqlBytes)); err != nil {
			return fmt.Errorf("apply seed %s: %w", file, err)
		}

		logger.Info("seed applied", "file", filepath.Base(file))
	}

	return nil
}

func sqlFiles(dir string, suffix string) ([]string, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("read %s directory: %w", dir, err)
	}

	files := make([]string, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		name := entry.Name()
		if strings.HasSuffix(name, suffix) {
			files = append(files, filepath.Join(dir, name))
		}
	}

	sort.Strings(files)
	return files, nil
}

func migrationApplied(ctx context.Context, conn *pgx.Conn, version string) (bool, error) {
	var applied bool
	err := conn.QueryRow(ctx, "SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = $1)", version).Scan(&applied)
	if err != nil {
		return false, fmt.Errorf("check migration %s: %w", version, err)
	}

	return applied, nil
}

func rollback(ctx context.Context, tx pgx.Tx) {
	if err := tx.Rollback(ctx); err != nil && !errors.Is(err, pgx.ErrTxClosed) {
		slog.Error("transaction rollback failed", "error", err)
	}
}

func printUsage() {
	fmt.Fprintln(os.Stderr, "usage: go run ./cmd/db <migrate|seed>")
}
