package challenges

import (
	"testing"
	"time"
)

func TestChallengePhaseAt(t *testing.T) {
	base := time.Date(2026, 6, 13, 8, 0, 0, 0, time.UTC)
	challenge := Challenge{
		SubmissionStartsAt: base.Add(24 * time.Hour),
		SubmissionEndsAt:   base.Add(6 * 24 * time.Hour),
		VotingStartsAt:     base.Add(6 * 24 * time.Hour),
		VotingEndsAt:       base.Add(8 * 24 * time.Hour),
	}

	tests := []struct {
		name string
		now  time.Time
		want string
	}{
		{name: "upcoming", now: base, want: PhaseUpcoming},
		{name: "submission start", now: challenge.SubmissionStartsAt, want: PhaseSubmission},
		{name: "submission", now: base.Add(2 * 24 * time.Hour), want: PhaseSubmission},
		{name: "voting start", now: challenge.VotingStartsAt, want: PhaseVoting},
		{name: "voting", now: base.Add(7 * 24 * time.Hour), want: PhaseVoting},
		{name: "results", now: challenge.VotingEndsAt, want: PhaseResults},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := challenge.PhaseAt(tt.now); got != tt.want {
				t.Fatalf("PhaseAt() = %q, want %q", got, tt.want)
			}
		})
	}
}
