#!/usr/bin/env bash
set -euo pipefail
DEV="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:-$DEV/dwpose-schp-offline-py312-cu128.tar.gz}"
tar -czf "$OUT" \
  -C "$DEV" \
  offline/common \
  offline/dwpose \
  offline/schp \
  offline/README.md \
  offline/lib-paths.sh \
  DWPose/INSTALL.md \
  DWPose/README.md \
  DWPose/ControlNet-v1-1-nightly \
  Self-Correction-Human-Parsing/networks \
  Self-Correction-Human-Parsing/utils \
  Self-Correction-Human-Parsing/datasets \
  Self-Correction-Human-Parsing/modules \
  Self-Correction-Human-Parsing/simple_extractor.py \
  Self-Correction-Human-Parsing/README.md
echo "Created: $OUT ($(du -h "$OUT" | awk '{print $1}'))"
