package rooms

import (
	"testing"
	"time"
)

func TestRoomPhaseAt(t *testing.T) {
	base := time.Date(2026, 6, 13, 8, 0, 0, 0, time.UTC)
	room := Room{
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
		{name: "submission", now: room.SubmissionStartsAt, want: PhaseSubmission},
		{name: "voting", now: room.VotingStartsAt, want: PhaseVoting},
		{name: "results", now: room.VotingEndsAt, want: PhaseResults},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := room.PhaseAt(tt.now); got != tt.want {
				t.Fatalf("PhaseAt() = %q, want %q", got, tt.want)
			}
		})
	}
}
