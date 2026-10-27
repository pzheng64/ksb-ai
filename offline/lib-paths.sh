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
