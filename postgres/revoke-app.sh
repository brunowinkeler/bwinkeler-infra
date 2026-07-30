#!/usr/bin/env bash
# DESTRUCTIVE: remove a per-application database and roles from the shared
# PostgreSQL (ARCHITECTURE.md §19.4). Before running, follow the decommission
# order: disable public ingress, take a FINAL verified backup, and let the
# quarantine period pass. Requires an explicit --yes.
#
# Usage:
#   postgres/revoke-app.sh <service_id> --yes
set -Eeuo pipefail

service_id="${1:-}"
confirm="${2:-}"
[[ -n "$service_id" ]] || { echo "usage: revoke-app.sh <service_id> --yes" >&2; exit 1; }
[[ "$service_id" =~ ^[a-z][a-z0-9_]{1,30}$ ]] || { echo "ERROR: invalid service_id." >&2; exit 1; }
[[ "$confirm" == "--yes" ]] || {
  echo "Refusing without --yes. This DROPS the database and roles for '$service_id'." >&2
  exit 1
}

INFRA_DIR="${INFRA_DIR:-/srv/bwinkeler/infra}"
POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"
PG_SUPERUSER="${PG_SUPERUSER:-bw_admin}"

db="${service_id}_db"
runtime_role="${service_id}_runtime"
migrator_role="${service_id}_migrator"

echo "About to DROP database '${db}' and roles '${migrator_role}', '${runtime_role}'."
echo "Confirm a final, verified backup exists and quarantine has passed."
echo "Press Ctrl-C within 10s to abort..."
sleep 10

docker compose -f "$INFRA_DIR/compose.prod.yaml" exec -T "$POSTGRES_SERVICE" \
  psql -v ON_ERROR_STOP=1 -U "$PG_SUPERUSER" -d postgres <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${db}' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS ${db};
DROP ROLE IF EXISTS ${runtime_role};
DROP ROLE IF EXISTS ${migrator_role};
SQL

cat <<EOF
Removed '${service_id}' from PostgreSQL. Also remove:
  - /etc/bwinkeler/apps/${service_id}/   (secret files)
  - '${db}' from BACKUP_DATABASES in /etc/bwinkeler/backup.env
  - the entry in docs/inventory.md
If DROP ROLE failed due to dependencies in another database, run
REASSIGN OWNED / DROP OWNED there first.
EOF
