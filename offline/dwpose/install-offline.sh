#!/usr/bin/env bash
set -euo pipefail

DWPOSE_OFFLINE="$(cd "$(dirname "$0")" && pwd)"
OFFLINE_ROOT="${OFFLINE_ROOT:-$(cd "$DWPOSE_OFFLINE/.." && pwd)}"
# shellcheck source=../lib-paths.sh
source "$OFFLINE_ROOT/lib-paths.sh"

DWPose_ROOT="${DWPose_ROOT:-$(cd "$DWPOSE_OFFLINE/../../DWPose" && pwd)}"
PY="${PY:-python3.12}"

FIND_LINKS=()
while IFS= read -r link; do
  FIND_LINKS+=(--find-links "$link")
done < <(resolve_wheel_find_links_dwpose)

if ((${#FIND_LINKS[@]} == 0)); then
  echo "Missing wheels under $COMMON_OFFLINE/wheels and/or $DWPOSE_OFFLINE/wheels" >&2
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

if [[ ! -d "$DWPose_ROOT/.venv" ]]; then
  "$PY" -m venv "$DWPose_ROOT/.venv" 2>/dev/null || uv venv "$DWPose_ROOT/.venv" --python "$PY"
fi

PYBIN="$DWPose_ROOT/.venv/bin/python"
"$PYBIN" -m pip install --no-index "${FIND_LINKS[@]}" --upgrade pip setuptools wheel
TORCH_VERSION="${TORCH_VERSION:-2.11.0+cu128}"
TV_VERSION="${TV_VERSION:-0.26.0+cu128}"
TA_VERSION="${TA_VERSION:-2.11.0+cu128}"
"$PYBIN" -m pip install --no-index "${FIND_LINKS[@]}" \
  "torch==${TORCH_VERSION}" "torchvision==${TV_VERSION}" "torchaudio==${TA_VERSION}"
"$PYBIN" -m pip install --no-index "${FIND_LINKS[@]}" \
  -r "$DWPOSE_OFFLINE/requirements-dwpose-gpu-py312.txt"

echo "Installed into $DWPose_ROOT/.venv"
"$PYBIN" - <<'PY'
import torch, onnxruntime as ort
print("torch", torch.__version__, "cuda", torch.version.cuda, "available", torch.cuda.is_available())
print("onnxruntime", ort.__version__, ort.get_available_providers())
PY
