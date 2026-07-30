#!/usr/bin/env bash
# Encrypted logical backup of the shared PostgreSQL databases to Cloudflare R2
# (ARCHITECTURE.md §20). For each database: pg_dump (custom format) -> age
# encryption -> upload to R2 with a SHA-256 sidecar, then prune by retention.
# No secret is printed. Run daily as root (cron / systemd timer).
set -Eeuo pipefail

BACKUP_ENV="${BACKUP_ENV:-/etc/bwinkeler/backup.env}"
[[ -f "$BACKUP_ENV" ]] || { echo "ERROR: $BACKUP_ENV not found (see templates/backup.env.example)." >&2; exit 1; }
set -a
# shellcheck source=/dev/null
. "$BACKUP_ENV"
set +a

: "${BACKUP_DATABASES:?set BACKUP_DATABASES in $BACKUP_ENV}"
: "${AGE_RECIPIENTS:?set AGE_RECIPIENTS in $BACKUP_ENV}"
: "${R2_BUCKET:?set R2_BUCKET in $BACKUP_ENV}"
INFRA_DIR="${INFRA_DIR:-/srv/bwinkeler/infra}"
POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"
PG_SUPERUSER="${PG_SUPERUSER:-bw_admin}"
R2_PREFIX="${R2_PREFIX:-postgres}"
RETAIN_DAILY="${RETAIN_DAILY:-7}"
RETAIN_WEEKLY="${RETAIN_WEEKLY:-4}"
RETAIN_MONTHLY="${RETAIN_MONTHLY:-6}"

command -v age >/dev/null || { echo "ERROR: 'age' is not installed." >&2; exit 1; }
command -v rclone >/dev/null || { echo "ERROR: 'rclone' is not installed." >&2; exit 1; }

# Build an ad-hoc rclone remote from env creds (kept out of argv and config files).
if [[ -n "${R2_ACCESS_KEY_ID:-}" ]]; then
  export RCLONE_CONFIG_R2_TYPE=s3
  export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
  export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
  export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
  export RCLONE_CONFIG_R2_ENDPOINT="${R2_ENDPOINT:-https://${R2_ACCOUNT_ID:?set R2_ACCOUNT_ID or R2_ENDPOINT}.r2.cloudflarestorage.com}"
  export RCLONE_CONFIG_R2_ACL=private
  R2_REMOTE=R2
fi
: "${R2_REMOTE:?set R2_REMOTE (or provide R2_ACCESS_KEY_ID/… in $BACKUP_ENV)}"

age_args=()
for r in $AGE_RECIPIENTS; do age_args+=(-r "$r"); done

ts="$(date -u +%Y%m%dT%H%M%SZ)"
dow="$(date -u +%u)"    # 1 = Monday
dom="$(date -u +%d)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

upload() {  # <local-file> <subdir>
  rclone copyto "$1" "${R2_REMOTE}:${R2_BUCKET}/${R2_PREFIX}/${2}/$(basename "$1")" --s3-no-check-bucket
}

prune() {   # <subdir> <keep>
  local sub="$1" keep="$2" names=() i=0
  mapfile -t names < <(rclone lsf "${R2_REMOTE}:${R2_BUCKET}/${R2_PREFIX}/${sub}/" --include '*.dump.age' 2>/dev/null | sort -r)
  for n in "${names[@]}"; do
    i=$((i + 1))
    if (( i > keep )); then
      rclone deletefile "${R2_REMOTE}:${R2_BUCKET}/${R2_PREFIX}/${sub}/${n}" || true
      rclone deletefile "${R2_REMOTE}:${R2_BUCKET}/${R2_PREFIX}/${sub}/${n}.sha256" || true
    fi
  done
}

for db in $BACKUP_DATABASES; do
  echo "== backing up ${db} =="
  enc="${work}/${db}-${ts}.dump.age"
  docker compose -f "$INFRA_DIR/compose.prod.yaml" exec -T "$POSTGRES_SERVICE" \
    pg_dump -U "$PG_SUPERUSER" -Fc --no-owner --no-privileges "$db" \
    | age "${age_args[@]}" -o "$enc"
  sha256sum "$enc" | awk '{print $1}' > "${enc}.sha256"
  size="$(stat -c%s "$enc")"
  [[ "$size" -gt 0 ]] || { echo "ERROR: empty backup for ${db}" >&2; exit 1; }
  echo "ok: $(basename "$enc") (${size} bytes)"

  upload "$enc" daily
  upload "${enc}.sha256" daily
  if [[ "$dow" == "1" ]]; then upload "$enc" weekly; upload "${enc}.sha256" weekly; fi
  if [[ "$dom" == "01" ]]; then upload "$enc" monthly; upload "${enc}.sha256" monthly; fi
done

echo "== pruning by retention =="
prune daily "$RETAIN_DAILY"
prune weekly "$RETAIN_WEEKLY"
prune monthly "$RETAIN_MONTHLY"

echo "backup complete: ${ts}"
