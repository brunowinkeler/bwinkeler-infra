# bwinkeler-infra

Private infrastructure repository and **canonical source** for the
`bwinkeler.com` platform. It owns the shared Caddy reverse proxy, the shared
PostgreSQL instance, the external Docker networks, per-app database/role
provisioning, encrypted R2 backups, host bootstrap, and disaster recovery for
independently deployed applications.

The canonical architecture contract is [`ARCHITECTURE.md`](./ARCHITECTURE.md).
Each application keeps a copy at `docs/PLATFORM_ARCHITECTURE.md` and its own
`docs/SERVICE_MANIFEST.md`.

> Applications never define the public Caddy, the shared PostgreSQL, the global
> networks, or the backups. Those are changes to **this** repository.

## Layout

```text
bwinkeler-infra/
├── ARCHITECTURE.md            # canonical platform contract
├── compose.prod.yaml          # shared Caddy + PostgreSQL (no app containers)
├── .env.example               # image version pins (copy to .env)
├── caddy/
│   ├── Caddyfile              # global block + import sites/*
│   └── sites/lists.caddy      # per-domain route fragments
├── postgres/
│   ├── provision-app.sh       # create per-app DB + runtime/migrator roles
│   └── revoke-app.sh          # decommission (destructive, guarded)
├── backup/
│   ├── backup-databases.sh    # pg_dump → age → R2 + checksum + retention
│   └── restore-database.sh    # download → verify → decrypt → restore
├── scripts/
│   ├── bootstrap-host.sh      # dirs + prerequisites + networks
│   ├── create-networks.sh     # idempotent bw-edge / bw-data
│   ├── validate.sh            # compose + Caddy config + networks (read-only)
│   └── deploy.sh              # bring up / update infra (never down -v)
├── templates/                 # *.env.example + site.caddy
└── docs/                      # RUNBOOK, DISASTER_RECOVERY, inventory
```

## Quick start (host)

```sh
cp .env.example .env                       # pin CADDY_VERSION / POSTGRES_VERSION
sudo scripts/bootstrap-host.sh             # dirs + shared networks
# install /etc/bwinkeler/infra.env (0600) from templates/infra.env.example
scripts/validate.sh
scripts/deploy.sh                          # Caddy + PostgreSQL
RUNTIME_PASSWORD=… MIGRATOR_PASSWORD=… postgres/provision-app.sh lists
```

Full procedures are in [`docs/RUNBOOK.md`](./docs/RUNBOOK.md).

## Safety rules

- No secrets in Git — only `*.example` files are tracked; real secrets live in
  `/etc/bwinkeler/` on the host (mode `0600`).
- No `latest` image tags; pin versions in `.env`.
- No published database port; PostgreSQL is only on the internal `bw-data`
  network.
- Never `docker compose down -v` the infra — it destroys `bw-postgres-data`.
- The scripts require Docker Compose v2 and are meant to run on the Linux host
  (Ubuntu LTS), not on a workstation.

## Currently onboarded

| App | Domain | Database | Status |
| --- | --- | --- | --- |
| [lists](../bwinkeler-lists) | `lists.bwinkeler.com` | `lists_db` | onboarding |

See [`docs/inventory.md`](./docs/inventory.md).
