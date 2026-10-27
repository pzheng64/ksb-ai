#!/usr/bin/env bash
exec "$(cd "$(dirname "$0")/../../offline/schp" && pwd)/install-offline.sh" "$@"
