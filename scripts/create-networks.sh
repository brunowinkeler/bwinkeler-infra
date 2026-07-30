#!/usr/bin/env bash
# Create the shared external Docker networks idempotently (ARCHITECTURE.md §7.4).
# Applications never create these; they attach as `external`. Fails loudly if a
# network already exists with an unexpected driver instead of recreating it.
set -Eeuo pipefail

networks=("bw-edge" "bw-data")
expected_driver="bridge"

ensure_network() {
  local name="$1" driver
  if docker network inspect "$name" >/dev/null 2>&1; then
    driver="$(docker network inspect -f '{{.Driver}}' "$name")"
    if [[ "$driver" != "$expected_driver" ]]; then
      echo "ERROR: network '$name' exists with driver '$driver' (expected '$expected_driver')." >&2
      echo "Refusing to modify it — inspect and reconcile manually." >&2
      exit 1
    fi
    echo "ok: '$name' already present ($driver)"
  else
    docker network create --driver "$expected_driver" "$name" >/dev/null
    echo "created: '$name' ($expected_driver)"
  fi
}

for n in "${networks[@]}"; do
  ensure_network "$n"
done

echo "Shared networks ready: ${networks[*]}"
