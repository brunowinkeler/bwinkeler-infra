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

## DNS (Cloudflare)

| Record | Target | Proxy | Notes |
| --- | --- | --- | --- |
| `bwinkeler.com` | Cloudflare Pages | — | portfolio |
| `physics.bwinkeler.com` | Cloudflare Pages | — | planned custom domain; no VPS or Caddy route |
| `lists.bwinkeler.com` | VPS `A`/`AAAA` | proxied | TLS `Full (strict)` |

## Backups

| Database | Class | Location | Retention |
| --- | --- | --- | --- |
| `lists_db` | daily | R2 `bwinkeler-backups/postgres/{daily,weekly,monthly}` | 7 / 4 / 6 |

## Cloudflare cache rules

None configured. Document any rule here (ARCHITECTURE.md §10.4).
