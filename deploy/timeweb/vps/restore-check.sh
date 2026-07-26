#!/usr/bin/env bash

set -Eeuo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: restore-check.sh <backup.dump>" >&2
  exit 2
fi

project_dir="${CREATIVE_GYM_PROJECT_DIR:-/opt/creative-gym}"
compose_file="${CREATIVE_GYM_COMPOSE_FILE:-docker-compose.vps.yml}"
database_user="${CREATIVE_GYM_DATABASE_USER:-creative_gym}"
backup_file="$(readlink -f "$1")"

if [ ! -s "$backup_file" ]; then
  echo "Backup is missing or empty: $backup_file" >&2
  exit 1
fi

case "$backup_file" in
  /var/backups/creative-gym/postgres/*.dump) ;;
  *)
    echo "Refusing to restore-check a file outside the backup directory: $backup_file" >&2
    exit 1
    ;;
esac

cd "$project_dir"

check_database="creative_gym_restore_$(date -u +%Y%m%d%H%M%S)_$$"

cleanup() {
  docker compose -f "$compose_file" exec -T postgres \
    dropdb \
    --username="$database_user" \
    --if-exists \
    --force \
    "$check_database" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker compose -f "$compose_file" exec -T postgres \
  createdb \
  --username="$database_user" \
  --template=template0 \
  "$check_database"

docker compose -f "$compose_file" exec -T postgres \
  pg_restore \
  --username="$database_user" \
  --dbname="$check_database" \
  --no-owner \
  --no-privileges \
  --exit-on-error < "$backup_file"

summary="$(
  docker compose -f "$compose_file" exec -T postgres \
    psql \
    --username="$database_user" \
    --dbname="$check_database" \
    --tuples-only \
    --no-align \
    --command="
      SELECT json_build_object(
        'migrations', (SELECT count(*) FROM schema_migrations),
        'users', (SELECT count(*) FROM users),
        'challenges', (SELECT count(*) FROM challenges)
      );
    "
)"

if [ -z "$summary" ]; then
  echo "Restore check returned an empty database summary." >&2
  exit 1
fi

echo "Restore check passed: $summary"
