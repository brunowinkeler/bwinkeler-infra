#!/usr/bin/env bash
# Restore an encrypted PostgreSQL backup from R2 (ARCHITECTURE.md §20.4–§20.5).
# Defaults to a SCRATCH database `<db>_restore` so the backup can be verified
# without touching production. Restoring over a real database requires --yes.
# Requires the age PRIVATE key (kept OFF the VPS).
#
# Usage:
#   AGE_IDENTITY=/path/key.txt backup/restore-database.sh <db> \
#       [--object <name.dump.age>] [--subdir daily|weekly|monthly] \
#       [--target <db>] [--yes]
set -Eeuo pipefail

BACKUP_ENV="${BACKUP_ENV:-/etc/bwinkeler/backup.env}"
[[ -f "$BACKUP_ENV" ]] || { echo "ERROR: $BACKUP_ENV not found." >&2; exit 1; }
set -a
# shellcheck source=/dev/null
. "$BACKUP_ENV"
set +a

: "${AGE_IDENTITY:?set AGE_IDENTITY to the age private key path (kept off the VPS)}"
: "${R2_BUCKET:?set R2_BUCKET in $BACKUP_ENV}"
INFRA_DIR="${INFRA_DIR:-/srv/bwinkeler/infra}"
POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"
PG_SUPERUSER="${PG_SUPERUSER:-bw_admin}"
R2_PREFIX="${R2_PREFIX:-postgres}"

db="${1:-}"; shift || true
[[ -n "$db" ]] || { echo "usage: restore-database.sh <db> [--object N] [--subdir S] [--target T] [--yes]" >&2; exit 1; }
object=""; subdir="daily"; target=""; confirm=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --object) object="$2"; shift 2 ;;
    --subdir) subdir="$2"; shift 2 ;;
    --target) target="$2"; shift 2 ;;
    --yes) confirm="--yes"; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
target="${target:-${db}_restore}"

command -v age >/dev/null || { echo "ERROR: 'age' is not installed." >&2; exit 1; }
command -v rclone >/dev/null || { echo "ERROR: 'rclone' is not installed." >&2; exit 1; }

if [[ -n "${R2_ACCESS_KEY_ID:-}" ]]; then
  export RCLONE_CONFIG_R2_TYPE=s3 RCLONE_CONFIG_R2_PROVIDER=Cloudflare
  export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
  export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
  export RCLONE_CONFIG_R2_ENDPOINT="${R2_ENDPOINT:-https://${R2_ACCOUNT_ID:?set R2_ACCOUNT_ID or R2_ENDPOINT}.r2.cloudflarestorage.com}"
  R2_REMOTE=R2
fi
: "${R2_REMOTE:?set R2_REMOTE (or provide R2_ACCESS_KEY_ID/…)}"

base="${R2_REMOTE}:${R2_BUCKET}/${R2_PREFIX}/${subdir}"
if [[ -z "$object" ]]; then
  object="$(rclone lsf "$base/" --include "${db}-*.dump.age" | sort -r | head -n1)"
  [[ -n "$object" ]] || { echo "ERROR: no backup found for '${db}' in ${base}/." >&2; exit 1; }
  echo "selected newest: ${object}"
fi

if [[ "$target" != *_restore && "$confirm" != "--yes" ]]; then
  echo "ERROR: target '${target}' is not a *_restore scratch DB. Re-run with --yes to overwrite it." >&2
  exit 1
fi

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

echo "== downloading =="
rclone copyto "$base/${object}" "$work/${object}"
rclone copyto "$base/${object}.sha256" "$work/${object}.sha256"

echo "== verifying checksum =="
expected="$(cat "$work/${object}.sha256")"
actual="$(sha256sum "$work/${object}" | awk '{print $1}')"
[[ "$expected" == "$actual" ]] || { echo "ERROR: checksum mismatch (expected $expected, got $actual)." >&2; exit 1; }
echo "ok: checksum matches"

echo "== decrypting =="
age -d -i "$AGE_IDENTITY" -o "$work/restore.dump" "$work/${object}"

echo "== (re)creating target database '${target}' =="
docker compose -f "$INFRA_DIR/compose.prod.yaml" exec -T "$POSTGRES_SERVICE" \
  psql -v ON_ERROR_STOP=1 -U "$PG_SUPERUSER" -d postgres <<SQL
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${target}' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS ${target};
CREATE DATABASE ${target};
SQL

echo "== restoring =="
docker compose -f "$INFRA_DIR/compose.prod.yaml" exec -T "$POSTGRES_SERVICE" \
  pg_restore -U "$PG_SUPERUSER" -d "$target" --no-owner --no-privileges < "$work/restore.dump"

echo "restore complete into '${target}' from '${object}'."
echo "Run the application's checks against '${target}', then drop it when done."
