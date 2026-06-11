# Domain Model

## Core Entities

### users

- `id`
- `email`
- `created_at`

### profiles

- `user_id`
- `display_name`
- `avatar_url`
- `creative_streak`
- `created_at`
- `updated_at`

### challenges

- `id`
- `kind`
- `title`
- `description`
- `rules`
- `starts_at`
- `submission_ends_at`
- `voting_ends_at`
- `status`
- `created_at`

### challenge_rooms

- `id`
- `challenge_id`
- `max_participants`
- `status`
- `created_at`

### room_participants

- `room_id`
- `user_id`
- `joined_at`

### submissions

- `id`
- `room_id`
- `user_id`
- `status`
- `created_at`
- `updated_at`

### submission_media

- `id`
- `submission_id`
- `kind`
- `original_object_key`
- `preview_object_key`
- `thumbnail_object_key`
- `width`
- `height`
- `duration_ms`
- `status`
- `created_at`

### votes

- `id`
- `room_id`
- `voter_id`
- `winner_submission_id`
- `loser_submission_id`
- `created_at`

## Important Relationships

- One challenge can have many gym rooms.
- One room belongs to one challenge.
- One user can join many rooms over time.
- A user should join only one room per challenge.
- One participant submits exactly one submission per room in the MVP.
- A submission can have media attached.
- Media is generic so future audio and video flows can use the same base model.
- Votes happen inside a room.
- A voter must not vote on their own submission.

## Challenge Kinds

Planned values:

- `photo`
- `music`
- `video`

MVP value:

- `photo`

## Media Kinds

Planned values:

- `image`
- `audio`
- `video`

MVP value:

- `image`

## API Direction

Versioned routes:

```txt
GET  /health

GET  /api/v1/challenges/active
GET  /api/v1/challenges/{challengeId}
POST /api/v1/challenges/{challengeId}/join

GET  /api/v1/rooms/{roomId}

POST /api/v1/submissions/upload-url
POST /api/v1/submissions
GET  /api/v1/rooms/{roomId}/submissions

POST /api/v1/votes
GET  /api/v1/rooms/{roomId}/results
```

First vertical slice routes:

```txt
GET  /health
GET  /api/v1/challenges/active
POST /api/v1/challenges/{challengeId}/join
GET  /api/v1/rooms/{roomId}
```
