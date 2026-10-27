#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/c/Program/cmd:${PATH}"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="${HOME}/.local/bin:${PATH}"
fi
uv --version
uv python install 3.12
PY312="$(uv python find 3.12)"
echo "Python at: ${PY312}"
"${PY312}" --version
