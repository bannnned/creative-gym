# Automatic VPS Deployment Setup

Creative Gym uses a systemd timer on the Timeweb VPS to deploy backend changes
from `main`. GitHub Actions runs the Go tests and then waits until the public
API reports the exact pushed commit.

```text
push backend change to main
  -> GitHub Actions runs go test ./...
  -> VPS timer fetches origin/main within one minute
  -> VPS builds the API in its production Docker daemon
  -> VPS applies pending migrations
  -> VPS recreates API and Caddy
  -> VPS verifies the exact commit through the public domain
  -> GitHub Actions verifies /readyz, auth, and /versionz
```

This design deliberately runs Docker operations from the VPS itself. It avoids
differences between an SSH execution environment and the public Docker
environment.

Flutter-only changes do not trigger the backend workflow. The VPS script also
skips an API rebuild when commits since the deployed API contain no
backend-related changes.

## One-Time VPS Setup

Run from the Timeweb VPS console:

```bash
cd /opt/creative-gym

git fetch origin main
git merge --ff-only origin/main

install -m 644 \
  deploy/timeweb/vps/creative-gym-deploy.service \
  /etc/systemd/system/creative-gym-deploy.service

install -m 644 \
  deploy/timeweb/vps/creative-gym-deploy.timer \
  /etc/systemd/system/creative-gym-deploy.timer

systemctl daemon-reload
systemctl enable --now creative-gym-deploy.timer
systemctl start creative-gym-deploy.service
```

The deployment script keeps production secrets in
`/opt/creative-gym/.env`. It does not print or copy them.

## Verification

Inspect the timer and its most recent deployment:

```bash
systemctl status creative-gym-deploy.timer --no-pager
systemctl status creative-gym-deploy.service --no-pager
journalctl -u creative-gym-deploy.service -n 150 --no-pager
```

Verify the public version:

```bash
curl -fsS https://creative.gde-kofe.ru/versionz
```

The `commit` value must match:

```bash
cd /opt/creative-gym
git rev-parse HEAD
```

## Deployment Safety

The script:

- uses a host lock so two deployments cannot run concurrently;
- refuses to overwrite tracked changes made directly on the VPS;
- uses only fast-forward Git updates;
- runs migrations before replacing the API container;
- requires `/readyz` and `/versionz` to pass inside the API container;
- recreates Caddy and checks the exact commit through the public domain;
- records the last successful commit in
  `/var/lib/creative-gym-deploy/last-successful-sha`.

Database migrations are forward-only and transactional. Do not attempt an
automatic application rollback after a migration without first checking schema
compatibility.

## Recovery

Trigger an immediate check without waiting for the timer:

```bash
systemctl start creative-gym-deploy.service
journalctl -u creative-gym-deploy.service -n 150 --no-pager
```

Inspect the runtime when needed:

```bash
cd /opt/creative-gym
docker compose -f docker-compose.vps.yml ps
docker compose -f docker-compose.vps.yml logs --since 15m --tail 200 api caddy
```

If the service reports tracked changes, inspect them with `git status` and
resolve them manually. Never use `git reset --hard` as routine deployment
recovery.
