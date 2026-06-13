package challenges

import "time"

const (
	PhaseUpcoming   = "upcoming"
	PhaseSubmission = "submission"
	PhaseVoting     = "voting"
	PhaseResults    = "results"
)

type Challenge struct {
	ID                 string
	Kind               string
	Title              string
	Theme              string
	Description        string
	Rules              []string
	Status             string
	SubmissionStartsAt time.Time
	SubmissionEndsAt   time.Time
	VotingStartsAt     time.Time
	VotingEndsAt       time.Time
	ParticipantCount   int
	RoomCapacity       int
	ViewerRoomID       *string
	ViewerHasJoined    bool
}

func (c Challenge) PhaseAt(now time.Time) string {
	switch {
	case now.Before(c.SubmissionStartsAt):
		return PhaseUpcoming
	case now.Before(c.SubmissionEndsAt):
		return PhaseSubmission
	case now.Before(c.VotingEndsAt):
		return PhaseVoting
	default:
		return PhaseResults
	}
}
