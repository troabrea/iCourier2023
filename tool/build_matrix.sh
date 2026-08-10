#!/usr/bin/env bash
set -euo pipefail

platform="${1:-all}"
scope="${2:-all}"

if [[ "$scope" == "pilots" ]]; then
  brands=(bmcargo fixocargo)
else
  brands=()
  while IFS= read -r brand; do
    brands+=("$brand")
  done < <(find whitelabel -maxdepth 1 -name '*.json' \
    ! -name '_schema.json' -exec basename {} .json \; | sort)
fi

entrypoint_for() {
  if [[ "$1" == "picknsend" ]]; then
    echo "lib/apps/pns/main_pns.dart"
    return
  fi
  find lib/apps -name "main_$1.dart" -print -quit
}

for brand in "${brands[@]}"; do
  entrypoint="$(entrypoint_for "$brand")"
  if [[ -z "$entrypoint" ]]; then
    echo "No existe entrypoint para $brand" >&2
    exit 1
  fi
  if [[ "$platform" == "android" || "$platform" == "all" ]]; then
    flutter build appbundle \
      --release \
      --flavor "$brand" \
      --target "$entrypoint"
  fi
  if [[ "$platform" == "ios" || "$platform" == "all" ]]; then
    flutter build ios \
      --release \
      --no-codesign \
      --flavor "$brand" \
      --target "$entrypoint"
  fi
done
