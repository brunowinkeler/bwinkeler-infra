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
cp .env.example .env                      # pin CADDY_VERSION / POSTGRES_VERSION

# Superuser secret — written via a temp file (mode 0600), never printed. A temp
# file avoids `/dev/stdin` under sudo, which is unreliable on some hosts:
umask 077
tmp="$(mktemp)"
cat > "$tmp" <<EOF
POSTGRES_USER=bw_admin
POSTGRES_PASSWORD=$(openssl rand -hex 24)
POSTGRES_DB=postgres
EOF
sudo install -m 0600 -o root -g root "$tmp" /etc/bwinkeler/infra.env
rm -f "$tmp"

sudo scripts/validate.sh
sudo scripts/deploy.sh
```

`deploy.sh` creates the networks, validates, pulls pinned images, and starts
Caddy + PostgreSQL — run it and every other infra `docker compose` command with
`sudo`, because the Postgres service reads the root-owned
`/etc/bwinkeler/infra.env`, which only root can read. It never runs `down -v`.

---

## 3. Onboard an application (example: lists)

Contract: `bwinkeler-lists/docs/SERVICE_MANIFEST.md`. This assumes the shared
infrastructure from §2 is already running. **Every secret below is generated on
the host and written straight to a mode-`0600` file — never printed, never
committed.** Run the commands as a user in the `docker` group (on a stock Ubuntu
VPS that is the `ubuntu` user, after `sudo usermod -aG docker ubuntu` and a
re-login). Any `docker compose` (or `provision-app.sh`) command that reads a
secret env_file under `/etc/bwinkeler` must run with `sudo` — those files are
`root:root 0600`.

### 3.1 Database + roles

From `/srv/bwinkeler/infra`. Export the passwords so the same values feed the
secret files in §3.2 — keep this one shell session open:

```sh
export RUNTIME_PASSWORD="$(openssl rand -hex 24)"
export MIGRATOR_PASSWORD="$(openssl rand -hex 24)"
sudo --preserve-env=RUNTIME_PASSWORD,MIGRATOR_PASSWORD postgres/provision-app.sh lists
```

`--preserve-env` keeps the passwords in the environment (never on the command
line) while giving the script the root access it needs to reach Postgres through
the infra compose project.

### 3.2 Host secrets (runtime + migration)

Reuse the passwords from §3.1 and mint a fresh `SESSION_SECRET`. Nothing is
echoed; the values go through a temp file (`mktemp`, mode 0600) that `install`
copies into place — `/dev/stdin` under `sudo` is unreliable on some hosts:

```sh
sudo install -d -m 0750 /etc/bwinkeler/apps/lists

SESSION_SECRET="$(openssl rand -hex 32)"
umask 077
tmp="$(mktemp)"
cat > "$tmp" <<EOF
NODE_ENV=production
HOST=0.0.0.0
PORT=8080
PUBLIC_ORIGIN=https://lists.bwinkeler.com
PGHOST=bw-postgres
PGPORT=5432
PGDATABASE=lists_db
PGUSER=lists_runtime
PGPASSWORD=${RUNTIME_PASSWORD}
SESSION_COOKIE_NAME=lists_sid
CSRF_COOKIE_NAME=lists_csrf
SESSION_TTL_HOURS=168
SESSION_SECRET=${SESSION_SECRET}
LOG_LEVEL=info
EOF
sudo install -m 0600 -o root -g root "$tmp" /etc/bwinkeler/apps/lists/runtime.env

cat > "$tmp" <<EOF
NODE_ENV=production
PGHOST=bw-postgres
PGPORT=5432
PGDATABASE=lists_db
PGUSER=lists_migrator
PGPASSWORD=${MIGRATOR_PASSWORD}
EOF
sudo install -m 0600 -o root -g root "$tmp" /etc/bwinkeler/apps/lists/migration.env

rm -f "$tmp"
unset RUNTIME_PASSWORD MIGRATOR_PASSWORD SESSION_SECRET
```

The runtime file must never carry the migrator password (ARCHITECTURE.md §17.2).

### 3.3 DNS + TLS (Cloudflare)

Create the record and choose the TLS mode — see **§6** for the exact dashboard
steps and the first-certificate bootstrap. Do this while bringing the app up so
Caddy can issue the certificate.

### 3.4 Caddy route

`caddy/sites/lists.caddy` ships with this repo. Validate and reload without
restarting PostgreSQL:

```sh
sudo scripts/validate.sh
sudo docker compose --env-file .env -f compose.prod.yaml exec caddy \
  caddy reload --config /etc/caddy/Caddyfile
```

### 3.5 Deploy the app

Place the app's production Compose manifest at
`/srv/bwinkeler/apps/lists/compose.prod.yaml`; no source build is performed on
the host. If the GHCR packages are private, authenticate root-owned Docker once
with a token scoped to `read:packages` (typed at the hidden password prompt —
never echoed); skip this if you made them public:

```sh
sudo docker login ghcr.io -u brunowinkeler
```

Run the one-shot migration with the migrator role, then start web + api:

```sh
cd /srv/bwinkeler/apps/lists
printf 'APP_VERSION=0.1.2\n' > .env # replace with the immutable version being deployed
sudo docker compose -f compose.prod.yaml --profile tools run --rm migrate
sudo docker compose -f compose.prod.yaml up -d --remove-orphans --wait --wait-timeout 120
```

Pin `APP_VERSION` to an immutable tag; roll back by repointing it and redeploying.

### 3.6 Backup + inventory

Add `lists_db` to `BACKUP_DATABASES` in `/etc/bwinkeler/backup.env` and to
[`inventory.md`](./inventory.md).

### 3.7 Verify

`https://lists.bwinkeler.com` loads, login works, list/item operations succeed,
the WebSocket connects (real-time updates), and the next backup includes
`lists_db`.

