#!/usr/bin/env bash

set -Eeuo pipefail

project_dir="${CREATIVE_GYM_PROJECT_DIR:-/opt/creative-gym}"
compose_file="${CREATIVE_GYM_COMPOSE_FILE:-docker-compose.vps.yml}"
remote="${CREATIVE_GYM_GIT_REMOTE:-origin}"
branch="${CREATIVE_GYM_GIT_BRANCH:-main}"
public_url="${CREATIVE_GYM_PUBLIC_URL:-https://creative.gde-kofe.ru}"
lock_file="${CREATIVE_GYM_DEPLOY_LOCK:-/run/lock/creative-gym-deploy.lock}"
state_dir="${CREATIVE_GYM_DEPLOY_STATE_DIR:-/var/lib/creative-gym-deploy}"

exec 9>"$lock_file"
if ! flock -n 9; then
  echo "Another Creative Gym deployment is already running."
  exit 0
fi

unset DOCKER_CONTEXT
export DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"

cd "$project_dir"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Tracked changes exist on the VPS. Refusing to overwrite them."
  git status --short
  exit 1
fi

git fetch --prune "$remote" "$branch"
target_sha="$(git rev-parse "$remote/$branch")"
current_sha="$(git rev-parse HEAD)"

git cat-file -e "${target_sha}^{commit}"
git checkout "$branch"
git merge --ff-only "$target_sha"

internal_version="$(
  docker compose -f "$compose_file" exec -T api \
    wget -qO- http://127.0.0.1:8080/versionz 2>/dev/null ||
    true
)"
deployed_sha="$(
  printf '%s' "$internal_version" |
    sed -n 's/.*"commit":"\([^"]*\)".*/\1/p'
)"

if [ "$deployed_sha" = "$target_sha" ]; then
  echo "Creative Gym API is already at $target_sha."
  install -d -m 755 "$state_dir"
  printf '%s\n' "$target_sha" > "$state_dir/last-successful-sha"
  exit 0
fi

if [ -n "$deployed_sha" ] &&
  git cat-file -e "${deployed_sha}^{commit}" 2>/dev/null &&
  git merge-base --is-ancestor "$deployed_sha" "$target_sha" &&
  git diff --quiet "$deployed_sha" "$target_sha" -- \
    apps/api \
    deploy/timeweb/vps \
    docker-compose.timeweb-vps.example.yml \
    .github/workflows/deploy-backend.yml; then
  echo "No backend changes between deployed $deployed_sha and $target_sha."
  exit 0
fi

echo "Deploying Creative Gym API:"
echo "  repository: $current_sha -> $target_sha"
echo "  API: ${deployed_sha:-unknown} -> $target_sha"
echo "  Docker daemon: $(docker info --format '{{.ID}}')"

docker compose -f "$compose_file" config --quiet
docker compose -f "$compose_file" build \
  --pull \
  --build-arg BUILD_SHA="$target_sha" \
  api
docker compose -f "$compose_file" run --rm api /app/db migrate
docker compose -f "$compose_file" up -d --no-deps --force-recreate api

ready=false
for attempt in $(seq 1 30); do
  if docker compose -f "$compose_file" exec -T api \
    wget -qO- http://127.0.0.1:8080/readyz |
    grep -q '"status":"ok"'; then
    ready=true
    break
  fi
  sleep 2
done

if [ "$ready" != true ]; then
  echo "API did not become ready after deployment."
  docker compose -f "$compose_file" ps
  docker compose -f "$compose_file" logs --tail 150 api
  exit 1
fi

healthy=false
for attempt in $(seq 1 30); do
  health_status="$(
    docker compose -f "$compose_file" ps -q api |
      xargs docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}missing{{end}}'
  )"
  if [ "$health_status" = "healthy" ]; then
    healthy=true
    break
  fi
  sleep 2
done

if [ "$healthy" != true ]; then
  echo "API Docker healthcheck did not become healthy: ${health_status:-missing}"
  docker compose -f "$compose_file" ps
  docker compose -f "$compose_file" logs --tail 150 api
  exit 1
fi

internal_version="$(
  docker compose -f "$compose_file" exec -T api \
    wget -qO- http://127.0.0.1:8080/versionz
)"
if ! printf '%s' "$internal_version" |
  grep -q "\"commit\":\"$target_sha\""; then
  echo "Expected API commit $target_sha, got: $internal_version"
  exit 1
fi

docker compose -f "$compose_file" up -d --no-deps --force-recreate caddy

public_ready=false
for attempt in $(seq 1 30); do
  public_version="$(
    curl --silent --show-error --max-time 10 \
      "$public_url/versionz" ||
      true
  )"
  if printf '%s' "$public_version" |
    grep -q "\"commit\":\"$target_sha\""; then
    public_ready=true
    break
  fi
  sleep 2
done

if [ "$public_ready" != true ]; then
  echo "Public API did not switch to $target_sha. Got: $public_version"
  docker compose -f "$compose_file" logs --tail 100 caddy
  exit 1
fi

install -d -m 755 "$state_dir"
printf '%s\n' "$target_sha" > "$state_dir/last-successful-sha"

docker compose -f "$compose_file" ps
echo "Creative Gym API deployment completed: $target_sha"
