#!/usr/bin/env bash
# Checks that every function under shell/silt is defined once. Prints each
# name that is defined more than once, with the places that define it, and
# fails when there is one.
#
# Usage: test/silt-names.sh [<file>...]; every shell/silt/*.sh when none is given

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

main() {
  local files=("$@")
  if [ "${#files[@]}" -eq 0 ]; then
    files=("$REPO"/shell/silt/*.sh)
  fi

  local findings
  findings="$(awk -f "$REPO/test/silt-names.awk" "${files[@]}")"

  if [ -n "$findings" ]; then
    printf '%s\n' "$findings"
    printf 'silt-names: a function is defined more than once\n' >&2
    exit 1
  fi
  printf 'names: every function is defined once\n'
}

main "$@"