---

## 4. Routine operations

Prefix every infra `docker compose` command with `sudo` (they read the
root-owned `/etc/bwinkeler/infra.env`).

| Task                       | Command                                                                       |
| -------------------------- | ----------------------------------------------------------------------------- |
| Status                     | `sudo docker compose --env-file .env -f compose.prod.yaml ps`                 |
| Caddy logs                 | `sudo docker compose … logs -f caddy`                                         |
| Postgres logs              | `sudo docker compose … logs -f postgres`                                      |
| Reload Caddy (no downtime) | `sudo docker compose … exec caddy caddy reload --config /etc/caddy/Caddyfile` |
| psql (superuser)           | `sudo docker compose … exec -it postgres psql -U bw_admin -d postgres`        |
| Rotate an app password     | re-run `postgres/provision-app.sh <id>` + update the secret file              |
| Upgrade Caddy              | bump `CADDY_VERSION` in `.env`, `scripts/validate.sh`, `scripts/deploy.sh`    |

**Never** run `docker compose down -v` here — it destroys `bw-postgres-data`.
Upgrading the PostgreSQL major is a separate, backup-first `pg_dump`/restore
procedure, not a tag bump.

---

## 5. Backups

See [`../backup/README.md`](../backup/README.md). Verify the daily job and run a
restore test at least quarterly.

---

## 6. Cloudflare (DNS + TLS)

`lists.bwinkeler.com` terminates at Caddy on this host and is fronted by
Cloudflare. Caddy obtains a publicly-trusted Let's Encrypt certificate (the
`email` in `caddy/Caddyfile`); Cloudflare then validates that origin
certificate, so the zone runs in **Full (strict)** (ARCHITECTURE.md §10). You
need dashboard access to the `bwinkeler.com` zone.

### 6.1 Issue the first certificate (grey-cloud bootstrap)

The most reliable bootstrap is to let Let's Encrypt reach Caddy directly before
enabling the proxy. Caddy chooses an available ACME challenge automatically:
HTTP-01 on port 80 or TLS-ALPN-01 on port 443. The first Listly deployment used
TLS-ALPN-01 successfully.

1. **DNS → Records → Add record:** Type `A`, Name `lists`, IPv4 = the VPS IP,
   **Proxy status: DNS only (grey cloud)**, TTL Auto. Add an `AAAA` record too if
   the VPS has IPv6.
2. Confirm the firewall allows 80/tcp + 443/tcp (§1.2), then bring up the infra
   (§2) and the app (§3). Caddy completes an ACME challenge and issues the
   certificate. Verify:

```sh
sudo docker compose --env-file .env -f compose.prod.yaml logs caddy | grep -i certificate
curl -I https://lists.bwinkeler.com     # valid Let's Encrypt cert, HTTP 200/308
```

### 6.2 Enable the proxy + Full (strict)

Once HTTPS works directly:

1. **SSL/TLS → Overview:** set the encryption mode to **Full (strict)**.
2. **DNS → Records:** edit the `lists` record → **Proxy status: Proxied (orange
   cloud)**.
3. **SSL/TLS → Edge Certificates:** it is safe to leave **Always Use HTTPS =
   Off** — Caddy already redirects HTTP→HTTPS. If you enable it later, ensure no
   Cloudflare rule blocks `/.well-known/acme-challenge/*` and monitor the next
   certificate renewal.
4. **Network:** confirm **WebSockets = On** (default) so `/ws` works.
5. Enable **HSTS** only after every `*.bwinkeler.com` name is HTTPS.

Renewals are automatic: Caddy renews before expiry using an available ACME
challenge. Keep ports 80/443 reachable and do not block ACME challenge paths.

### 6.3 Alternative: Cloudflare Origin Certificate

To keep the record proxied at all times and avoid public-CA renewals, issue a
15-year **Origin Certificate** (SSL/TLS → Origin Server → Create Certificate),
install the cert + key on the host under `/etc/bwinkeler/` (mode 0600), mount
them into the Caddy container, and replace automatic HTTPS for this site with an
explicit `tls <cert> <key>` directive in `caddy/sites/lists.caddy`. Full (strict)
then validates against Cloudflare's Origin CA — one manual install, no ACME.

### 6.4 Behind-the-proxy notes

- **Client IPs:** requests arrive from Cloudflare IPs; Caddy adds
  `X-Forwarded-For`. The API already sets `trustProxy: true`, so per-IP rate
  limits (e.g. login: 10/min) use the real client IP, not the proxy's.
- **WebSocket keep-alive:** Cloudflare drops idle proxied WebSockets after
  ~100 s; the API already pings every 30 s, so connections stay open.
