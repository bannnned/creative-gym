# GitHub Actions Deployment Setup

The workflow `.github/workflows/deploy-backend.yml` automatically deploys the
Go API after relevant code reaches `main`.

Deployment sequence:

```text
push to main
  -> go test ./...
  -> SSH to the Timeweb VPS
  -> fast-forward /opt/creative-gym to the pushed commit
  -> build the api image
  -> apply pending database migrations
  -> replace the api container
  -> verify /readyz inside the container
```

Flutter changes do not trigger this workflow. Flutter builds are installed on
devices or published to mobile stores separately.

## One-Time SSH Setup

Generate a dedicated key on the development Windows machine. Do not add this
key to the repository:

```powershell
ssh-keygen -t ed25519 `
  -C "github-actions-creative-gym" `
  -f "$env:USERPROFILE\.ssh\creative_gym_github_actions"
```

Print the public key:

```powershell
Get-Content "$env:USERPROFILE\.ssh\creative_gym_github_actions.pub"
```

In the Timeweb VPS console, add that one public-key line to root's authorized
keys:

```bash
install -d -m 700 /root/.ssh
printf '%s\n' 'PASTE_PUBLIC_KEY_HERE' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

Print the VPS SSH host key in GitHub `known_hosts` format:

```bash
awk '{print "147.45.99.61 " $1 " " $2}' \
  /etc/ssh/ssh_host_ed25519_key.pub
```

The public key and host key are not secrets. The private key is a secret.

## GitHub Production Environment

In the GitHub repository, open:

```text
Settings -> Environments -> New environment -> production
```

Add these environment secrets:

| Secret | Value |
|---|---|
| `VPS_HOST` | `147.45.99.61` |
| `VPS_PORT` | `22` |
| `VPS_USER` | `root` |
| `VPS_SSH_PRIVATE_KEY` | Entire contents of `creative_gym_github_actions` |
| `VPS_SSH_KNOWN_HOSTS` | Entire output of the VPS `awk` command above |

Read the private key in PowerShell without copying the `.pub` file:

```powershell
Get-Content "$env:USERPROFILE\.ssh\creative_gym_github_actions" -Raw
```

S3 credentials, the PostgreSQL password, and other application settings stay
only in `/opt/creative-gym/.env`. Do not add them to GitHub.

## First Deployment

Before enabling the first run, confirm that the VPS checkout has no tracked
edits. Untracked `.env` and `docker-compose.vps.yml` files are expected and are
not affected:

```bash
cd /opt/creative-gym
git status --short
git remote -v
git branch --show-current
```

The workflow intentionally stops when tracked VPS files have local changes. It
never performs `git reset --hard`.

After adding the secrets, either push a relevant backend change to `main` or
open:

```text
GitHub -> Actions -> Deploy backend -> Run workflow
```

The manual run is useful for the first deployment and for retrying a failed
deployment without making an empty commit.

## Recovery

If deployment fails, read the failed GitHub Actions step first. The existing
PostgreSQL container and volume are not recreated by this workflow.

The SSH client retries initial connections and uses keepalive probes because
the VPS route has previously shown intermittent connection and banner
timeouts.

Inspect the server when needed:

```bash
cd /opt/creative-gym
docker compose -f docker-compose.vps.yml ps
docker compose -f docker-compose.vps.yml logs --since 15m --tail 200 api
git log -3 --oneline
```

Database migrations are forward-only and transactional. Do not attempt an
automatic application rollback after a migration without checking schema
compatibility.
