# Retention Implementation Plan

Date: 2026-07-26

Status: PLANNED. This is the next product implementation direction after the
core submission, comparison, and outcome loop is reliable.

## Goal

Give the user a clear and calm reason to return at every meaningful transition
of a Weekly Workout:

```text
submit a photo
  -> know what happens next
  -> return when comparison opens
  -> complete comparison
  -> return for the outcome
  -> discover the next workout
```

Creative Gym should optimize for completion of weekly creative cycles, not for
daily app opens.

## Implementation Order

1. Improve the accepted-photo state with room progress and the next event.
2. Add local notifications for the joined workout lifecycle.
3. Add the first short visual warm-up.
4. Measure return from one workout into the next.
5. Introduce monthly seasons after the weekly loop is reliable.

## 1. Accepted Photo State

Immediately after a successful upload, and whenever the user returns during
the submission phase, show:

```text
Фото принято
7 из 11 участников уже завершили тренировку
Сравнение откроется в воскресенье
```

The values must be real:

- `7` is the number of room participants with an accepted photo;
- `11` is the current number of participants in the room;
- `в воскресенье` is derived from the comparison start date and displayed in
  the user's local timezone.

If the exact weekday would be ambiguous or too far away, show a short date and
time instead.

Product rules:

- do not show other participants' photos before comparison opens;
- do not show names of people who have or have not submitted;
- do not turn submission progress into a competition;
- keep `Заменить` as a quiet secondary action while replacement is allowed;
- make the next lifecycle event more prominent than technical room details.

Required backend/client data:

- accepted submission count for the room;
- current participant count;
- comparison start timestamp;
- results start timestamp when available.

## 2. Workout Notifications

The first implementation should use calm, event-based local notifications for
a workout the user has joined. It does not need a remote push service.

Schedule:

### Submission Reminder

Send once, 24 hours before the submission deadline, only if the user has not
uploaded a photo:

```text
Задание скоро закроется
До конца тренировки остался день.
```

Cancel this notification immediately after a successful upload.

### Comparison Opened

Send when the comparison phase begins:

```text
Работы открылись для сравнения
Посмотри, как другие участники раскрыли тему.
```

Open the joined room's comparison screen.

### Outcome Ready

Send when the outcome becomes available:

```text
Итог тренировки готов
Посмотри свою работу и заверши неделю.
```

Open the joined room's outcome screen.

Notification rules:

- request notification permission only after the user joins a workout, with a
  short explanation of the concrete events they can be reminded about;
- use the device timezone;
- reschedule notifications when workout dates change;
- cancel obsolete notifications after leaving or completing the relevant
  state;
- use stable notification identifiers per workout and event;
- deep-link directly to the relevant screen;
- do not send daily reminders or streak-pressure messages;
- keep the application fully usable when permission is denied.

Known limitation:

Local notifications are sufficient for the first retention experiment, but
they cannot reliably announce a newly published workout that the app has never
fetched. Remote push notifications can be considered later for new workout
announcements and cross-device reliability.

## 3. Short Visual Warm-Up

The first selected format is:

> Какой кадр лучше раскрывает тему?

Flow:

1. Show the current workout theme.
2. Show one pair of curated photographs.
3. Let the user choose one photograph with a single tap.
4. Advance immediately.
5. Repeat for 3-5 pairs.
6. Once during the set, optionally ask:

   > Что сделало этот кадр сильнее?

7. Finish with a short observation or Coach Note, not a score.

The warm-up should:

- take no more than 1-2 minutes;
- have no correct or incorrect answer;
- introduce anonymous comparison;
- focus attention on interpretation of the current theme;
- use owned, licensed, or explicitly consented photographs;
- be skippable;
- avoid global percentages and popularity signals in the first version.

The first content version may be curated and bundled manually. Dynamic author
warm-ups and personalized observations are later extensions.

Open implementation decision:

- place the first warm-up before joining a workout, immediately after joining,
  or as an optional action while waiting for comparison.

The first usability prototype should compare these placements before the
product makes the warm-up mandatory.

## 4. Measurement

Primary retention metric:

> Percentage of users who complete one workout and join the next available
> workout.

Supporting funnel:

```text
joined
  -> submitted
  -> opened comparison
  -> completed comparison
  -> opened outcome
  -> joined next workout
```

Also measure:

- notification permission acceptance;
- return after the comparison notification;
- return after the outcome notification;
- warm-up start, completion, and skip rates;
- time from joining to submitting;
- completion of at least two workouts in a four-workout season.

## 5. Monthly Seasons

A season is a monthly creative program containing four related Weekly
Workouts. The first purpose of seasons is to create continuity and a visible
creative journey, not a competitive league.

Example:

```text
Сезон «Свет»
1. Тень
2. Контраст
3. Мягкий свет
4. Искусственный свет
```

Initial season experience:

- one season title and visual identity;
- four ordered weekly workouts;
- calm progress such as `2 из 4 тренировок завершено`;
- a short preview of the next workout after the current outcome;
- a season completion state;
- a collection of the user's season photographs.

Future season extensions:

- an invited photographer as the season author;
- author introductions and Coach Notes;
- an end-of-season personal collection;
- a summary of what attracted the user's attention during comparison;
- Creative Streak based on sustained workout or season participation;
- private clubs completing the same season together.

Season rules still to decide:

- whether completing 3 of 4 workouts counts as season completion;
- whether missed workouts can be completed later;
- whether all users share one global season or can join asynchronously;
- when Creative Streak starts and what preserves it;
- whether author-led seasons are free, paid, or mixed.

Do not implement points, public season leaderboards, or daily attendance
pressure as part of the first season version.

## Definition Of Done For The First Retention Slice

- the accepted-photo state shows real room completion progress;
- the accepted-photo state clearly names when comparison opens;
- joined workout events schedule local notifications;
- upload cancels the unnecessary submission reminder;
- notification taps deep-link to comparison and outcome;
- the warm-up can present 3-5 curated comparisons for the current theme;
- warm-up completion and the weekly return funnel are measurable;
- denied notification permission does not block the workout;
- copy remains short, calm, and Russian.
