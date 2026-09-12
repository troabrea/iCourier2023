#!/usr/bin/env bash
set -euo pipefail
# Credentials are parsed as data by Python; never source or trace them.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$script_dir/android_release.py" "$@"
