# Platform improvements and pending work

> Cross-project backlog for the `bwinkeler.com` platform. Consolidated on
> 2026-07-30 from a working session and moved into this repository on
> 2026-09-06 (it used to sit untracked in the aggregator folder).
> Priorities: **P1** = required for/around the deploy · **P2** = soon ·
> **P3** = backlog/later. Tick `[x]` as items are resolved.

---

## 1. Deploy — checklist to go live

> This checklist predates the production deployment. Reconcile every item
> against [`inventory.md`](./inventory.md), which is the source of truth for
> what is actually running.

- [x] **P1** Push the `bwinkeler-infra` repository to its remote (it only had the
      local commit `d6bfe15`).
- [ ] **P1** Provision the VPS (OVHcloud, Ubuntu LTS): install Docker, harden the
      host (SSH by key only, disable root/password login, firewall 22/80/443,
      `unattended-upgrades`) — see [`RUNBOOK.md`](./RUNBOOK.md) §1.
- [ ] **P1** Run `scripts/bootstrap-host.sh` (creates directories plus the
      `bw-edge`/`bw-data` networks).
- [ ] **P1** Install `/etc/bwinkeler/infra.env` (PostgreSQL superuser,
      `chmod 600`) and `.env` (version pins), then `scripts/deploy.sh` (brings up
      Caddy and PostgreSQL).
- [ ] **P1** Run `postgres/provision-app.sh lists` (creates `lists_db` plus the
      `lists_runtime`/`lists_migrator` roles); generate strong passwords and
      store them in `/etc/bwinkeler/apps/lists/{runtime,migration}.env`.
- [ ] **P1** Cloudflare: DNS record for `lists.bwinkeler.com` (proxied) pointing
      at the VPS; TLS **Full (strict)**.
- [ ] **P1** Publish images: keep CI green on `main`, tag
      `git tag v0.1.0 && git push origin v0.1.0` so `release.yaml` publishes
      `ghcr.io/brunowinkeler/lists-{api,web}`.
- [ ] **P1** Bring the app up: `deploy/compose.prod.yaml` with `APP_VERSION=0.1.0`
      (run the `migrate` job of the `tools` profile **before** `up -d`).
- [ ] **P1** Add the existing Caddy fragment (`caddy/sites/lists.caddy`) and
      `caddy reload`; validate HTTPS, login, operations, and the WebSocket from
      outside.
- [ ] **P1** **Backup**: install `/etc/bwinkeler/backup.env`, generate the `age`
      key (keep the **private key off the VPS**), configure rclone → R2 (token
      scoped to the bucket), schedule `backup-databases.sh` (cron), and **run a
      restore test**.
- [ ] **P2** Record the release plus its rollback target (previous tag) in the
      infra inventory.

---

## 2. Infrastructure repository (`bwinkeler-infra`)

- [x] **P2** Add a CI workflow: `shellcheck` + `caddy validate` +
      `docker compose config` (plus `actionlint`) — see
      [`../.github/workflows/ci.yaml`](../.github/workflows/ci.yaml).
- [ ] **P2** Set `mem_limit`/`cpus` in `compose.prod.yaml` (Caddy/PostgreSQL)
      **after measuring** (4 GB VPS).
- [ ] **P3** Document a PostgreSQL major upgrade procedure (backup first,
      `pg_dump`/restore).
- [ ] **P3** Evaluate Docker Secrets / SOPS+age / Vault once the `.env` files in
      `/etc/bwinkeler` stop being sufficient.
- [ ] **P3** Minimum observability: external uptime monitor
      (`lists.bwinkeler.com`), disk/RAM/CPU alerts, and a daily check of the
      backup result.

---

## 3. Tests and quality (`bwinkeler-lists`)

- [ ] **P2** **Backend** unit coverage is missing (only 5 Vitest tests, in
      `shared/test/dto.test.ts`). Add service tests:
  - `duplicateList` (copies categories, remaps `categoryId`, **clears
    assignees**, include/reset-completed options).
  - `toCategoryDto` (includes `color`) and `toListSummary` (includes `pinned`).
  - Fractional index ordering (`keyBetween` / positions).
  - Category/item authorization (owner vs editor) and grant provisioning.
