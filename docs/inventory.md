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

App images: `ghcr.io/brunowinkeler/lists-web`, `ghcr.io/brunowinkeler/lists-api`.

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
`deploy.yaml`. The phone PWA (`/`, with printable templates), the TV browser
builds (`/tv/` for a remote, `/pc/` for a mouse or touch screen) and the API are
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
| `aquarium.bwinkeler.com` | Worker Custom Domain (`bwinkeler-aquarium`) | — | active since 2026-11-08; no VPS or Caddy route |

## Backups

| Database | Class | Location | Retention |
| --- | --- | --- | --- |
| `lists_db` | daily | R2 `bwinkeler-backups/postgres/{daily,weekly,monthly}` | 7 / 4 / 6 |

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
