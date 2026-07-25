package voting

import "errors"

const MaxVotesPerUser = 10

var (
	ErrRoomNotFound   = errors.New("room not found")
	ErrVotingClosed   = errors.New("voting is closed")
	ErrVotingComplete = errors.New("voting is complete")
	ErrInvalidPair    = errors.New("invalid vote pair")
	ErrAlreadyVoted   = errors.New("pair was already voted")
)

type Submission struct {
	ID string
}

type Progress struct {
	Completed int
	Target    int
}

type Pair struct {
	Left     Submission
	Right    Submission
	Progress Progress
}