- [ ] **P2** The newer features (categories/colours, pin, duplication, drag and
      drop) are covered **only** by the 12 e2e tests (Chromium) plus smoke.
      Consider HTTP-level API integration tests in addition to the e2e suite.
- [ ] **P3** The drag e2e test depends on coordinates and timing (mouse); keep
      the `dragOnto` helper and the "midpoint" test as a regression guard.

---

## 4. Accessibility and UI

- [ ] **P2** `LST-QUA-006` requires **WCAG 2.2 AA** but has **not been audited**.
      Do an accessibility pass:
  - **Keyboard** reordering for drag and drop (the dnd-kit keyboard sensor was
    unstable in this environment) — guarantee an accessible alternative to
    dragging.
  - Contrast of the **category colours** (palette) on light and dark themes.
  - Focus and roles in modals and popovers (notifications, colour picker,
    duplicate).
- [ ] **P2** Verify responsiveness from **320 px** upwards (`LST-QUA-005`).
- [ ] **P3** There is no administration UI to create or manage accounts — today
      it is only the `create-user` CLI.

---

## 5. Known limitations and accepted risks (revisit)

- [ ] **P2** The global **`isAdmin` flag does nothing**: `requireAdmin` exists but
      no route uses it. Decide whether to implement admin routes (for example,
      creating a user from the UI) **or** to remove the flag and document that.
      Define what "admin" means.
- [ ] **P2** **`/health/live` depends on the database**: the server only listens
      after connecting to PostgreSQL, which contradicts §14.1 ("live must not fail
      because of an external dependency"). Consider listening first and checking
      the database only in `ready`, avoiding a restart loop when the database
      wobbles.
- [ ] **P2** **Accepted** dependency advisories (review on every update):
      `react-router`/`react-router-dom` GHSA-qwww-vcr4-c8h2 (RSC mode only — not
      applicable to the SPA) and `esbuild` via `drizzle-kit`
      GHSA-67mh-4wv8-2f99 (development only). Move to a clean tree once patches
      land.
- [ ] **P3** **Notes** use last-write-wins over the whole field, so simultaneous
      edits of the same item can lose text (character-level merge is out of
      scope).
- [ ] **P3** **Cascading deletion**: deleting the owner account removes their
      lists and revokes everyone's access, with no ownership transfer (the UI
      confirms this).
- [ ] **P3** **Single backend replica**: a restart drops the WebSocket (mitigated
      by reconnect/resync). Multiple replicas would require a bus (Redis/NATS)
      plus shared sessions.
- [ ] **P3** The owner should clearly see **pending** invitations (visibility of
      the pending state).

---

## 6. Feature backlog (excluded from v1 — `REQUIREMENTS §1.3`)

Add when it makes sense; none of these block the deploy:

- [ ] **E-mail/push** notifications and more notification events.
- [ ] Presence and typing indicators.
- [ ] **Offline** editing / CRDT.
- [ ] File **attachments** (would require R2/object storage).
- [ ] List **ownership transfer**.
- [ ] Item **priority**, **multiple labels** (tagging), **subtasks**, **quantity**.
- [ ] A dedicated "shopping" kind.
- [ ] **Internationalization** (English only today).
- [ ] Native **mobile** apps.
- [ ] **Public self-registration** (invitation/admin only today).
- [ ] **SSO/OIDC** across the platform applications.

---

## 7. Hygiene and reminders

- [ ] **P3** `frontend/dist/` may hold an old build mentioning "Tandem" — it is a
      gitignored artifact and disappears on the next `npm run build`. Source and
      docs are already fully "Listly".
- [ ] **P3** Development over the LAN: open the port in Windows Firewall (Wi-Fi
      uses the Public profile) from an **elevated** terminal with
      `New-NetFirewallRule -DisplayName "Listly dev 5173" -Direction Inbound -Protocol TCP -LocalPort 5173 -Action Allow -Profile Any`.
- [ ] **P3** Stable identifiers that must **not** change: `service_id lists`,
      `lists.bwinkeler.com`, `lists_db`, the `lists-web`/`lists-api` images, the
      `bwinkeler-lists` repository, and the `@bwinkeler-lists/*` packages (only
      the **display name** became Listly).
