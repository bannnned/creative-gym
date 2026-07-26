#!/usr/bin/env bash

set -Eeuo pipefail

project_dir="${CREATIVE_GYM_PROJECT_DIR:-/opt/creative-gym}"
compose_file="${CREATIVE_GYM_COMPOSE_FILE:-docker-compose.vps.yml}"
database_name="${CREATIVE_GYM_DATABASE_NAME:-creative_gym}"
database_user="${CREATIVE_GYM_DATABASE_USER:-creative_gym}"
backup_dir_input="${CREATIVE_GYM_BACKUP_DIR:-/var/backups/creative-gym/postgres}"
retention_days="${CREATIVE_GYM_BACKUP_RETENTION_DAYS:-14}"
s3_prefix="${CREATIVE_GYM_BACKUP_S3_PREFIX:-database-backups/postgres}"
lock_file="${CREATIVE_GYM_BACKUP_LOCK:-/run/lock/creative-gym-backup.lock}"

if ! [[ "$retention_days" =~ ^[0-9]+$ ]] || [ "$retention_days" -lt 1 ]; then
  echo "Backup retention must be a positive number of days." >&2
  exit 1
fi

exec 9>"$lock_file"
if ! flock -n 9; then
  echo "Another Creative Gym backup is already running."
  exit 0
fi

install -d -m 700 "$backup_dir_input"
backup_dir="$(readlink -f "$backup_dir_input")"
case "$backup_dir" in
  /var/backups/creative-gym/postgres) ;;
  *)
    echo "Refusing to use an unexpected backup directory: $backup_dir" >&2
    exit 1
    ;;
esac

cd "$project_dir"
docker compose -f "$compose_file" config --quiet

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
filename="creative-gym-${timestamp}.dump"
temporary_file="$backup_dir/.${filename}.partial"
backup_file="$backup_dir/$filename"
checksum_file="$backup_file.sha256"
object_key="${s3_prefix%/}/$filename"

cleanup_partial() {
  rm -f -- "$temporary_file"
}
trap cleanup_partial EXIT

docker compose -f "$compose_file" exec -T postgres \
  pg_dump \
  --username="$database_user" \
  --dbname="$database_name" \
  --format=custom \
  --compress=6 \
  --no-owner \
  --no-privileges > "$temporary_file"

if [ ! -s "$temporary_file" ]; then
  echo "PostgreSQL produced an empty backup." >&2
  exit 1
fi

chmod 600 "$temporary_file"
mv "$temporary_file" "$backup_file"
checksum="$(sha256sum "$backup_file" | awk '{print $1}')"
printf '%s  %s\n' "$checksum" "$filename" > "$checksum_file"
chmod 600 "$checksum_file"

"$project_dir/deploy/timeweb/vps/restore-check.sh" "$backup_file"

docker compose -f "$compose_file" run \
  --rm \
  --no-deps \
  -T \
  --user 0:0 \
  --volume "$backup_dir:/backups:ro" \
  api \
  /app/backup upload "/backups/$filename" "$object_key"

docker compose -f "$compose_file" run \
  --rm \
  --no-deps \
  -T \
  --user 0:0 \
  api \
  /app/backup verify "$checksum" "$object_key"

find "$backup_dir" \
  -maxdepth 1 \
  -type f \
  \( -name 'creative-gym-*.dump' -o -name 'creative-gym-*.dump.sha256' \) \
  -mtime "+$retention_days" \
  -print \
  -delete

echo "Backup completed:"
echo "  local=$backup_file"
echo "  s3=$object_key"
echo "  sha256=$checksum"
