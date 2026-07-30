#!/usr/bin/env bash
# Idempotent host bootstrap for the bwinkeler platform (ARCHITECTURE.md §8.1, §21).
# Creates the directory layout, verifies prerequisites, and creates the shared
# Docker networks. It deliberately does NOT install packages, configure the
# firewall, or change SSH — a wrong firewall rule can lock you out of the VPS.
# Those steps are in docs/RUNBOOK.md. Run as root on a fresh, supported VPS.
set -Eeuo pipefail

[[ "$(id -u)" -eq 0 ]] || { echo "ERROR: run as root." >&2; exit 1; }

echo "== checking prerequisites =="
command -v docker >/dev/null || {
  echo "ERROR: Docker is not installed. See docs/RUNBOOK.md → 'Install Docker'." >&2
  exit 1
}
docker compose version >/dev/null 2>&1 || {
  echo "ERROR: the Docker Compose v2 plugin is missing." >&2
  exit 1
}
echo "ok: $(docker --version), $(docker compose version | head -n1)"

echo "== creating directory layout =="
install -d -m 0755 /srv/bwinkeler /srv/bwinkeler/infra /srv/bwinkeler/apps /srv/bwinkeler/restore-work
install -d -m 0750 /etc/bwinkeler /etc/bwinkeler/apps
echo "ok: /srv/bwinkeler and /etc/bwinkeler ready"

echo "== creating shared networks =="
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/create-networks.sh"

cat <<'EOF'

Bootstrap complete. Next steps (docs/RUNBOOK.md):
  1. Harden the host: SSH keys only, disable password/root SSH, firewall
     (allow 22/tcp, 80/tcp, 443/tcp + 443/udp), enable unattended-upgrades.
  2. Copy this repository to /srv/bwinkeler/infra and: cp .env.example .env
  3. Install /etc/bwinkeler/infra.env (chmod 600) from templates/infra.env.example.
  4. scripts/deploy.sh                         # start Caddy + PostgreSQL
  5. RUNTIME_PASSWORD=... MIGRATOR_PASSWORD=... postgres/provision-app.sh lists
  6. Install app secrets under /etc/bwinkeler/apps/<id>/ and deploy the app.
  7. Install /etc/bwinkeler/backup.env and schedule backup/backup-databases.sh.
EOF
