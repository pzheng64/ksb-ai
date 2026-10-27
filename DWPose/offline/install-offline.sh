#!/usr/bin/env bash
exec "$(cd "$(dirname "$0")/../../offline/dwpose" && pwd)/install-offline.sh" "$@"
