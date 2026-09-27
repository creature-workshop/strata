#!/usr/bin/env bash
# Checks the shape of every function under shell/silt: none runs past 60
# lines, and none nests past two levels, which is an indent of six spaces
# inside a function whose body starts at two. Prints each function that
# breaks either rule and fails when there is one.
#
# Usage: test/silt-shape.sh [<file>...]; every shell/silt/*.sh when none is given

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINES_CAP=60
INDENT_CAP=6

main() {
  local files=("$@")
  if [ "${#files[@]}" -eq 0 ]; then
    files=("$REPO"/shell/silt/*.sh)
  fi

  local findings
  findings="$(scan "${files[@]}")"

  if [ -n "$findings" ]; then
    printf '%s\n' "$findings"
    printf 'silt-shape: a function runs past %s lines or nests past two levels\n' "$LINES_CAP" >&2
    exit 1
  fi
  printf 'shape: every function under %s lines and two levels deep\n' "$LINES_CAP"
}

# One line per function that breaks a rule: file:line name lines=N indent=M.
scan() {
  awk -v lines_cap="$LINES_CAP" -v indent_cap="$INDENT_CAP" '
    /^[a-z_]+\(\) \{/ { name = $1; start = NR; deepest = 0; next }
    name && /^\}/ {
      length_of_body = NR - start - 1
      if (length_of_body > lines_cap || deepest > indent_cap) {
        printf "%s:%d %s lines=%d indent=%d\n", FILENAME, start, name, length_of_body, deepest
      }
      name = ""
      next
    }
    name && $0 !~ /^ *$/ {
      match($0, /^ */)
      if (RLENGTH > deepest) {
        deepest = RLENGTH
      }
    }
  ' "$@"
}

main "$@"
