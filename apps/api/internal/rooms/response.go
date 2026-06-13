package rooms

import "time"

type roomResponseEnvelope struct {
	Room roomResponse `json:"room"`
}

type roomResponse struct {
	ID                  string    `json:"id"`
	ChallengeID         string    `json:"challenge_id"`
	ChallengeTitle      string    `json:"challenge_title"`
	ChallengeTheme      string    `json:"challenge_theme"`
	Phase               string    `json:"phase"`
	ParticipantCount    int       `json:"participant_count"`
	Capacity            int       `json:"capacity"`
	ViewerHasSubmission bool      `json:"viewer_has_submission"`
	SubmissionEndsAt    time.Time `json:"submission_ends_at"`
	VotingEndsAt        time.Time `json:"voting_ends_at"`
}

func toRoomResponse(room Room, now time.Time) roomResponse {
	return roomResponse{
		ID:                  room.ID,
		ChallengeID:         room.ChallengeID,
		ChallengeTitle:      room.ChallengeTitle,
		ChallengeTheme:      room.ChallengeTheme,
		Phase:               room.PhaseAt(now),
		ParticipantCount:    room.ParticipantCount,
		Capacity:            room.Capacity,
		ViewerHasSubmission: room.ViewerHasSubmission,
		SubmissionEndsAt:    room.SubmissionEndsAt,
		VotingEndsAt:        room.VotingEndsAt,
	}
}
