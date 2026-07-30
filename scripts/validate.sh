#!/usr/bin/env bash
# Validate the shared infrastructure before a deploy (ARCHITECTURE.md §8.2, §9.6).
# Read-only: makes no changes.
#   - resolves/type-checks the infra compose (needs .env);
#   - validates the Caddyfile + all site fragments;
#   - reports whether the shared networks exist.
set -Eeuo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fail=0

echo "== docker compose config =="
if [[ -f .env ]]; then
  if docker compose --env-file .env -f compose.prod.yaml config >/dev/null; then
    echo "ok: compose.prod.yaml resolves"
  else
    echo "FAIL: compose.prod.yaml invalid"; fail=1
  fi
else
  echo "skip: no .env (copy .env.example); cannot resolve version pins"
fi

echo "== caddy validate =="
caddy_ver="2"
if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  . ./.env
  set +a
  caddy_ver="${CADDY_VERSION:-2}"
fi
if docker run --rm \
    -v "$root/caddy/Caddyfile:/etc/caddy/Caddyfile:ro" \
    -v "$root/caddy/sites:/etc/caddy/sites:ro" \
    "caddy:${caddy_ver}" \
    caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile >/dev/null 2>&1; then
  echo "ok: Caddyfile + sites valid"
else
  echo "FAIL: Caddy configuration invalid"
  echo "  re-run without redirection to see details:"
  echo "  docker run --rm -v \"$root/caddy/Caddyfile:/etc/caddy/Caddyfile:ro\" -v \"$root/caddy/sites:/etc/caddy/sites:ro\" caddy:${caddy_ver} caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile"
  fail=1
fi

echo "== shared networks =="
for n in bw-edge bw-data; do
  if docker network inspect "$n" >/dev/null 2>&1; then
    echo "ok: '$n' present"
  else
    echo "WARN: '$n' missing — run scripts/create-networks.sh"
  fi
done

[[ "$fail" -eq 0 ]] && echo "validate: PASS" || echo "validate: FAIL"
exit "$fail"
