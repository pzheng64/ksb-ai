#!/usr/bin/env bash
# Download wheels into offline/common + offline/dwpose (run with internet).
set -euo pipefail

DWPOSE_OFFLINE="$(cd "$(dirname "$0")" && pwd)"
OFFLINE_ROOT="$(cd "$DWPOSE_OFFLINE/.." && pwd)"
# shellcheck source=../lib-paths.sh
source "$OFFLINE_ROOT/lib-paths.sh"

COMMON_WHEELS="$COMMON_OFFLINE/wheels"
DWPOSE_WHEELS="$DWPOSE_OFFLINE/wheels"
DEBS="$COMMON_OFFLINE/debs"
PY="${PY:-python3.12}"
DWPose_ROOT="${DWPose_ROOT:-$(cd "$DWPOSE_OFFLINE/../../DWPose" 2>/dev/null && pwd || echo "")}"

mkdir -p "$COMMON_WHEELS" "$DWPOSE_WHEELS" "$DEBS"
[[ -n "$DWPose_ROOT" && -d "$DWPose_ROOT" ]] && cd "$DWPose_ROOT" || cd "$HOME"

if ! command -v "$PY" >/dev/null 2>&1; then
  echo "Python not found: $PY" >&2
  exit 1
fi

export PATH="${HOME}/.local/bin:${PATH}"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="${HOME}/.local/bin:${PATH}"
fi

VENV="${DWPose_ROOT:-$DWPOSE_OFFLINE}/.venv"
if [[ ! -d "$VENV" ]]; then
  uv venv "$VENV" --python "$PY"
fi

PYBIN="$VENV/bin/python"
PIP_DOWNLOAD=( "$PYBIN" -m pip download --retries 30 --resume-retries 100 --timeout 120 "${OFFLINE_PIP_DOWNLOAD_LINUX_ARGS[@]}" )
"$PYBIN" -m pip install -U pip setuptools wheel

TORCH_VERSION="${TORCH_VERSION:-2.11.0+cu128}"
TV_VERSION="${TV_VERSION:-0.26.0+cu128}"
TA_VERSION="${TA_VERSION:-2.11.0+cu128}"

echo "==> PyTorch cu128 → common/wheels"
if compgen -G "$COMMON_WHEELS/torch-${TORCH_VERSION}*.whl" >/dev/null; then
  echo "  already present; skipping"
else
  "${PIP_DOWNLOAD[@]}" \
    --dest "$COMMON_WHEELS" \
    --index-url https://download.pytorch.org/whl/cu128 \
    --extra-index-url https://pypi.org/simple \
    "torch==${TORCH_VERSION}" "torchvision==${TV_VERSION}" "torchaudio==${TA_VERSION}"
fi

echo "==> DWPose requirements → common + dwpose/wheels"
find "$COMMON_WHEELS" "$DWPOSE_WHEELS" -maxdepth 1 \
  \( -name 'torch-*.whl' -o -name 'torchvision-*.whl' -o -name 'torchaudio-*.whl' \) \
  ! -name '*cu128*' -delete 2>/dev/null || true

DWPOSE_REQ="$DWPOSE_OFFLINE/requirements-dwpose-gpu-py312.txt"
DWPOSE_REQ_TMP=""
if offline_linux_cross_host; then
  DWPOSE_REQ_TMP="$(mktemp)"
  grep -v -E '^(fvcore|iopath|antlr4-python3-runtime)([<=> ].*)?$' "$DWPOSE_REQ" > "$DWPOSE_REQ_TMP" || true
  DWPOSE_REQ="$DWPOSE_REQ_TMP"
fi

"${PIP_DOWNLOAD[@]}" \
  --dest "$DWPOSE_WHEELS" \
  --find-links "$COMMON_WHEELS" \
  --index-url https://download.pytorch.org/whl/cu128 \
  --extra-index-url https://pypi.org/simple \
  -c "$COMMON_OFFLINE/constraints-torch-cu128.txt" \
  -r "$DWPOSE_REQ"

if offline_linux_cross_host; then
  "$PYBIN" -m pip download --retries 30 --resume-retries 100 --timeout 120 \
    --dest "$DWPOSE_WHEELS" --no-binary=:all: fvcore iopath antlr4-python3-runtime || true
fi
[[ -n "$DWPOSE_REQ_TMP" ]] && rm -f "$DWPOSE_REQ_TMP"

"${PIP_DOWNLOAD[@]}" --dest "$COMMON_WHEELS" pip setuptools wheel

echo "==> Ubuntu debs → common/debs"
if offline_linux_cross_host && [[ -f "$OFFLINE_ROOT/download-debs-mirror.py" ]]; then
  PY_MIRROR="${PY_MIRROR:-python3}"
  command -v "$PY_MIRROR" >/dev/null 2>&1 || PY_MIRROR="$PY"
  "$PY_MIRROR" "$OFFLINE_ROOT/download-debs-mirror.py" --out "$DEBS"
elif command -v apt-get >/dev/null 2>&1; then
  (
    cd "$DEBS"
    PKGS=(python3.12 python3.12-venv python3.12-dev libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 libgomp1)
    for p in "${PKGS[@]}"; do
      apt-get download "$p" 2>/dev/null || echo "  (skip $p)"
    done
  )
fi

echo "Done. common/wheels + dwpose/wheels"
du -sh "$COMMON_WHEELS" "$DWPOSE_WHEELS" "$DEBS" 2>/dev/null || true
