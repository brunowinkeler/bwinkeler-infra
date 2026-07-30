#!/usr/bin/env bash
# Provision a per-application database and roles on the SHARED PostgreSQL
# (ARCHITECTURE.md §11.3–§11.4). Idempotent and safe to re-run. Creates:
#
#   <service_id>_db        owned by <service_id>_migrator
#   <service_id>_migrator  role for DDL / migrations
#   <service_id>_runtime   least-privilege runtime role (DML only)
#
# Passwords are supplied via the environment and are NEVER printed, stored, or
# placed on the command line (they travel to the container over stdin only).
#
# Usage:
#   RUNTIME_PASSWORD=... MIGRATOR_PASSWORD=... postgres/provision-app.sh <service_id>
#
# Optional environment:
#   INFRA_DIR         path to the infra compose dir (default /srv/bwinkeler/infra)
#   POSTGRES_SERVICE  compose service name          (default postgres)
#   PG_SUPERUSER      superuser role                (default bw_admin)
set -Eeuo pipefail

service_id="${1:-}"
[[ -n "$service_id" ]] || { echo "usage: provision-app.sh <service_id>" >&2; exit 1; }
[[ "$service_id" =~ ^[a-z][a-z0-9_]{1,30}$ ]] || {
  echo "ERROR: invalid service_id '$service_id' (must match ^[a-z][a-z0-9_]{1,30}$)." >&2
  exit 1
}
: "${RUNTIME_PASSWORD:?set RUNTIME_PASSWORD in the environment}"
: "${MIGRATOR_PASSWORD:?set MIGRATOR_PASSWORD in the environment}"

INFRA_DIR="${INFRA_DIR:-/srv/bwinkeler/infra}"
POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"
PG_SUPERUSER="${PG_SUPERUSER:-bw_admin}"

db="${service_id}_db"
runtime_role="${service_id}_runtime"
migrator_role="${service_id}_migrator"

[[ -f "$INFRA_DIR/compose.prod.yaml" ]] || {
  echo "ERROR: $INFRA_DIR/compose.prod.yaml not found (set INFRA_DIR)." >&2
  exit 1
}

# Escape single quotes for safe SQL string literals. Identifiers are already
# constrained by the service_id pattern above.
runtime_pw_sql="${RUNTIME_PASSWORD//\'/\'\'}"
migrator_pw_sql="${MIGRATOR_PASSWORD//\'/\'\'}"

# Run psql inside the running container as the superuser (local socket = trust).
# SQL arrives on stdin, so no secret ever appears in a process argument list.
psql_db() {
  docker compose -f "$INFRA_DIR/compose.prod.yaml" exec -T "$POSTGRES_SERVICE" \
    psql -v ON_ERROR_STOP=1 -U "$PG_SUPERUSER" -d "$1"
}

echo "== roles + database =="
psql_db postgres <<SQL
DO \$do\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${migrator_role}') THEN
    CREATE ROLE ${migrator_role} LOGIN PASSWORD '${migrator_pw_sql}';
  ELSE
    ALTER ROLE ${migrator_role} LOGIN PASSWORD '${migrator_pw_sql}';
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${runtime_role}') THEN
    CREATE ROLE ${runtime_role} LOGIN PASSWORD '${runtime_pw_sql}';
  ELSE
    ALTER ROLE ${runtime_role} LOGIN PASSWORD '${runtime_pw_sql}';
  END IF;
END
\$do\$;
-- CREATE DATABASE cannot run inside a transaction/DO block; emit it only when
-- absent and execute via \gexec.
SELECT format('CREATE DATABASE %I OWNER %I', '${db}', '${migrator_role}')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db}')\gexec
SQL
echo "ok: roles ensured; database '${db}' present"

echo "== grants + default privileges (in ${db}) =="
psql_db "$db" <<SQL
GRANT CONNECT ON DATABASE ${db} TO ${runtime_role};
ALTER SCHEMA public OWNER TO ${migrator_role};
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO ${runtime_role};

-- Existing objects (safe on a fresh or already-migrated database).
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${runtime_role};
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${runtime_role};

-- Future objects created by the migrator become usable by the runtime role.
ALTER DEFAULT PRIVILEGES FOR ROLE ${migrator_role} IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${runtime_role};
ALTER DEFAULT PRIVILEGES FOR ROLE ${migrator_role} IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO ${runtime_role};
ALTER DEFAULT PRIVILEGES FOR ROLE ${migrator_role} IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO ${runtime_role};
SQL
echo "ok: privileges configured"

echo "== verifying logins over TCP =="
verify_login() {
  local role="$1" pw_env="$2"
  # The password is forwarded by name (-e) from this script's environment; only
  # the variable NAME appears in argv, never the value.
  if docker compose -f "$INFRA_DIR/compose.prod.yaml" exec -T -e "$pw_env" "$POSTGRES_SERVICE" \
      sh -c 'PGPASSWORD="$'"$pw_env"'" psql -h 127.0.0.1 -U '"$role"' -d '"$db"' -tAc "SELECT 1" >/dev/null 2>&1'; then
    echo "ok: login verified for ${role}"
  else
    echo "WARN: could not verify login for ${role} (check pg_hba / password); rerun manually." >&2
  fi
}
export BW_PROV_RUNTIME_PW="$RUNTIME_PASSWORD"
export BW_PROV_MIGRATOR_PW="$MIGRATOR_PASSWORD"
verify_login "$runtime_role" BW_PROV_RUNTIME_PW
verify_login "$migrator_role" BW_PROV_MIGRATOR_PW

cat <<EOF

Provisioned '${service_id}':
  database : ${db}
  migrator : ${migrator_role}   (used only by the one-shot migrate job)
  runtime  : ${runtime_role}    (used by the api container)

Next:
  1. Put the passwords into the host secret files (mode 0600), never in Git:
       /etc/bwinkeler/apps/${service_id}/runtime.env    -> PGUSER=${runtime_role}
       /etc/bwinkeler/apps/${service_id}/migration.env  -> PGUSER=${migrator_role}
  2. Add '${db}' to BACKUP_DATABASES in /etc/bwinkeler/backup.env and to docs/inventory.md.
  3. Run the app migrate job, then start the app.
EOF
