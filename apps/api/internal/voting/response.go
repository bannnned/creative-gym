package voting

type pairResponseEnvelope struct {
	Pair     *pairResponse    `json:"pair"`
	Progress progressResponse `json:"progress"`
}

type pairResponse struct {
	Left  voteSubmissionResponse `json:"left"`
	Right voteSubmissionResponse `json:"right"`
}

type voteSubmissionResponse struct {
	ID       string `json:"id"`
	MediaURL string `json:"media_url"`
}

type progressResponse struct {
	Completed int `json:"completed"`
	Target    int `json:"target"`
}

type castVoteRequest struct {
	LeftSubmissionID   string `json:"left_submission_id"`
	RightSubmissionID  string `json:"right_submission_id"`
	ChosenSubmissionID string `json:"chosen_submission_id"`
}

func toPairResponse(pair *Pair) pairResponseEnvelope {
	if pair == nil {
		return pairResponseEnvelope{}
	}
	return pairResponseEnvelope{
		Pair: &pairResponse{
			Left: voteSubmissionResponse{
				ID:       pair.Left.ID,
				MediaURL: "/api/v1/submissions/" + pair.Left.ID + "/media",
			},
			Right: voteSubmissionResponse{
				ID:       pair.Right.ID,
				MediaURL: "/api/v1/submissions/" + pair.Right.ID + "/media",
			},
		},
		Progress: progressResponse{
			Completed: pair.Progress.Completed,
			Target:    pair.Progress.Target,
		},
	}
}
