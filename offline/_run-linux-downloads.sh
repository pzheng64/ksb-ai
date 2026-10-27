#!/usr/bin/env bash
# Download Linux (manylinux / Ubuntu noble) wheels + debs from a Windows/macOS host.
set -euo pipefail

export OFFLINE_TARGET_OS=linux
export PATH="${HOME}/.local/bin:/c/Program/cmd:${PATH}"
export PY="${PY:-$(uv python find 3.12)}"
export PY_MIRROR="${PY_MIRROR:-$PY}"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OFFLINE="$REPO/offline"
LOGDIR="$OFFLINE/_download-logs"
mkdir -p "$LOGDIR"

ensure_unix_venv_bin() {
  local root="$1"
  local venv="$root/.venv"
  if [[ ! -d "$venv" ]]; then
    uv venv "$venv" --python "$PY" --seed
  fi
  if [[ -f "$venv/Scripts/python.exe" && ! -e "$venv/bin/python" ]]; then
    mkdir -p "$venv/bin"
    ln -sf "../Scripts/python.exe" "$venv/bin/python"
  fi
  if ! "$venv/bin/python" -m pip --version >/dev/null 2>&1; then
    uv pip install --python "$venv/bin/python" pip setuptools wheel
  fi
}

run_one() {
  local script="$1"
  local name
  name="$(basename "$script" .sh)"
  local dir
  dir="$(dirname "$script")"
  echo ""
  echo "========== $(date -Iseconds) $script (OFFLINE_TARGET_OS=linux) =========="
  (
    cd "$dir"
    bash "./$(basename "$script")"
  ) 2>&1 | tee "$LOGDIR/${name}-linux.log"
}

ensure_unix_venv_bin "$REPO/DWPose"
run_one "$OFFLINE/dwpose/download-wheels.sh"
ensure_unix_venv_bin "$REPO/Self-Correction-Human-Parsing"
run_one "$OFFLINE/schp/download-wheels.sh"

echo ""
echo "Linux-targeted downloads finished. Logs: $LOGDIR"
