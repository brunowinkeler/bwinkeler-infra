# Runbook — bwinkeler-infra

Operational procedures for the shared host (Caddy + PostgreSQL). Canonical
architecture: [`../ARCHITECTURE.md`](../ARCHITECTURE.md). Nothing here contains
secrets.

Paths on the host:

- `/srv/bwinkeler/infra` — this repository (non-secret manifests + scripts).
- `/etc/bwinkeler/` — secrets, mode `0600`/`0750` (`infra.env`, `backup.env`,
  `apps/<id>/{runtime,migration}.env`).

Run infra commands from `/srv/bwinkeler/infra` with `.env` present.

---

## 1. Provision a new host

Fresh, supported Ubuntu LTS VPS (ARCHITECTURE.md §21, §23).

### 1.1 Install Docker

```sh
curl -fsSL https://get.docker.com | sh
docker compose version    # confirm the v2 plugin
```

### 1.2 Harden (do this before exposing anything)

```sh
# Administrative user with sudo; SSH by key only.
adduser deploy && usermod -aG sudo,docker deploy
# In /etc/ssh/sshd_config: PermitRootLogin no, PasswordAuthentication no
systemctl restart ssh

# Firewall — allow SSH + HTTP/HTTPS only. Add the SSH rule FIRST.
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp        # HTTP/3
ufw enable

# Automatic security updates.
apt-get install -y unattended-upgrades && dpkg-reconfigure -plow unattended-upgrades
```

MFA on Cloudflare, GitHub, OVHcloud, and the registrar accounts.

### 1.3 Bootstrap the layout + networks

```sh
sudo scripts/bootstrap-host.sh
```

---

## 2. Bring up the infrastructure

```sh
cp .env.example .env                     # pin CADDY_VERSION / POSTGRES_VERSION
sudo install -m 600 /dev/stdin /etc/bwinkeler/infra.env < templates/infra.env.example
sudo "$EDITOR" /etc/bwinkeler/infra.env  # set a strong POSTGRES_PASSWORD
scripts/validate.sh
scripts/deploy.sh
```

`deploy.sh` creates the networks, validates, pulls pinned images, and starts
Caddy + PostgreSQL. It never runs `down -v`.

---

## 3. Onboard an application (example: lists)

Contract: `bwinkeler-lists/docs/SERVICE_MANIFEST.md`.

1. **Database + roles:**
   ```sh
   RUNTIME_PASSWORD="$(openssl rand -base64 24)" \
   MIGRATOR_PASSWORD="$(openssl rand -base64 24)" \
     postgres/provision-app.sh lists
   ```
2. **Secrets on the host** (mode 600), from the app's `deploy/env/*.example`:
   - `/etc/bwinkeler/apps/lists/runtime.env` (`PGUSER=lists_runtime`, `SESSION_SECRET`, …)
   - `/etc/bwinkeler/apps/lists/migration.env` (`PGUSER=lists_migrator`)
3. **Caddy route:** `caddy/sites/lists.caddy` is already present. Validate + reload:
   ```sh
   scripts/validate.sh
   docker compose --env-file .env -f compose.prod.yaml exec caddy \
     caddy reload --config /etc/caddy/Caddyfile
   ```
4. **DNS:** create a proxied `A`/`AAAA` record for `lists.bwinkeler.com` → this
   host; Cloudflare TLS mode `Full (strict)` (ARCHITECTURE.md §10).
5. **Deploy the app** from the app repo (`bwinkeler-lists/deploy/compose.prod.yaml`):
   run the `migrate` tools profile, then `up -d`. Pin `APP_VERSION` to an
   immutable tag.
6. **Backup + inventory:** add `lists_db` to `BACKUP_DATABASES` and
   [`inventory.md`](./inventory.md).
7. **Verify:** HTTPS, login, main operations, WebSocket, and that the backup
   includes the new DB.

---

## 4. Routine operations

| Task | Command |
| --- | --- |
| Status | `docker compose --env-file .env -f compose.prod.yaml ps` |
| Caddy logs | `docker compose … logs -f caddy` |
| Postgres logs | `docker compose … logs -f postgres` |
| Reload Caddy (no downtime) | `… exec caddy caddy reload --config /etc/caddy/Caddyfile` |
| psql (superuser) | `… exec -it postgres psql -U bw_admin -d postgres` |
| Rotate an app password | re-run `postgres/provision-app.sh <id>` + update the secret file |
| Upgrade Caddy | bump `CADDY_VERSION` in `.env`, `scripts/validate.sh`, `scripts/deploy.sh` |

**Never** run `docker compose down -v` here — it destroys `bw-postgres-data`.
Upgrading the PostgreSQL major is a separate, backup-first `pg_dump`/restore
procedure, not a tag bump.

---

## 5. Backups

See [`../backup/README.md`](../backup/README.md). Verify the daily job and run a
restore test at least quarterly.
