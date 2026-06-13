package challenges

import "time"

type challengesResponse struct {
	Challenges []challengeResponse `json:"challenges"`
}

type challengeResponseEnvelope struct {
	Challenge challengeResponse `json:"challenge"`
}

type challengeResponse struct {
	ID                 string    `json:"id"`
	Kind               string    `json:"kind"`
	Title              string    `json:"title"`
	Theme              string    `json:"theme"`
	Description        string    `json:"description"`
	Rules              []string  `json:"rules"`
	Status             string    `json:"status"`
	Phase              string    `json:"phase"`
	SubmissionStartsAt time.Time `json:"submission_starts_at"`
	SubmissionEndsAt   time.Time `json:"submission_ends_at"`
	VotingStartsAt     time.Time `json:"voting_starts_at"`
	VotingEndsAt       time.Time `json:"voting_ends_at"`
	ParticipantCount   int       `json:"participant_count"`
	RoomCapacity       int       `json:"room_capacity"`
	ViewerRoomID       *string   `json:"viewer_room_id"`
	ViewerHasJoined    bool      `json:"viewer_has_joined"`
}

func toChallengeResponses(challenges []Challenge, now time.Time) []challengeResponse {
	responses := make([]challengeResponse, 0, len(challenges))
	for _, challenge := range challenges {
		responses = append(responses, toChallengeResponse(challenge, now))
	}

	return responses
}

func toChallengeResponse(challenge Challenge, now time.Time) challengeResponse {
	return challengeResponse{
		ID:                 challenge.ID,
		Kind:               challenge.Kind,
		Title:              challenge.Title,
		Theme:              challenge.Theme,
		Description:        challenge.Description,
		Rules:              challenge.Rules,
		Status:             challenge.Status,
		Phase:              challenge.PhaseAt(now),
		SubmissionStartsAt: challenge.SubmissionStartsAt,
		SubmissionEndsAt:   challenge.SubmissionEndsAt,
		VotingStartsAt:     challenge.VotingStartsAt,
		VotingEndsAt:       challenge.VotingEndsAt,
		ParticipantCount:   challenge.ParticipantCount,
		RoomCapacity:       challenge.RoomCapacity,
		ViewerRoomID:       challenge.ViewerRoomID,
		ViewerHasJoined:    challenge.ViewerHasJoined,
	}
}
