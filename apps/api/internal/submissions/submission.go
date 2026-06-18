package submissions

import (
	"errors"
	"time"
)

const MaxImageBytes int64 = 10 * 1024 * 1024

var (
	ErrRoomNotFound       = errors.New("room not found")
	ErrSubmissionNotFound = errors.New("submission not found")
	ErrSubmissionClosed   = errors.New("submission phase is closed")
	ErrMediaNotFound      = errors.New("media not found")
)

type Submission struct {
	ID          string
	RoomID      string
	UserID      string
	ContentType string
	ByteSize    int64
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type MediaObject struct {
	SubmissionID string
	Bucket       string
	ObjectKey    string
	ContentType  string
	ByteSize     int64
}

type ObjectRef struct {
	Bucket    string
	ObjectKey string
}
