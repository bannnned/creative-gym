package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"strings"
	"time"

	"creative-gym/apps/api/internal/config"
	"creative-gym/apps/api/internal/storage"
)

const backupContentType = "application/vnd.postgresql.custom"

type objectStore interface {
	Bucket() string
	Put(ctx context.Context, key string, body io.Reader, contentType string, byteSize int64) error
	Get(ctx context.Context, bucket string, key string) (storage.Object, error)
}

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	if len(os.Args) != 4 {
		printUsage()
		os.Exit(2)
	}

	cfg := config.Load()
	if !cfg.S3.Complete() {
		logger.Error("backup storage is not configured")
		os.Exit(1)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	store, err := storage.NewS3ObjectStore(ctx, cfg.S3)
	if err != nil {
		logger.Error("backup storage init failed", "error", err)
		os.Exit(1)
	}

	switch os.Args[1] {
	case "upload":
		err = upload(ctx, store, os.Args[2], os.Args[3])
	case "verify":
		err = verify(ctx, store, os.Args[2], os.Args[3])
	case "download":
		err = download(ctx, store, os.Args[2], os.Args[3])
	default:
		printUsage()
		os.Exit(2)
	}

	if err != nil {
		logger.Error("backup command failed", "command", os.Args[1], "error", err)
		os.Exit(1)
	}

	logger.Info("backup command completed", "command", os.Args[1])
}

func upload(
	ctx context.Context,
	store objectStore,
	filePath string,
	objectKey string,
) error {
	file, err := os.Open(filePath)
	if err != nil {
		return fmt.Errorf("open backup: %w", err)
	}
	defer file.Close()

	info, err := file.Stat()
	if err != nil {
		return fmt.Errorf("stat backup: %w", err)
	}
	if info.Size() <= 0 {
		return errors.New("backup is empty")
	}

	if err := store.Put(ctx, objectKey, file, backupContentType, info.Size()); err != nil {
		return fmt.Errorf("upload backup: %w", err)
	}

	return nil
}

func verify(
	ctx context.Context,
	store objectStore,
	expectedSHA256 string,
	objectKey string,
) error {
	expectedSHA256 = strings.ToLower(strings.TrimSpace(expectedSHA256))
	if len(expectedSHA256) != sha256.Size*2 {
		return errors.New("expected SHA-256 is invalid")
	}

	object, err := store.Get(ctx, store.Bucket(), objectKey)
	if err != nil {
		return fmt.Errorf("download backup for verification: %w", err)
	}
	defer object.Body.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, object.Body); err != nil {
		return fmt.Errorf("hash downloaded backup: %w", err)
	}

	actual := hex.EncodeToString(hash.Sum(nil))
	if actual != expectedSHA256 {
		return fmt.Errorf("backup checksum mismatch: got %s", actual)
	}

	return nil
}

func download(
	ctx context.Context,
	store objectStore,
	objectKey string,
	outputPath string,
) error {
	object, err := store.Get(ctx, store.Bucket(), objectKey)
	if err != nil {
		return fmt.Errorf("download backup: %w", err)
	}
	defer object.Body.Close()

	file, err := os.OpenFile(outputPath, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if err != nil {
		return fmt.Errorf("create backup file: %w", err)
	}

	if _, err := io.Copy(file, object.Body); err != nil {
		file.Close()
		os.Remove(outputPath)
		return fmt.Errorf("write backup file: %w", err)
	}
	if err := file.Close(); err != nil {
		os.Remove(outputPath)
		return fmt.Errorf("close backup file: %w", err)
	}

	return nil
}

func printUsage() {
	fmt.Fprintln(os.Stderr, "usage:")
	fmt.Fprintln(os.Stderr, "  backup upload <file> <object-key>")
	fmt.Fprintln(os.Stderr, "  backup verify <sha256> <object-key>")
	fmt.Fprintln(os.Stderr, "  backup download <object-key> <file>")
}
