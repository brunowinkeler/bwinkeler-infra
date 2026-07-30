# Backups and restoration

Encrypted logical backups of the shared PostgreSQL databases to Cloudflare R2
(ARCHITECTURE.md §20). Objectives for family apps: RPO ≤ 24 h, RTO ≤ 4 h.

- `backup-databases.sh` — `pg_dump -Fc` per database → `age` encryption →
  upload to R2 with a SHA-256 sidecar → prune by retention.
- `restore-database.sh` — download → verify checksum → decrypt → restore
  (into a scratch `<db>_restore` by default).

## One-time setup (on the host)

1. Install tooling: `age`, `rclone` (and Docker/compose for the running DB).
2. Generate an age key pair; keep the **private** key OFF the VPS:
   ```sh
   age-keygen -o key.txt          # copy key.txt to your password manager, then remove it
   grep 'public key' key.txt      # the age1... recipient goes into backup.env
   ```
3. Configure an rclone remote for R2 (token scoped to the backups bucket only):
   ```sh
   rclone config    # new remote, type=s3, provider=Cloudflare, endpoint=<account>.r2.cloudflarestorage.com
   ```
   Or set `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` / `R2_ACCOUNT_ID` in
   `backup.env` and let the script build a temporary remote from the environment.
4. Install `/etc/bwinkeler/backup.env` (mode `0600`) from
   [`../templates/backup.env.example`](../templates/backup.env.example) and list
   the databases in `BACKUP_DATABASES`.

## Schedule (daily)

Example root crontab (02:30 UTC):

```cron
30 2 * * * /srv/bwinkeler/infra/backup/backup-databases.sh >> /var/log/bw-backup.log 2>&1
```

Weekly/monthly copies are made automatically on Mondays / the 1st. Retention is
`RETAIN_DAILY` / `RETAIN_WEEKLY` / `RETAIN_MONTHLY`. Backups are never deleted
before newer valid copies exist.

## Restore test (at least quarterly — ARCHITECTURE.md §20.4)

```sh
AGE_IDENTITY=/secure/key.txt backup/restore-database.sh lists_db   # -> lists_db_restore
# run the app's checks against lists_db_restore, record duration, then:
docker compose -f /srv/bwinkeler/infra/compose.prod.yaml exec -T postgres \
  psql -U bw_admin -d postgres -c 'DROP DATABASE lists_db_restore;'
```

## Disaster recovery

Full host rebuild is documented in
[`../docs/DISASTER_RECOVERY.md`](../docs/DISASTER_RECOVERY.md). The private age key
and the R2 credentials are the two things that must survive the loss of the VPS.

## Notes

- The VPS provider snapshot is a complementary layer, not a substitute for these
  encrypted dumps (ARCHITECTURE.md §20.2).
- Dumps use `--no-owner --no-privileges` for portability; roles/grants are
  recreated by `postgres/provision-app.sh`, not by the restore.
