package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"os"
	"path/filepath"
	"testing"

	"creative-gym/apps/api/internal/storage"
)

type memoryStore struct {
	bucket      string
	objects     map[string][]byte
	contentType string
}

func (s *memoryStore) Bucket() string {
	return s.bucket
}

func (s *memoryStore) Put(_ context.Context, key string, body io.Reader, contentType string, _ int64) error {
	data, err := io.ReadAll(body)
	if err != nil {
		return err
	}
	s.objects[key] = data
	s.contentType = contentType
	return nil
}

func (s *memoryStore) Get(_ context.Context, _ string, key string) (storage.Object, error) {
	data := s.objects[key]
	return storage.Object{
		Body:          io.NopCloser(bytes.NewReader(data)),
		ContentType:   s.contentType,
		ContentLength: int64(len(data)),
	}, nil
}

func TestUploadAndVerifyBackup(t *testing.T) {
	backup := []byte("postgres custom archive")
	path := filepath.Join(t.TempDir(), "backup.dump")
	if err := os.WriteFile(path, backup, 0o600); err != nil {
		t.Fatal(err)
	}

	store := &memoryStore{
		bucket:  "private-bucket",
		objects: make(map[string][]byte),
	}
	if err := upload(context.Background(), store, path, "database-backups/backup.dump"); err != nil {
		t.Fatalf("upload() error = %v", err)
	}

	if store.contentType != backupContentType {
		t.Fatalf("content type = %q, want %q", store.contentType, backupContentType)
	}

	sum := sha256.Sum256(backup)
	if err := verify(
		context.Background(),
		store,
		hex.EncodeToString(sum[:]),
		"database-backups/backup.dump",
	); err != nil {
		t.Fatalf("verify() error = %v", err)
	}
}

func TestVerifyRejectsChecksumMismatch(t *testing.T) {
	store := &memoryStore{
		bucket: "private-bucket",
		objects: map[string][]byte{
			"database-backups/backup.dump": []byte("backup"),
		},
	}

	err := verify(
		context.Background(),
		store,
		string(bytes.Repeat([]byte("0"), sha256.Size*2)),
		"database-backups/backup.dump",
	)
	if err == nil {
		t.Fatal("verify() error = nil, want checksum mismatch")
	}
}

func TestDownloadBackupDoesNotOverwrite(t *testing.T) {
	store := &memoryStore{
		bucket: "private-bucket",
		objects: map[string][]byte{
			"database-backups/backup.dump": []byte("backup"),
		},
	}
	path := filepath.Join(t.TempDir(), "download.dump")

	if err := download(
		context.Background(),
		store,
		"database-backups/backup.dump",
		path,
	); err != nil {
		t.Fatalf("download() error = %v", err)
	}
	if got, err := os.ReadFile(path); err != nil || string(got) != "backup" {
		t.Fatalf("downloaded backup = %q, error = %v", got, err)
	}

	if err := download(
		context.Background(),
		store,
		"database-backups/backup.dump",
		path,
	); err == nil {
		t.Fatal("second download() error = nil, want no-overwrite failure")
	}
}
