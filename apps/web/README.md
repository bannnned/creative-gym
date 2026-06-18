# Creative Gym Web

React PWA client for Creative Gym.

## Local Development

Install dependencies:

```powershell
npm install
```

Run the PWA:

```powershell
npm run dev
```

The Vite dev server runs on:

```text
http://127.0.0.1:5173
```

By default, the app uses same-origin API paths and the Vite dev proxy forwards
`/api`, `/healthz`, and `/readyz` to `http://localhost:8080`.

Optional local env:

```powershell
Copy-Item .env.example .env
```

Set `VITE_API_BASE_URL` only when calling a remote API directly. Leave it empty
for local proxy development.

## Checks

```powershell
npm run lint
npm test
npm run build
```
