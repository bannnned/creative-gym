# Collaboration Rules

## How To Work On This Repo

1. Read the docs before changing code.
2. Keep changes small and reviewable.
3. Prefer simple working vertical slices over broad unfinished scaffolding.
4. Do not implement future product areas before they are part of the active plan.
5. Keep terminology aligned with `docs/02-domain-glossary.md`.
6. Update docs when product meaning, architecture, or scope changes.

## Before Coding

For non-trivial work:

1. Inspect the repository.
2. Identify existing structure and conventions.
3. Propose a concise implementation plan.
4. Implement only the agreed or clearly requested scope.
5. Verify the result with the relevant commands.

## Documentation Rule

Documentation should answer:

- what this part of the project is;
- why it exists;
- what is intentionally not included;
- how it fits the first MVP slice.

Avoid vague roadmap promises.

## TODO Rule

Use TODO comments only when they identify a real next step.

Good:

```txt
TODO: Replace dev-user header with real auth middleware.
```

Bad:

```txt
TODO: Improve this later.
```

## Product Consistency Rule

When adding UI or API behavior, check whether it preserves these distinctions:

- Challenge is not a room.
- Submission is not media.
- Voting happens after submissions close.
- Users do not vote on their own submissions.
- MVP is photo-only, but the model should not block future media kinds.
