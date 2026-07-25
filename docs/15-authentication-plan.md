# Authentication Plan

Updated: 2026-07-25.

## Current decision

Creative Gym uses a real guest session as the first authentication step.

- On the first API-backed launch, the existing single `Continue` action creates
  a guest user and an opaque session.
- The raw session token is returned once, stored in platform secure storage,
  and sent as `Authorization: Bearer <token>`.
- PostgreSQL stores only the SHA-256 hash of the token.
- Guest sessions currently live for 90 days.
- On later launches, Flutter validates the stored session and skips the login
  screen when it is still valid.
- Mock mode keeps the local one-tap flow and does not use platform storage.

This is an intermediate product state, but the session implementation is
production-shaped and will be reused by phone authentication.

## API

```text
POST /api/v1/auth/guest
GET  /api/v1/auth/me
```

All protected API routes resolve the viewer from the bearer session.
`X-Dev-User-Id` remains available only when `APP_ENV` is not `production`.

## Phone upgrade path

The guest user must not be replaced when phone verification is added. A
successful phone verification will:

1. resolve the current bearer session;
2. normalize and verify the phone number;
3. attach a `phone` auth identity to the current guest user;
4. merge into an existing phone user if that number was already registered;
5. rotate the session token.

This preserves the guest user's submissions, points, rooms, and profile.

## Provider status

The production delivery method is pending a written answer from the provider
about access for a physical person without an individual entrepreneur or legal
entity.

Preferred order:

1. flash-call verification if it is available to a physical person;
2. authorization SMS without a monthly sender fee;
3. passkey as a later zero-cost repeat-login method.

No provider API key, OTP code, full phone number, or raw session token may be
written to application logs or committed to Git.

## Required safeguards for phone verification

- one request per phone per 60 seconds;
- at most three requests per phone per hour;
- IP/device and global daily limits;
- short verification lifetime;
- limited verification attempts;
- provider spending cap;
- masked phone numbers in operational logs;
- privacy policy, consent, and personal-data compliance before production.
