# Authentication

Updated: 2026-08-01.

## Product flow

Creative Gym starts instantly with a real guest account. The user can upload
work, vote, and keep using the app before adding a sign-in method.

The account screen can attach three recovery methods to that same user:

- email confirmation link;
- Yandex ID;
- passkey after email or Yandex has been verified.

Challenge places are always recorded. A user with an unverified email sees
their place and crown, but the 100/60/30 prize points are withheld. Those
points appear automatically as soon as the email is confirmed. Ordinary
participation points are not withheld.

If an email or Yandex identity already belongs to an existing account, a fresh
guest signs into that account. A guest that already has rooms, submissions, or
votes is never switched silently; the API returns `identity_in_use` so no work
appears to be lost.

## API

```text
POST /api/v1/auth/guest
GET  /api/v1/auth/me

POST /api/v1/auth/email/start
GET  /api/v1/auth/email/confirm

POST /api/v1/auth/yandex/start
GET  /api/v1/auth/yandex/callback
POST /api/v1/auth/exchange

POST /api/v1/auth/passkeys/register/options
POST /api/v1/auth/passkeys/register/verify
POST /api/v1/auth/passkeys/login/options
POST /api/v1/auth/passkeys/login/verify
```

Email and Yandex callbacks issue a short, single-use exchange code. The raw
session token is only returned to the app, stored in secure storage, and sent
as `Authorization: Bearer <token>`. PostgreSQL stores only its SHA-256 hash.

## VPS environment

The untracked `/opt/creative-gym/docker-compose.vps.yml` must pass the following
variables into the `api` service. The repository example compose already does
this.

```dotenv
PUBLIC_BASE_URL=https://creative.gde-kofe.ru
AUTH_APP_CALLBACK_URL=creativegym://auth/complete

YANDEX_CLIENT_ID=...
YANDEX_CLIENT_SECRET=...

SMTP_HOST=...
SMTP_PORT=587
SMTP_USERNAME=...
SMTP_PASSWORD=...
SMTP_FROM=...

PASSKEY_RP_ID=creative.gde-kofe.ru
PASSKEY_RP_NAME=Creative Gym
PASSKEY_ORIGINS=https://creative.gde-kofe.ru,android:apk-key-hash:BASE64URL_SHA256
ANDROID_PACKAGE_NAME=com.creativegym.mobile
ANDROID_SHA256_CERT_FINGERPRINTS=COLON_SEPARATED_SHA256
```

Use SMTP submission with STARTTLS on port 587. Store secrets only in the VPS
`.env`; never commit them.

## Yandex setup

Create a Yandex OAuth application and configure the exact web callback:

```text
https://creative.gde-kofe.ru/api/v1/auth/yandex/callback
```

Enable access to the user identity and default email, then place the client ID
and secret in the VPS `.env`.

## Passkey association

Android validates that the app and `creative.gde-kofe.ru` belong together.
The API serves `/.well-known/assetlinks.json` from the configured package name
and SHA-256 signing-certificate fingerprints.

Two encodings of the same certificate hash are needed:

- colon-separated uppercase hex in `ANDROID_SHA256_CERT_FINGERPRINTS`;
- unpadded base64url in the Android `android:apk-key-hash:` entry inside
  `PASSKEY_ORIGINS`.

Include both debug and release certificate origins/fingerprints while local
debug APKs are being tested. External builds should be signed with a stable
release key.

Current configured keys:

```text
release fingerprint: B1:86:98:77:72:33:A6:1F:42:F4:EB:0E:96:20:16:C6:71:6A:12:DA:2C:53:1D:A8:92:59:34:6B:E1:CD:78:27
release origin:      android:apk-key-hash:sYaYd3Izph9C9OsOliAWxnFqEtosUx2oklk0a-HNeCc
debug fingerprint:   7B:30:9F:C5:E9:3B:12:0F:3B:5B:1B:FB:66:F8:E3:A7:28:01:88:67:96:24:FE:7D:20:BB:65:F5:64:F3:EC:C6
debug origin:        android:apk-key-hash:ezCfxek7Eg87Wxv7ZvjjpygBiGeWJP59ILtl9WTz7MY
```

The HTTPS origin in `PASSKEY_ORIGINS` is what lets the future PWA use the same
RP ID and synced passkeys.

## Safeguards

- email links expire after 30 minutes;
- one email per address/account per minute and at most three per hour;
- OAuth states use PKCE and expire after 10 minutes;
- app exchange codes are single-use and expire after five minutes;
- passkey challenges are single-use and expire after five minutes;
- session, email, OAuth, SMTP, and provider secrets are never logged.
