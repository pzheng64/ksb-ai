#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.local/bin:/c/Program/cmd:${PATH}"
export PY="${PY:-$(uv python find 3.12)}"

OFFLINE="/c/dev/ksb-ai/offline"
LOGDIR="$OFFLINE/_download-logs"
mkdir -p "$LOGDIR"

# Scripts expect Unix venv layout (.venv/bin/python); uv on Windows uses Scripts/.
ensure_unix_venv_bin() {
  local venv="$1/.venv"
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
  echo "========== $(date -Iseconds) $script =========="
  (
    cd "$dir"
    bash "./$(basename "$script")"
  ) 2>&1 | tee "$LOGDIR/${name}.log"
}

# README order: dwpose base stack, then SCHP (wheels invokes debs).
ensure_unix_venv_bin "/c/dev/ksb-ai/DWPose"
run_one "$OFFLINE/dwpose/download-wheels.sh"
ensure_unix_venv_bin "/c/dev/ksb-ai/Self-Correction-Human-Parsing"
run_one "$OFFLINE/schp/download-wheels.sh"
run_one "$OFFLINE/schp/download-checkpoints.sh"

# Explicit debs script (no-op if already populated by download-wheels).
if [[ -f "$OFFLINE/schp/download-debs.sh" ]]; then
  run_one "$OFFLINE/schp/download-debs.sh" || {
    echo "WARN: download-debs.sh failed (expected on Windows without apt-get)." >&2
  }
fi

echo ""
echo "All download scripts finished. Logs: $LOGDIR"
