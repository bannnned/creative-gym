package results

import (
	"bytes"
	"context"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"creative-gym/apps/api/internal/auth"
	"creative-gym/apps/api/internal/storage"
)

type avatarFakeStore struct {
	fakeStore
	upsertedUserID string
	upsertedMedia  AvatarMedia
	replaced       *AvatarObjectRef
}

func (s *avatarFakeStore) GetAvatar(context.Context, string) (AvatarMedia, error) {
	return AvatarMedia{}, ErrAvatarNotFound
}

func (s *avatarFakeStore) UpsertAvatar(
	_ context.Context,
	userID string,
	media AvatarMedia,
) (*AvatarObjectRef, error) {
	s.upsertedUserID = userID
	s.upsertedMedia = media
	return s.replaced, nil
}

type avatarFakeObjectStore struct {
	putKey         string
	putContentType string
	putBytes       []byte
	deletedKeys    []string
}

func (s *avatarFakeObjectStore) Bucket() string {
	return "test-bucket"
}

func (s *avatarFakeObjectStore) Put(
	_ context.Context,
	key string,
	body io.Reader,
	contentType string,
	_ int64,
) error {
	s.putKey = key
	s.putContentType = contentType
	s.putBytes, _ = io.ReadAll(body)
	return nil
}

func (s *avatarFakeObjectStore) Get(
	context.Context,
	string,
	string,
) (storage.Object, error) {
	return storage.Object{}, nil
}

func (s *avatarFakeObjectStore) Delete(
	_ context.Context,
	_ string,
	key string,
) error {
	s.deletedKeys = append(s.deletedKeys, key)
	return nil
}

func TestUploadAvatarStoresNewImageAndRemovesReplacedObject(t *testing.T) {
	const oldKey = "profile-avatars/user-id/old.jpg"
	imageBytes := []byte{0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46}
	store := &avatarFakeStore{
		replaced: &AvatarObjectRef{ObjectKey: oldKey},
	}
	objects := &avatarFakeObjectStore{}
	handler := NewHandler(store, testWriteJSON, testWriteAPIError)
	handler.WithObjectStore(objects)

	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	file, err := writer.CreateFormFile("avatar", "avatar.jpg")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := file.Write(imageBytes); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}

	request := httptest.NewRequest(http.MethodPut, "/api/v1/profile/me/avatar", &body)
	request.Header.Set("Content-Type", writer.FormDataContentType())
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.UploadAvatar(response, request)

	if response.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d; body = %s", response.Code, http.StatusCreated, response.Body.String())
	}
	if store.upsertedUserID != "user-id" {
		t.Fatalf("upserted user = %q, want user-id", store.upsertedUserID)
	}
	if !strings.HasPrefix(objects.putKey, "profile-avatars/user-id/") ||
		!strings.HasSuffix(objects.putKey, ".jpg") {
		t.Fatalf("put key = %q, want a versioned user avatar key", objects.putKey)
	}
	if objects.putContentType != "image/jpeg" || !bytes.Equal(objects.putBytes, imageBytes) {
		t.Fatalf("stored object content does not match uploaded JPEG")
	}
	if store.upsertedMedia.ObjectKey != objects.putKey {
		t.Fatalf("database object key = %q, want %q", store.upsertedMedia.ObjectKey, objects.putKey)
	}
	if len(objects.deletedKeys) != 1 || objects.deletedKeys[0] != oldKey {
		t.Fatalf("deleted keys = %v, want [%s]", objects.deletedKeys, oldKey)
	}
	if !strings.Contains(
		response.Body.String(),
		`"avatar_url":"/api/v1/profiles/user-id/avatar?v=`,
	) {
		t.Fatalf("body = %q, want versioned avatar URL", response.Body.String())
	}
}
