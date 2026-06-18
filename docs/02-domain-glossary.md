# Domain Glossary

## Creative Gym

The product itself: a web-first app for training creativity through recurring challenges.

## Challenge

A public creative task with a topic, description, rules, dates, and status.

In user-facing text, prefer "Weekly Workout" when the weekly training metaphor is useful.

## Challenge Kind

The creative direction of a challenge.

Planned values:

- `photo`
- `music`
- `video`

Only `photo` is implemented in the MVP.

## Gym Room

A small participant group for a specific challenge.

A challenge can have many rooms.

This distinction is important:

- Challenge: "Reflections", a weekly public creative task.
- Room: one small group of 8-16 participants doing that challenge together.

## Participant

A user who joined a room.

## Submission

One creative work submitted by a participant for a room.

For MVP photo flows, each participant submits exactly one photo.

## Media

A generic uploaded asset attached to a submission.

Planned media kinds:

- `image`
- `audio`
- `video`

Only `image` is implemented in the MVP.

## Voting

The phase after submissions close.

Users vote on other participants' submissions, not their own.

The long-term direction is anonymous pairwise voting.

## Results

The room outcome after voting ends.

Results should support creative growth, not just ranking.

## Creative Streak

A user's consistency signal.

It should reward participation and training rhythm.

## Coach Notes

Future feedback concept.

Do not implement in the MVP unless explicitly planned later.

## Creative Form

Profile progress concept.

It represents creative training progress over time.
