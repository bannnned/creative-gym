# Project Context

## Product

Creative Gym is a web-first app for creative challenges.

The core metaphor is a gym for creativity: users train creative shape by joining weekly creative workouts.

The MVP focuses only on photography. Future directions may include music and video, but they must not be implemented in the first version.

## Core Loop

1. A weekly photo workout becomes active.
2. A user opens the PWA and sees active challenges.
3. The user joins a challenge.
4. The backend assigns the user to a small gym room.
5. During the submission phase, the user uploads exactly one photo.
6. After the submission deadline, voting starts.
7. Users vote on other participants' photos, not their own.
8. After voting ends, room results are shown.

## Product Feeling

Creative Gym should feel like a calm creative training habit.

It should not feel like:

- an Instagram clone;
- a casino-like competition;
- a toxic popularity contest;
- a public likes feed;
- a social network with endless scrolling.

The app should encourage consistency, practice, and reflection.

## First Implementation Goal

The first implementation should be a clean full-stack monorepo scaffold with one
working vertical slice:

- React PWA can fetch active photo challenges.
- User can open a challenge.
- User can join a gym room.
- Room screen displays data returned by the backend.

Photo upload via S3 signed URLs is the next step after the first slice.

The existing Flutter app remains a prototype/reference. Native iOS and Android
apps can be added later against the same Go API if the product needs app store
distribution, native push notifications, or deeper device integration.
