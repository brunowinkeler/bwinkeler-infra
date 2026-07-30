# Disaster recovery

Rebuild the whole platform on a new VPS from this repository plus the off-host
backups (ARCHITECTURE.md §20.5). Target RTO ≤ 4 h.

## What must survive the loss of the VPS

These live **off** the VPS (password manager / offline media) and cannot be
regenerated from it:

1. the **age private key** used to decrypt backups;
2. the **R2 credentials** (or the rclone remote config) for the backups bucket;
3. the **superuser** `POSTGRES_PASSWORD` and each app's runtime/migration
   passwords (or the ability to rotate them);
4. access to Cloudflare (DNS), GitHub/GHCR (images), and the VPS provider.

This Git repository holds everything non-secret: compose files, Caddy config,
scripts, and this runbook.

## Recovery procedure

1. **Provision a new VPS** (same or larger spec) and apply the security baseline
   (RUNBOOK §1.2).
2. **Install Docker** and clone this repo to `/srv/bwinkeler/infra`.
3. `cp .env.example .env` and pin the same `POSTGRES_VERSION` used by the
   backups (a dump restores into the same or a newer major only).
4. **Recreate secrets** under `/etc/bwinkeler/` from the encrypted copies:
   `infra.env`, `backup.env`, and `apps/<id>/{runtime,migration}.env`.
5. **Create networks + start infra:** `scripts/bootstrap-host.sh` then
   `scripts/deploy.sh` (brings up Caddy + an empty PostgreSQL).
6. **Recreate roles + databases:** run `postgres/provision-app.sh <id>` for each
   app with its known passwords (this restores roles/grants; the data comes next).
7. **Restore data** for each database from the latest good backup:
   ```sh
   AGE_IDENTITY=/secure/key.txt backup/restore-database.sh lists_db --target lists_db --yes
   ```
   Verify the checksum step passes before the restore proceeds.
8. **Pull versioned images + start each app** from its own repo
   (`deploy/compose.prod.yaml`, immutable `APP_VERSION`). Run the migrate job
   only if the restored schema predates the target image.
9. **Add the Caddy fragments** (already in `caddy/sites/`) and reload Caddy.
10. **Repoint DNS** in Cloudflare to the new host; keep the old host (if it
    exists) for rollback until validation passes.
11. **Validate** HTTPS, login, main flows, and WebSocket for each app; confirm
    the backup job runs on the new host.

## After recovery

- Rotate any credential that may have been exposed during the incident.
- Record the actual RTO, what was missing, and fixes in an ADR.
- Re-run a restore test to confirm the new host's backup chain is healthy.
