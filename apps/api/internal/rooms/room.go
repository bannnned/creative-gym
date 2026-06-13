package rooms

import "time"

const (
	PhaseUpcoming   = "upcoming"
	PhaseSubmission = "submission"
	PhaseVoting     = "voting"
	PhaseResults    = "results"
)

type Room struct {
	ID                  string
	ChallengeID         string
	ChallengeTitle      string
	ChallengeTheme      string
	SubmissionStartsAt  time.Time
	SubmissionEndsAt    time.Time
	VotingStartsAt      time.Time
	VotingEndsAt        time.Time
	ParticipantCount    int
	Capacity            int
	ViewerHasSubmission bool
}

func (r Room) PhaseAt(now time.Time) string {
	switch {
	case now.Before(r.SubmissionStartsAt):
		return PhaseUpcoming
	case now.Before(r.SubmissionEndsAt):
		return PhaseSubmission
	case now.Before(r.VotingEndsAt):
		return PhaseVoting
	default:
		return PhaseResults
	}
}
