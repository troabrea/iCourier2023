#!/usr/bin/env bash
set -euo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly project_dir="$(cd "$script_dir/.." && pwd)"

list_flavors() {
  find "$project_dir/whitelabel" -maxdepth 1 -name '*.json' \
    ! -name '_schema.json' -exec basename {} .json \; | sort
}

usage() {
  cat <<'USAGE'
Uso:
  ./tools/run_flavor.sh <flavor> [opciones de flutter run]
  ./tools/run_flavor.sh --list
  ./tools/run_flavor.sh --devices

Ejemplos:
  ./tools/run_flavor.sh bmcargo
  ./tools/run_flavor.sh bmcargo -d emulator-5554
  ./tools/run_flavor.sh bmcargo -d 00000000-0000-0000-0000-000000000000
  ./tools/run_flavor.sh fixocargo --release

El dispositivo puede ser un emulador o dispositivo Android, un iOS Simulator
o un dispositivo iOS físico. Usa --devices para consultar los IDs disponibles.
USAGE
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

resolve_entrypoint() {
  local flavor="$1"

  # picknsend conserva el nombre historico "pns" en su codigo Dart.
  if [[ "$flavor" == "picknsend" ]]; then
    printf '%s\n' 'lib/apps/pns/main_pns.dart'
    return
  fi

  find "$project_dir/lib/apps" -type f -name "main_${flavor}.dart" \
    -print -quit | sed "s|^$project_dir/||"
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  --list)
    list_flavors
    exit 0
    ;;
  --devices)
    command -v fvm >/dev/null 2>&1 \
      || fail 'FVM no está instalado o no está disponible en PATH.'
    cd "$project_dir"
    exec fvm flutter devices
    ;;
esac

[[ $# -gt 0 ]] || {
  usage >&2
  printf '\nFlavors disponibles:\n' >&2
  list_flavors >&2
  exit 2
}

flavor="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
shift

[[ -f "$project_dir/whitelabel/$flavor.json" ]] || {
  printf 'Error: El flavor "%s" no existe.\n\nFlavors disponibles:\n' "$flavor" >&2
  list_flavors >&2
  exit 2
}

entrypoint="$(resolve_entrypoint "$flavor")"
[[ -n "$entrypoint" && -f "$project_dir/$entrypoint" ]] \
  || fail "No se encontró el entrypoint Dart para el flavor '$flavor'."

command -v fvm >/dev/null 2>&1 \
  || fail 'FVM no está instalado o no está disponible en PATH.'

printf 'Ejecutando flavor "%s"...\n' "$flavor"
printf 'Entrypoint: %s\n' "$entrypoint"

cd "$project_dir"
exec fvm flutter run \
  --flavor "$flavor" \
  --target "$entrypoint" \
  "$@"
