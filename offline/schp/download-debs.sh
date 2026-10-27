#!/usr/bin/env bash
set -euo pipefail

SCHP_OFFLINE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-offline.sh
source "$SCHP_OFFLINE/lib-offline.sh"

DEBS="$(resolve_debs_download_dir)"
mkdir -p "$DEBS"

if _offline_has_debs "$COMMON_OFFLINE"; then
  echo "==> Common offline debs already present; skipping download."
  echo "    $DEBS"
  write_schp_debs_pointer "$DEBS"
  exit 0
fi

PKGS=(
  python3.12 python3.12-venv python3.12-dev python3-pip
  build-essential ninja-build git
  libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 libgomp1
)

if ! command -v apt-get >/dev/null 2>&1; then
  if [[ "${OFFLINE_TARGET_OS:-}" == "linux" && -f "$OFFLINE_ROOT/download-debs-mirror.py" ]]; then
    PY_MIRROR="${PY_MIRROR:-python3}"
    command -v "$PY_MIRROR" >/dev/null 2>&1 || PY_MIRROR="python3.12"
    "$PY_MIRROR" "$OFFLINE_ROOT/download-debs-mirror.py" --out "$DEBS"
    write_schp_debs_pointer "$DEBS"
    du -sh "$DEBS"
    exit 0
  fi
  echo "apt-get not found." >&2
  exit 1
fi

apt-get update -qq 2>/dev/null || sudo apt-get update -qq 2>/dev/null || true

collect_deps() {
  apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts \
    --no-breaks --no-replaces --no-enhances "$1" 2>/dev/null \
    | grep -E '^[[:alnum:]]' | sort -u
}

mapfile -t ALL_DEPS < <(
  { for p in "${PKGS[@]}"; do collect_deps "$p"; done; } | sort -u
)

echo "==> Downloading ${#ALL_DEPS[@]} packages to $DEBS"
(
  cd "$DEBS"
  for p in "${ALL_DEPS[@]}"; do
    apt-get download "$p" 2>/dev/null || echo "  (skip: $p)"
  done
)

write_schp_debs_pointer "$DEBS"
du -sh "$DEBS"
