package results

type roomResultEnvelope struct {
	Result roomResultResponse `json:"result"`
}

type roomResultResponse struct {
	RoomID            string                     `json:"room_id"`
	ChallengeTitle    string                     `json:"challenge_title"`
	ParticipantsCount int                        `json:"participants_count"`
	SubmissionsCount  int                        `json:"submissions_count"`
	CurrentSubmission *resultSubmissionResponse  `json:"current_user_submission"`
	RankedSubmissions []resultSubmissionResponse `json:"ranked_submissions"`
}

type resultSubmissionResponse struct {
	ID            string `json:"id"`
	AuthorUserID  string `json:"author_user_id"`
	Rank          int    `json:"rank"`
	Title         string `json:"title"`
	AuthorLabel   string `json:"author_label"`
	Wins          int    `json:"wins"`
	Comparisons   int    `json:"comparisons"`
	MediaURL      string `json:"media_url"`
	IsCurrentUser bool   `json:"is_current_user"`
}

type profileEnvelope struct {
	Profile profileResponse `json:"profile"`
}

type profileResponse struct {
	UserID        string                `json:"id"`
	DisplayName   string                `json:"display_name"`
	IsCurrentUser bool                  `json:"is_current_user"`
	Points        int                   `json:"points"`
	FirstPlaces   int                   `json:"first_places"`
	SecondPlaces  int                   `json:"second_places"`
	ThirdPlaces   int                   `json:"third_places"`
	Works         []profileWorkResponse `json:"works"`
}

type profileWorkResponse struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	MediaURL string `json:"media_url"`
	Place    *int   `json:"place"`
}

func toRoomResultResponse(result RoomResult) roomResultEnvelope {
	response := roomResultResponse{
		RoomID:            result.RoomID,
		ChallengeTitle:    result.ChallengeTitle,
		ParticipantsCount: result.ParticipantsCount,
		SubmissionsCount:  result.SubmissionsCount,
		RankedSubmissions: make([]resultSubmissionResponse, 0, len(result.RankedSubmissions)),
	}
	for _, submission := range result.RankedSubmissions {
		item := toSubmissionResponse(submission)
		response.RankedSubmissions = append(response.RankedSubmissions, item)
		if submission.IsCurrentUser {
			current := item
			response.CurrentSubmission = &current
		}
	}
	return roomResultEnvelope{Result: response}
}

func toSubmissionResponse(submission SubmissionResult) resultSubmissionResponse {
	return resultSubmissionResponse{
		ID:            submission.ID,
		AuthorUserID:  submission.AuthorUserID,
		Rank:          submission.Rank,
		Title:         submission.Title,
		AuthorLabel:   submission.AuthorLabel,
		Wins:          submission.Wins,
		Comparisons:   submission.Comparisons,
		MediaURL:      "/api/v1/submissions/" + submission.ID + "/media",
		IsCurrentUser: submission.IsCurrentUser,
	}
}

func toProfileResponse(profile Profile) profileEnvelope {
	response := profileResponse{
		UserID:        profile.UserID,
		DisplayName:   profile.DisplayName,
		IsCurrentUser: profile.IsCurrentUser,
		Points:        profile.Points,
		FirstPlaces:   profile.FirstPlaces,
		SecondPlaces:  profile.SecondPlaces,
		ThirdPlaces:   profile.ThirdPlaces,
		Works:         make([]profileWorkResponse, 0, len(profile.Works)),
	}
	for _, work := range profile.Works {
		response.Works = append(response.Works, profileWorkResponse{
			ID:       work.ID,
			Title:    work.Title,
			MediaURL: "/api/v1/submissions/" + work.ID + "/media",
			Place:    work.Place,
		})
	}
	return profileEnvelope{Profile: response}
}
