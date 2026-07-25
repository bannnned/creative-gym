package challenges

import (
	"bytes"
	"context"
	"encoding/base64"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"

	"creative-gym/apps/api/internal/auth"
	"creative-gym/apps/api/internal/storage"
)

type fakeCoverStore struct {
	fakeStore
	getCover    func(ctx context.Context, challengeID string) (CoverMedia, error)
	upsertCover func(
		ctx context.Context,
		challengeID string,
		userID string,
		media CoverMedia,
	) (*CoverObjectRef, error)
	deleteCover func(
		ctx context.Context,
		challengeID string,
		userID string,
	) (CoverObjectRef, error)
}

func (s fakeCoverStore) GetCover(
	ctx context.Context,
	challengeID string,
) (CoverMedia, error) {
	return s.getCover(ctx, challengeID)
}

func (s fakeCoverStore) UpsertCover(
	ctx context.Context,
	challengeID string,
	userID string,
	media CoverMedia,
) (*CoverObjectRef, error) {
	return s.upsertCover(ctx, challengeID, userID, media)
}

func (s fakeCoverStore) DeleteCover(
	ctx context.Context,
	challengeID string,
	userID string,
) (CoverObjectRef, error) {
	return s.deleteCover(ctx, challengeID, userID)
}

type fakeCoverObjectStore struct {
	put func(
		ctx context.Context,
		key string,
		body io.Reader,
		contentType string,
		byteSize int64,
	) error
	get    func(ctx context.Context, bucket string, key string) (storage.Object, error)
	delete func(ctx context.Context, bucket string, key string) error
}

func (s fakeCoverObjectStore) Bucket() string {
	return "covers"
}

func (s fakeCoverObjectStore) Put(
	ctx context.Context,
	key string,
	body io.Reader,
	contentType string,
	byteSize int64,
) error {
	return s.put(ctx, key, body, contentType, byteSize)
}

func (s fakeCoverObjectStore) Get(
	ctx context.Context,
	bucket string,
	key string,
) (storage.Object, error) {
	return s.get(ctx, bucket, key)
}

func (s fakeCoverObjectStore) Delete(
	ctx context.Context,
	bucket string,
	key string,
) error {
	if s.delete == nil {
		return nil
	}
	return s.delete(ctx, bucket, key)
}

func TestUploadCover(t *testing.T) {
	pngBytes, err := base64.StdEncoding.DecodeString(
		"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
	)
	if err != nil {
		t.Fatalf("decode fixture: %v", err)
	}

	var uploaded bool
	store := fakeCoverStore{
		upsertCover: func(
			ctx context.Context,
			challengeID string,
			userID string,
			media CoverMedia,
		) (*CoverObjectRef, error) {
			if challengeID != "challenge-id" {
				t.Fatalf("challengeID = %q", challengeID)
			}
			if userID != "author-id" {
				t.Fatalf("userID = %q", userID)
			}
			if media.Bucket != "covers" {
				t.Fatalf("bucket = %q", media.Bucket)
			}
			if media.ContentType != "image/png" {
				t.Fatalf("content type = %q", media.ContentType)
			}
			uploaded = true
			return nil, nil
		},
	}
	objects := fakeCoverObjectStore{
		put: func(
			ctx context.Context,
			key string,
			body io.Reader,
			contentType string,
			byteSize int64,
		) error {
			if contentType != "image/png" {
				t.Fatalf("content type = %q", contentType)
			}
			if byteSize != int64(len(pngBytes)) {
				t.Fatalf("byte size = %d", byteSize)
			}
			if _, err := io.ReadAll(body); err != nil {
				t.Fatalf("read object body: %v", err)
			}
			return nil
		},
	}
	handler := NewHandler(store, testWriteJSON, testWriteAPIError).
		WithObjectStore(objects)

	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	file, err := writer.CreateFormFile("cover", "cover.png")
	if err != nil {
		t.Fatalf("create multipart file: %v", err)
	}
	if _, err := file.Write(pngBytes); err != nil {
		t.Fatalf("write multipart file: %v", err)
	}
	if err := writer.Close(); err != nil {
		t.Fatalf("close multipart writer: %v", err)
	}

	request := httptest.NewRequest(
		http.MethodPut,
		"/api/v1/challenges/challenge-id/cover",
		&body,
	)
	request.Header.Set("Content-Type", writer.FormDataContentType())
	request.SetPathValue("challengeId", "challenge-id")
	request = request.WithContext(
		auth.ContextWithUserID(request.Context(), "author-id"),
	)
	response := httptest.NewRecorder()

	handler.UploadCover(response, request)

	if response.Code != http.StatusCreated {
		t.Fatalf(
			"status = %d, want %d; body = %s",
			response.Code,
			http.StatusCreated,
			response.Body.String(),
		)
	}
	if !uploaded {
		t.Fatal("cover metadata was not saved")
	}
}

func TestGetCoverStreamsPrivateObject(t *testing.T) {
	store := fakeCoverStore{
		getCover: func(
			ctx context.Context,
			challengeID string,
		) (CoverMedia, error) {
			return CoverMedia{
				ChallengeID: challengeID,
				Bucket:      "covers",
				ObjectKey:   "challenge-covers/challenge-id/cover.webp",
				ContentType: "image/webp",
				ByteSize:    5,
			}, nil
		},
	}
	objects := fakeCoverObjectStore{
		get: func(
			ctx context.Context,
			bucket string,
			key string,
		) (storage.Object, error) {
			return storage.Object{
				Body:          io.NopCloser(bytes.NewReader([]byte("cover"))),
				ContentType:   "image/webp",
				ContentLength: 5,
			}, nil
		},
	}
	handler := NewHandler(store, testWriteJSON, testWriteAPIError).
		WithObjectStore(objects)

	request := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/challenges/challenge-id/cover",
		nil,
	)
	request.SetPathValue("challengeId", "challenge-id")
	response := httptest.NewRecorder()

	handler.GetCover(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	if response.Header().Get("Content-Type") != "image/webp" {
		t.Fatalf(
			"content type = %q",
			response.Header().Get("Content-Type"),
		)
	}
	if response.Body.String() != "cover" {
		t.Fatalf("body = %q", response.Body.String())
	}
}
