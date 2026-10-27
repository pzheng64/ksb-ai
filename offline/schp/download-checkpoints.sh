#!/usr/bin/env bash
# Download official SCHP pretrained weights (~267 MB each). Run on a connected machine.
set -euo pipefail

SCHP_OFFLINE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-offline.sh
source "$SCHP_OFFLINE/lib-offline.sh"
CKPT="$SCHP_ROOT/checkpoints"
mkdir -p "$CKPT"

download_one() {
  local name="$1"
  local gdrive_id="$2"
  local hf_url="$3"
  local dest="$CKPT/$name"

  if [[ -f "$dest" ]] && [[ $(stat -c%s "$dest" 2>/dev/null || echo 0) -gt 100000000 ]]; then
    echo "==> Already present: $name ($(du -h "$dest" | cut -f1))"
    return 0
  fi

  echo "==> Downloading $name ..."
  if command -v gdown >/dev/null 2>&1; then
    if gdown "https://drive.google.com/uc?id=${gdrive_id}" -O "$dest" --continue 2>/dev/null \
      && [[ $(stat -c%s "$dest") -gt 100000000 ]]; then
      return 0
    fi
    rm -f "$dest"
  fi

  if curl -fL --retry 5 --retry-delay 3 -C - -o "$dest" "$hf_url" \
    && [[ $(stat -c%s "$dest") -gt 100000000 ]]; then
    return 0
  fi
  rm -f "$dest"

  echo "Failed: $name (install gdown: pip install gdown, or download manually from README)" >&2
  return 1
}

# Google Drive file IDs from README.md; Hugging Face mirrors as fallback.
download_one "exp-schp-201908261155-lip.pth" \
  "1k4dllHpu0bdx38J7H28rVVLpU-kOHmnH" \
  "https://huggingface.co/levihsu/OOTDiffusion/resolve/main/checkpoints/humanparsing/exp-schp-201908261155-lip.pth"

download_one "exp-schp-201908301523-atr.pth" \
  "1ruJg4lqR_jgQPj-9K0PP-L2vJERYOxLP" \
  "https://huggingface.co/panyanyany/Self-Correction-Human-Parsing/resolve/main/schp/exp-schp-201908301523-atr.pth"

download_one "exp-schp-201908270938-pascal-person-part.pth" \
  "1E5YwNKW2VOEayK9mWCS3Kpsxf-3z04ZE" \
  "https://huggingface.co/panyanyany/Self-Correction-Human-Parsing/resolve/main/schp/exp-schp-201908270938-pascal-person-part.pth"

failed=0
for f in exp-schp-201908261155-lip.pth exp-schp-201908301523-atr.pth exp-schp-201908270938-pascal-person-part.pth; do
  if [[ ! -f "$CKPT/$f" ]] || [[ $(stat -c%s "$CKPT/$f") -lt 100000000 ]]; then
    echo "Missing or incomplete: $f" >&2
    failed=1
  fi
done

echo ""
echo "Checkpoints in $CKPT:"
ls -lh "$CKPT"/*.pth 2>/dev/null || true
du -sh "$CKPT"
exit $failed
