package results

import "errors"

var (
	ErrRoomNotFound    = errors.New("room not found")
	ErrResultsPending  = errors.New("results are not available")
	ErrProfileNotFound = errors.New("profile not found")
	ErrAvatarNotFound  = errors.New("avatar not found")
)

type SubmissionResult struct {
	ID            string
	AuthorUserID  string
	Title         string
	AuthorLabel   string
	Wins          int
	Comparisons   int
	Rank          int
	IsCurrentUser bool
}

type RoomResult struct {
	RoomID            string
	ChallengeTitle    string
	ParticipantsCount int
	SubmissionsCount  int
	CurrentSubmission *SubmissionResult
	RankedSubmissions []SubmissionResult
}

type ProfileWork struct {
	ID       string
	Title    string
	Place    *int
	Finished bool
}

type Profile struct {
	UserID             string
	DisplayName        string
	AvatarURL          string
	IsCurrentUser      bool
	Points             int
	FirstPlaces        int
	SecondPlaces       int
	ThirdPlaces        int
	EmailVerified      bool
	PendingPrizePoints int
	Works              []ProfileWork
}

func pointsForWork(work ProfileWork) int {
	if !work.Finished {
		return 0
	}
	if work.Place == nil {
		return 10
	}
	switch *work.Place {
	case 1:
		return 100
	case 2:
		return 60
	case 3:
		return 30
	default:
		return 10
	}
}

func prizePointsForWork(work ProfileWork) int {
	if !work.Finished || work.Place == nil {
		return 0
	}
	switch *work.Place {
	case 1:
		return 100
	case 2:
		return 60
	case 3:
		return 30
	default:
		return 0
	}
}
