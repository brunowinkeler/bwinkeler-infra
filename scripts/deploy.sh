#!/usr/bin/env bash
# Bring up / update the shared infrastructure stack (Caddy + PostgreSQL) only.
# Applications deploy from their own repositories. This script NEVER runs
# `down -v` — that would destroy the PostgreSQL data volume (ARCHITECTURE.md §8.2).
set -Eeuo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

[[ -f .env ]] || { echo "ERROR: .env missing — copy .env.example and pin versions." >&2; exit 1; }
[[ -f /etc/bwinkeler/infra.env ]] || {
  echo "ERROR: /etc/bwinkeler/infra.env missing — install it (mode 0600) from templates/infra.env.example." >&2
  exit 1
}

compose() { docker compose --env-file .env -f compose.prod.yaml "$@"; }

echo "== ensuring shared networks =="
"$root/scripts/create-networks.sh"

echo "== validating resolved config =="
compose config >/dev/null

echo "== pulling pinned images =="
compose pull

echo "== starting infrastructure =="
compose up -d --remove-orphans

echo "== status =="
compose ps

cat <<EOF

Infrastructure is up. After adding or changing a Caddy site fragment, reload
Caddy without restarting PostgreSQL:

  docker compose --env-file .env -f compose.prod.yaml exec caddy \\
    caddy reload --config /etc/caddy/Caddyfile
EOF
