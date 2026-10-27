# SCHP offline helpers — shared bundle under dev/offline/
_schp_offline_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFLINE_ROOT="${OFFLINE_ROOT:-$(cd "$_schp_offline_dir/.." && pwd)}"
# shellcheck source=../lib-paths.sh
source "$OFFLINE_ROOT/lib-paths.sh"

SCHP_ROOT="${SCHP_ROOT:-$(cd "$_schp_offline_dir/../../Self-Correction-Human-Parsing" && pwd)}"

resolve_wheel_find_links() {
  resolve_wheel_find_links_schp
}

resolve_debs_download_dir() {
  local d
  d="$(resolve_debs_dir)"
  if [[ -n "$d" ]]; then
    echo "$d"
  else
    echo "$COMMON_OFFLINE/debs"
  fi
}

write_schp_debs_pointer() {
  local target="${1:-$COMMON_OFFLINE/debs}"
  mkdir -p "$SCHP_OFFLINE/debs"
  cat > "$SCHP_OFFLINE/debs/README.txt" <<EOF
Ubuntu .deb packages (shared):

  ${target}

See: ${OFFLINE_ROOT}/README.md
EOF
}

write_schp_wheels_pointer() {
  local _target="${1:-$COMMON_OFFLINE/wheels}"
  mkdir -p "$SCHP_OFFLINE/wheels"
  cat > "$SCHP_OFFLINE/wheels/README.txt" <<EOF
Shared PyTorch / common wheels:

  ${COMMON_OFFLINE}/wheels

SCHP-only wheels:

  ${SCHP_OFFLINE}/wheels
EOF
}
