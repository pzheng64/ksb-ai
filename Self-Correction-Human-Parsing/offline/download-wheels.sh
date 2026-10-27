#!/usr/bin/env bash
exec "$(cd "$(dirname "$0")/../../offline/schp" && pwd)/download-wheels.sh" "$@"
