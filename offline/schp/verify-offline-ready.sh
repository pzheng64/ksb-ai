#!/usr/bin/env bash
set -euo pipefail

SCHP_OFFLINE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-offline.sh
source "$SCHP_OFFLINE/lib-offline.sh"
PY="${PY:-python3.12}"

fail=0
warn() { echo "WARN: $*" >&2; }
err() { echo "ERROR: $*" >&2; fail=1; }
ok() { echo "OK: $*"; }

echo "==> Offline readiness (SCHP + shared bundle)"
echo "    OFFLINE_ROOT=$OFFLINE_ROOT"
echo ""

if _offline_has_debs "$COMMON_OFFLINE"; then
  n=$(ls -1 "$COMMON_OFFLINE/debs/"*.deb | wc -l)
  ok "common/debs: $n files"
else
  err "Missing common/debs. Run: bash offline/dwpose/download-wheels.sh or offline/schp/download-debs.sh"
fi

if _offline_has_wheels "$COMMON_OFFLINE"; then
  n=$(ls -1 "$COMMON_OFFLINE/wheels/"*.whl | wc -l)
  sz=$(du -sh "$COMMON_OFFLINE/wheels" | cut -f1)
  ok "common/wheels: $n files ($sz)"
else
  err "Missing common/wheels. Run: bash offline/dwpose/download-wheels.sh"
fi

if _offline_has_wheels "$DWPOSE_OFFLINE"; then
  n=$(ls -1 "$DWPOSE_OFFLINE/wheels/"*.whl | wc -l)
  ok "dwpose/wheels: $n files"
else
  warn "No dwpose-only wheels (OK if you only need SCHP)"
fi

if _offline_has_wheels "$SCHP_OFFLINE"; then
  n=$(ls -1 "$SCHP_OFFLINE/wheels/"*.whl | wc -l)
  ok "schp/wheels: $n files"
else
  warn "No schp/wheels yet — run: bash offline/schp/download-wheels.sh"
fi

mapfile -t FIND_DIRS < <(resolve_wheel_find_links)
FIND_LINKS=()
for d in "${FIND_DIRS[@]}"; do FIND_LINKS+=(--find-links "$d"); done

if [[ -x "$SCHP_ROOT/.venv/bin/python" ]]; then
  PYBIN="$SCHP_ROOT/.venv/bin/python"
elif [[ -x "$(dirname "$OFFLINE_ROOT")/DWPose/.venv/bin/python" ]]; then
  PYBIN="$(dirname "$OFFLINE_ROOT")/DWPose/.venv/bin/python"
else
  warn "No venv for pip dry-run; skipping resolution check."
  [[ $fail -eq 0 ]] || exit 1
  exit 0
fi

TORCH_VERSION="${TORCH_VERSION:-2.11.0+cu128}"
TV_VERSION="${TV_VERSION:-0.26.0+cu128}"
TA_VERSION="${TA_VERSION:-2.11.0+cu128}"

if ! "$PYBIN" -m pip install --dry-run --no-index "${FIND_LINKS[@]}" \
  "torch==${TORCH_VERSION}" "torchvision==${TV_VERSION}" "torchaudio==${TA_VERSION}" \
  -r "$SCHP_OFFLINE/requirements-schp-gpu-py312.txt" >/tmp/schp-offline-dry-run.log 2>&1; then
  err "SCHP requirements do not resolve from offline wheels."
  tail -30 /tmp/schp-offline-dry-run.log >&2
  fail=1
else
  ok "requirements-schp-gpu-py312.txt resolves offline"
fi

CKPT_DIR="$SCHP_ROOT/checkpoints"
if compgen -G "$CKPT_DIR/"'exp-schp-*.pth' >/dev/null; then
  ok "checkpoints present in $CKPT_DIR"
else
  warn "No checkpoints — run: bash offline/schp/download-checkpoints.sh"
fi

[[ $fail -eq 0 ]] && echo "Ready." || exit 1
