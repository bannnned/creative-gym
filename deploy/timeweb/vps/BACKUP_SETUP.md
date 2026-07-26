# PostgreSQL Backup And Restore Setup

Creative Gym creates one logical PostgreSQL backup every day. Each run:

1. creates a custom-format `pg_dump`;
2. restores it into a temporary database in the production PostgreSQL
   container;
3. reads core table counts from the restored database;
4. uploads the dump to the private Timeweb S3 bucket;
5. downloads the S3 object and verifies its SHA-256 checksum;
6. keeps local dumps for 14 days.

The temporary restore database is always removed. The live
`creative_gym` database is never overwritten by the verification process.

Backups contain user and application data. Keep the bucket private and never
commit or print S3 credentials.

## Schedule

`creative-gym-backup.timer` runs daily at approximately 03:20-03:30 Moscow
time. `Persistent=true` runs a missed backup after the VPS comes back online.

Local directory:

```text
/var/backups/creative-gym/postgres
```

S3 prefix:

```text
database-backups/postgres/
```

S3 copies are not automatically deleted. Configure a 90-day lifecycle policy
for this prefix in Timeweb after the first successful backup.

## One-Time Installation

Run in the Timeweb VPS console after the backend commit containing `/app/backup`
has deployed:

```bash
cd /opt/creative-gym

git fetch origin main
git merge --ff-only origin/main

install -m 644 \
  deploy/timeweb/vps/creative-gym-backup.service \
  /etc/systemd/system/creative-gym-backup.service

install -m 644 \
  deploy/timeweb/vps/creative-gym-backup.timer \
  /etc/systemd/system/creative-gym-backup.timer

systemctl daemon-reload
systemctl enable --now creative-gym-backup.timer
systemctl start creative-gym-backup.service
```

The first manual start can take several minutes because it performs a real
restore and S3 round trip.

## Verification

```bash
systemctl status creative-gym-backup.timer --no-pager
systemctl status creative-gym-backup.service --no-pager
journalctl -u creative-gym-backup.service -n 200 --no-pager

find /var/backups/creative-gym/postgres \
  -maxdepth 1 \
  -type f \
  -printf '%TY-%Tm-%Td %TH:%TM %s %f\n' |
sort
```

A successful journal ends with:

```text
Restore check passed
backup command completed command=upload
backup command completed command=verify
Backup completed
```

## Manual Restore Check

Re-check the newest local dump without changing production data:

```bash
cd /opt/creative-gym

latest_backup="$(
  find /var/backups/creative-gym/postgres \
    -maxdepth 1 \
    -type f \
    -name 'creative-gym-*.dump' \
    -printf '%T@ %p\n' |
  sort -n |
  tail -1 |
  cut -d' ' -f2-
)"

deploy/timeweb/vps/restore-check.sh "$latest_backup"
```

## Recover A Dump From S3

Use an exact object key from the backup journal:

```bash
cd /opt/creative-gym
install -d -m 700 /var/backups/creative-gym/postgres

docker compose -f docker-compose.vps.yml run \
  --rm \
  --no-deps \
  -T \
  --user 0:0 \
  --volume /var/backups/creative-gym/postgres:/backups \
  api \
  /app/backup download \
  database-backups/postgres/PASTE_EXACT_BACKUP_NAME.dump \
  /backups/recovered.dump

deploy/timeweb/vps/restore-check.sh \
  /var/backups/creative-gym/postgres/recovered.dump
```

The download command refuses to overwrite an existing local file.

Do not restore directly over the live `creative_gym` database. In a real
incident, first restore into a new database, verify it, stop application
writes, and only then plan the controlled database switch.
