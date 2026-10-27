#!/usr/bin/env bash
set -euo pipefail

SCHP_OFFLINE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-offline.sh
source "$SCHP_OFFLINE/lib-offline.sh"
PY="${PY:-python3.12}"

mkdir -p "$SCHP_OFFLINE/wheels" "$COMMON_OFFLINE/wheels"
cd "$SCHP_ROOT"

export PATH="${HOME}/.local/bin:${PATH}"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="${HOME}/.local/bin:${PATH}"
fi

if [[ ! -d "$SCHP_ROOT/.venv" ]]; then
  uv venv "$SCHP_ROOT/.venv" --python "$PY"
fi

PYBIN="$SCHP_ROOT/.venv/bin/python"
PIP_DOWNLOAD=( "$PYBIN" -m pip download --retries 30 --resume-retries 100 --timeout 120 "${OFFLINE_PIP_DOWNLOAD_LINUX_ARGS[@]}" )
"$PYBIN" -m pip install -U pip setuptools wheel

if _offline_has_wheels "$COMMON_OFFLINE"; then
  echo "==> Reusing common wheels: $COMMON_OFFLINE/wheels"
  write_schp_wheels_pointer
else
  echo "Run offline/dwpose/download-wheels.sh first (PyTorch + common stack)." >&2
  exit 1
fi

FIND_LINKS=()
while IFS= read -r link; do
  FIND_LINKS+=(--find-links "$link")
done < <(resolve_wheel_find_links)

filter_req_for_linux_cross() {
  local src="$1"
  if ! offline_linux_cross_host; then
    echo "$src"
    return 0
  fi
  local tmp
  tmp="$(mktemp)"
  grep -v -E '^(fvcore|iopath|antlr4-python3-runtime)([<=> ].*)?$' "$src" > "$tmp" || true
  echo "$tmp"
}

echo "==> SCHP-only wheels → schp/wheels"
SCHP_EXTRAS_REQ="$(filter_req_for_linux_cross "$SCHP_OFFLINE/requirements-schp-extras.txt")"
SCHP_GPU_REQ="$(filter_req_for_linux_cross "$SCHP_OFFLINE/requirements-schp-gpu-py312.txt")"
DOWNLOAD_ARGS=( "${PIP_DOWNLOAD[@]}" --dest "$SCHP_OFFLINE/wheels" --extra-index-url https://download.pytorch.org/whl/cu128 )
DOWNLOAD_ARGS+=("${FIND_LINKS[@]}")
if [[ -f "$COMMON_OFFLINE/constraints-torch-cu128.txt" ]]; then
  DOWNLOAD_ARGS+=(-c "$COMMON_OFFLINE/constraints-torch-cu128.txt")
fi
"${DOWNLOAD_ARGS[@]}" -r "$SCHP_EXTRAS_REQ"

FILL_ARGS=( "${PIP_DOWNLOAD[@]}" --dest "$SCHP_OFFLINE/wheels" --extra-index-url https://download.pytorch.org/whl/cu128 )
while IFS= read -r link; do
  FILL_ARGS+=(--find-links "$link")
done < <(resolve_wheel_find_links)
"${FILL_ARGS[@]}" -r "$SCHP_GPU_REQ"

if offline_linux_cross_host; then
  "$PYBIN" -m pip download --retries 30 --resume-retries 100 --timeout 120 \
    --dest "$SCHP_OFFLINE/wheels" --no-binary=:all: fvcore iopath antlr4-python3-runtime || true
fi
[[ "$SCHP_EXTRAS_REQ" != "$SCHP_OFFLINE/requirements-schp-extras.txt" ]] && rm -f "$SCHP_EXTRAS_REQ"
[[ "$SCHP_GPU_REQ" != "$SCHP_OFFLINE/requirements-schp-gpu-py312.txt" ]] && rm -f "$SCHP_GPU_REQ"

bash "$SCHP_OFFLINE/download-debs.sh"
echo "Done."
