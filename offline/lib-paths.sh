# Shared offline bundle layout (source from project offline/*.sh scripts).
#   $DEV/offline/common   — PyTorch cu128, Ubuntu debs, wheels used by both projects
#   $DEV/offline/dwpose   — DWPose-only wheels + install/download scripts
#   $DEV/offline/schp     — SCHP-only wheels + install/download scripts

_offline_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFLINE_ROOT="$_offline_lib"
COMMON_OFFLINE="$OFFLINE_ROOT/common"
DWPOSE_OFFLINE="$OFFLINE_ROOT/dwpose"
SCHP_OFFLINE="$OFFLINE_ROOT/schp"

_offline_has_wheels() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir/wheels" ]] && compgen -G "$dir/wheels/"'*.whl' >/dev/null
}

_offline_has_debs() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir/debs" ]] && compgen -G "$dir/debs/"'*.deb' >/dev/null
}

# pip --find-links order: common → project-specific
resolve_wheel_find_links_dwpose() {
  local out=()
  _offline_has_wheels "$COMMON_OFFLINE" && out+=("$COMMON_OFFLINE/wheels")
  _offline_has_wheels "$DWPOSE_OFFLINE" && out+=("$DWPOSE_OFFLINE/wheels")
  printf '%s\n' "${out[@]}"
}

resolve_wheel_find_links_schp() {
  local out=()
  _offline_has_wheels "$COMMON_OFFLINE" && out+=("$COMMON_OFFLINE/wheels")
  _offline_has_wheels "$SCHP_OFFLINE" && out+=("$SCHP_OFFLINE/wheels")
  printf '%s\n' "${out[@]}"
}

resolve_debs_dir() {
  if _offline_has_debs "$COMMON_OFFLINE"; then
    echo "$COMMON_OFFLINE/debs"
  else
    echo ""
  fi
}

offline_linux_cross_host() {
  [[ "${OFFLINE_TARGET_OS:-}" == "linux" ]] && [[ "$(uname -s 2>/dev/null)" != "Linux" ]]
}

# Cross-download manylinux wheels from macOS/Windows (OFFLINE_TARGET_OS=linux).
OFFLINE_PIP_DOWNLOAD_LINUX_ARGS=()
if offline_linux_cross_host; then
  OFFLINE_PIP_DOWNLOAD_LINUX_ARGS=(
    --platform manylinux_2_28_x86_64
    --platform manylinux2014_x86_64
    --python-version 3.12
    --implementation cp
    --abi cp312
    --only-binary=:all:
  )
fi
