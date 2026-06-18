package submissions

import "time"

type submissionResponseEnvelope struct {
	Submission *submissionResponse `json:"submission"`
}

type submissionResponse struct {
	ID          string    `json:"id"`
	RoomID      string    `json:"room_id"`
	MediaURL    string    `json:"media_url"`
	ContentType string    `json:"content_type"`
	ByteSize    int64     `json:"byte_size"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

func toSubmissionResponse(submission Submission) submissionResponse {
	return submissionResponse{
		ID:          submission.ID,
		RoomID:      submission.RoomID,
		MediaURL:    "/api/v1/submissions/" + submission.ID + "/media",
		ContentType: submission.ContentType,
		ByteSize:    submission.ByteSize,
		CreatedAt:   submission.CreatedAt,
		UpdatedAt:   submission.UpdatedAt,
	}
}
