#!/usr/bin/env bash
set -euo pipefail

SCHP_OFFLINE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-offline.sh
source "$SCHP_OFFLINE/lib-offline.sh"
PY="${PY:-python3.12}"

FIND_LINKS=()
while IFS= read -r link; do
  FIND_LINKS+=(--find-links "$link")
done < <(resolve_wheel_find_links)

if ((${#FIND_LINKS[@]} == 0)); then
  echo "Missing wheels under $COMMON_OFFLINE/wheels (run offline/dwpose/download-wheels.sh)." >&2
  exit 1
fi

DEBS="$(resolve_debs_dir)"
if [[ "${SKIP_DEBS:-0}" != "1" && -n "$DEBS" ]] && command -v dpkg >/dev/null 2>&1; then
  echo "==> Installing .deb packages from $DEBS ..."
  if sudo -n true 2>/dev/null; then
    sudo dpkg -i "$DEBS"/*.deb 2>/dev/null || sudo apt-get install -y -f
  else
    echo "  (skipped sudo; run: sudo dpkg -i $DEBS/*.deb)"
  fi
fi

if ! command -v "$PY" >/dev/null 2>&1; then
  echo "Install Python 3.12 first." >&2
  exit 1
fi

if [[ ! -d "$SCHP_ROOT/.venv" ]]; then
  "$PY" -m venv "$SCHP_ROOT/.venv" 2>/dev/null || uv venv "$SCHP_ROOT/.venv" --python "$PY"
fi

PYBIN="$SCHP_ROOT/.venv/bin/python"
"$PYBIN" -m pip install --no-index "${FIND_LINKS[@]}" --upgrade pip setuptools wheel
TORCH_VERSION="${TORCH_VERSION:-2.11.0+cu128}"
TV_VERSION="${TV_VERSION:-0.26.0+cu128}"
TA_VERSION="${TA_VERSION:-2.11.0+cu128}"
"$PYBIN" -m pip install --no-index "${FIND_LINKS[@]}" \
  "torch==${TORCH_VERSION}" "torchvision==${TV_VERSION}" "torchaudio==${TA_VERSION}"
"$PYBIN" -m pip install --no-index "${FIND_LINKS[@]}" \
  -r "$SCHP_OFFLINE/requirements-schp-gpu-py312.txt"

echo "Installed into $SCHP_ROOT/.venv"
"$PYBIN" - <<'PY'
import torch
print("torch", torch.__version__, "cuda", torch.version.cuda, "available", torch.cuda.is_available())
PY
