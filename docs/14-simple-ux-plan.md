# Simple UX Plan

Date: 2026-07-25

Status: ACTIVE. This is the product UX direction for the Flutter application.

## Goal

Creative Gym should require almost no interface learning. At every moment the
user should understand:

1. what is happening now;
2. what they need to do next.

The app should prefer one useful element over several explanatory or
decorative elements.

## Primary Journey

```text
Sign in
  -> choose a challenge
  -> current challenge
  -> add one photo
  -> compare anonymous photos
  -> view the outcome
```

The challenge list is the first screen after sign in. Selecting a challenge
opens a focused screen whose content and primary action change with the
challenge phase. Room and submission implementation details must not become
mandatory navigation steps.

## Interface Rules

### One primary action

Each screen has at most one visually dominant action. A secondary action may
be shown as text. Destructive or infrequent actions belong in an overflow
menu.

### Minimal challenge choice

The first screen after sign in is a vertical list of challenge covers. A card
contains only:

- the author's cover image;
- challenge title;
- time remaining or the current terminal state.

The whole card is one tap target. Description, participant count, room size,
icons, and separate call-to-action buttons do not appear inside it.

Selecting a card opens one focused challenge. Back navigation returns to the
choice screen.

### Only actionable information

Show:

- assignment title;
- one-sentence task;
- current deadline or state;
- the user's photo when relevant;
- the next action.

Hide or move behind a secondary action:

- repeated phase labels;
- room capacity when it does not affect a decision;
- implementation terminology;
- long rules;
- decorative counters and badges.

### Russian product language

User-facing screens use short Russian terms:

```text
Weekly Workout -> Задание
Gym Room       -> Группа, only when the group matters
Submission     -> Фото
Voting         -> Сравнение
Results        -> Итог
```

Code and API identifiers remain English.

### Calm Liquid Glass visual language

- one warm neutral background;
- author photography is the content layer;
- one green accent for the primary action;
- Liquid Glass belongs to navigation, primary actions, sheets, and small
  control surfaces;
- challenge covers and user photos are never turned into glass cards;
- low and standard rendering quality must degrade to a calm translucent
  fallback rather than dropping controls;
- generous spacing;
- no nested glass panels;
- icons only when they clarify an action.

Flutter feature screens depend on app-owned glass adapters, not directly on a
third-party rendering package.

### Calm motion language

Motion should explain state changes and preserve spatial continuity. It must
not compete with the photographs.

Current implementation direction:

- shared-axis transitions connect primary application screens;
- challenge cards enter with a short, restrained stagger;
- selected and accepted photographs use a brief photographic reveal;
- comparison selection responds with a small check and scale motion;
- workout completion assembles in a short sequence;
- motion durations and delays become zero when the system requests reduced
  motion.

Use `flutter_animate` for focused widget effects and the official `animations`
package for navigation transitions. Prefer Flutter's built-in animated widgets
for simple state changes.

Avoid:

- looping decorative motion on primary screens;
- confetti and casino-like celebration;
- large parallax or gyroscope effects;
- animating every text or control;
- stacking blur, glass, and shader effects on the same surface;
- making task completion wait for an animation.

## Challenge Covers

- Covers are private S3 objects served through the backend.
- Only the challenge author can upload or replace a cover.
- The list crops covers to `16:10` using `BoxFit.cover`.
- The author sees the same crop preview before saving.
- JPEG, PNG, and WebP are accepted up to 5 MiB.
- A deterministic muted gradient is used when a challenge has no cover.
- Title and remaining time stay readable over every cover through a dark
  bottom scrim.

### Human errors

Never show exception types, stack traces, HTTP internals, or timeout durations
to users. A failure state contains:

```text
Не удалось загрузить данные
Проверьте интернет и попробуйте ещё раз.
[ Повторить ]
```

Technical details stay in application logs.

## Screen States

### Sign in

Show the product name, a short promise, one animated visual hook, and one
primary action. The hook is a slowly shifting deck of creative frames; it
respects the system Reduce Motion setting. Alternative providers are
secondary. Demo access exists only in development builds.

### Profile

The profile is opened through one quiet icon in the challenge-list header.
It contains:

- a large avatar;
- one unified statistics block with points on the left and first, second, and
  third place crown counts on the right;
- `Работы` and a compact `Победители` switch;
- a three-column square gallery;
- a small place-coloured crown in the bottom-right corner of prize works;
- a full-screen, swipeable viewer with only a back action.

In API mode this screen uses the real profile endpoint and authenticated S3
media. Mock mode keeps `mockProfileData` for deterministic demos and widget
tests.

#### Avatar

- The current user can tap the avatar or camera badge to add or replace it.
- The editor opens immediately after choosing a photo.
- The preview is circular; the user can move and zoom the photo and rotate it
  in either direction.
- The saved file is a square `1024 x 1024` JPEG, while the interface displays
  it through a circular mask.
- Avatar files are limited to 3 MiB and stored as private S3 objects.
- Replacing an avatar creates a versioned object URL, updates the profile, and
  removes the previous private object.
- Other users can see the avatar but cannot edit it.

### Submission

Before selection: one photo placeholder and `Выбрать фото`.

After selection: photo preview and `Загрузить фото`.

After upload: the uploaded photo, `Фото принято`, a quiet `Заменить` action,
and `Удалить` inside an overflow menu.

### Comparison

Show `Какой кадр сильнее?`, two anonymous photos, and quiet progress. Tapping a
photo immediately records the choice and advances. `Пропустить` is secondary.

### Outcome

Lead with completion and the user's own photo. Keep room-wide results
collapsed until the user explicitly asks to see them. Avoid popularity-first
language.

## Definition Of Done

- sign in opens the challenge choice screen;
- each challenge card contains only cover, title, and remaining time;
- selecting a card opens one focused challenge;
- every primary screen has one dominant action;
- all primary navigation and copy are Russian;
- raw technical errors are absent from UI;
- photo upload, comparison demo, and outcome demo remain functional;
- cover upload is restricted to the challenge author and persists in S3;
- glass is limited to navigation and actions with a non-glass fallback;
- `flutter analyze` and `flutter test` pass.
