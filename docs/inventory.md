# Platform inventory

Source of truth for what is deployed on the shared host. Update it on every
onboarding, decommission, or route change (ARCHITECTURE.md §4.2). No secrets.

## Host

| Item | Value |
| --- | --- |
| Provider / region | OVHcloud — Germany (Limburg) |
| Plan | VPS-1 2027 (2 vCPU / 4 GB / 40 GB NVMe) — revalidate before recreating |
| OS | Ubuntu LTS |
| Infra path | `/srv/bwinkeler/infra` |
| Secrets path | `/etc/bwinkeler/` |

## Shared services

| Service | Image | Alias | Networks | Volume |
| --- | --- | --- | --- | --- |
| Caddy | `caddy:${CADDY_VERSION}` | `bw-caddy` | `bw-edge` | `bw-caddy-data`, `bw-caddy-config` |
| PostgreSQL | `postgres:${POSTGRES_VERSION}` (16) | `bw-postgres` | `bw-data` | `bw-postgres-data` |

External networks (infra-owned): `bw-edge`, `bw-data`.

## Applications

| Service ID | Domain | Compose project | Database | Roles | App networks | Backup | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `lists` | `lists.bwinkeler.com` | `bw-lists` | `lists_db` | `lists_runtime`, `lists_migrator` | `bw-edge`, `bw-data`, `bw-lists-private` | daily | onboarding |
| `finances` | `finances.bwinkeler.com` | `bw-finances` | `finances_db` | `finances_runtime`, `finances_migrator` | `bw-edge`, `bw-data`, `bw-finances-private` | daily | active |

App images: `ghcr.io/brunowinkeler/lists-web`, `ghcr.io/brunowinkeler/lists-api`,
`ghcr.io/brunowinkeler/finances-web`, `ghcr.io/brunowinkeler/finances-api` (finances
images are private; root Docker on the host pulls them with a `read:packages` token).

Finances is the only application behind **Cloudflare Access**: a self-hosted
Access application on `finances.bwinkeler.com` with Google login and an Allow
policy for the two household addresses. Its API rejects requests without a valid
Access token, so the Caddy route alone does not expose it.

## Cloudflare Pages applications

| Service ID | Domain | Pages project | Repository | Persistent state | VPS dependency | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `physics` | `physics.bwinkeler.com` | `bwinkeler-physics` | `brunowinkeler/bwinkeler-physics` | none | none | onboarding |
| `keyplay` | `play.bwinkeler.com` | `bwinkeler-keyplay` | `brunowinkeler/bwinkeler-keyplay` | none | none | active |
| `practice` | `practice.bwinkeler.com` | `bwinkeler-practice` | `brunowinkeler/bwinkeler-music-practice` | browser IndexedDB only | none | onboarding |

## Cloudflare Workers applications

| Service ID | Domain | Worker | Repository | Persistent state | Backup | VPS dependency | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `aquarium` | `aquarium.bwinkeler.com` | `bwinkeler-aquarium` | `brunowinkeler/bwinkeler-aquarium` | Durable Objects (SQLite) and the private R2 bucket `bwinkeler-aquarium-files` | none | none | onboarding |

Aquarium data is short-lived by design: an aquarium and its images are deleted
when its TV ends it or 4 hours after the TV disconnects, so nothing is backed up
(aquarium ADR 001 and ADR 003). First deployed by hand with `wrangler deploy` on
2026-11-08; since v0.2.0 every `v*` tag deploys through the repository's
`deploy.yaml`. The aquarium screen (`/` for a mouse or touch screen, `/tv/` for a
remote), the phone PWA (`/join/`, with printable templates) and the API are
live; the webOS TV package waits for the TV spike, so the status stays
`onboarding`.

## DNS (Cloudflare)

| Record | Target | Proxy | Notes |
| --- | --- | --- | --- |
| `bwinkeler.com` | Cloudflare Pages | — | portfolio |
| `physics.bwinkeler.com` | Cloudflare Pages | — | planned custom domain; no VPS or Caddy route |
| `play.bwinkeler.com` | Cloudflare Pages | — | active custom domain; no VPS or Caddy route |
| `practice.bwinkeler.com` | Cloudflare Pages | — | not registered yet; the project serves `bwinkeler-practice.pages.dev` and the name is still negotiable |
| `lists.bwinkeler.com` | VPS `A`/`AAAA` | proxied | TLS `Full (strict)` |
| `finances.bwinkeler.com` | VPS `A`/`AAAA` | proxied | TLS `Full (strict)`; Cloudflare Access application in front |
| `aquarium.bwinkeler.com` | Worker Custom Domain (`bwinkeler-aquarium`) | — | active since 2026-11-08; no VPS or Caddy route |

## Backups

| Database | Class | Location | Retention |
| --- | --- | --- | --- |
| `lists_db` | daily | R2 `bwinkeler-backups/postgres/{daily,weekly,monthly}` | 7 / 4 / 6 |
| `finances_db` | daily | R2 `bwinkeler-backups/postgres/{daily,weekly,monthly}` | 7 / 4 / 6 |

Root crontab runs `backup/backup-databases.sh` at 02:30 UTC (log
`/var/log/bw-backup.log`). The R2 bucket `bwinkeler-backups` (location WEUR) and
the first backups were created on 2026-11-13; before that no backup had ever run.
The `age` private key is kept off the VPS by the owner. Last restore test:
2026-11-13, both dumps downloaded, checksum-verified, decrypted on the
workstation and restored into a scratch PostgreSQL 16 (`lists_db` 9 tables,
`finances_db` 21 tables).

## Cloudflare cache rules

None configured. Document any rule here (ARCHITECTURE.md §10.4).

### Open item: browser cache TTL on custom domains

The zone raises the browser TTL of static responses whose origin TTL is shorter,
so `https://play.bwinkeler.com/sw.js` answers `max-age=14400` while
`https://bwinkeler-keyplay.pages.dev/sw.js` keeps the `no-cache` value from the
application `_headers` file. A cached service worker delays an update by up to
four hours.

Fix by either setting **Caching › Configuration › Browser Cache TTL** to
*Respect Existing Headers* for the zone, or adding a cache rule for
`play.bwinkeler.com` paths `/sw.js` and `/manifest.webmanifest` with browser TTL
*Respect origin*. Record the chosen rule in the table above.
