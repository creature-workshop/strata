#!/usr/bin/env bash
# Measures where the shell tier stops being cheaper than the awk tier: for a
# flat map of N string leaves, the time of one silt__get of the last key with
# the walk forced to the shell (SILT_THRESHOLD past N) and forced to awk
# (SILT_THRESHOLD=0), under dash and under bash, in milliseconds per call
# over a few calls. The number the constant in shell/silt/constants.sh
# carries is read off the bash column, where the two cross first.
#
# Usage: test/silt-threshold.sh [<lines>...]; 50 100 200 400 800 1600 when none

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CALLS=5

main() {
  local sizes=("$@")
  if [ "${#sizes[@]}" -eq 0 ]; then
    sizes=(50 100 200 400 800 1600)
  fi

  printf '%6s  %-12s %-12s  %-12s %-12s\n' lines 'dash shell' 'dash awk' 'bash shell' 'bash awk'
  local lines
  for lines in "${sizes[@]}"; do
    row "$lines"
  done
}

# One row: the four timings for a document of <lines> lines.
row() {
  local lines="$1" doc
  doc="$(wide_map "$lines")"
  printf '%6s  %-12s %-12s  %-12s %-12s\n' "$lines" \
    "$(timed dash "$doc" "$lines" "$((lines + 1))")" \
    "$(timed dash "$doc" "$lines" 0)" \
    "$(timed bash "$doc" "$lines" "$((lines + 1))")" \
    "$(timed bash "$doc" "$lines" 0)"
}

# Milliseconds per silt__get of the last key, under <shell> with the
# threshold at <threshold>, as "<ms> ms".
timed() {
  local shell="$1" doc="$2" lines="$3" threshold="$4" file="$REPO/test/silt-threshold.doc.$$"
  printf '%s' "$doc" > "$file"
  local ms
  ms="$(SILT_THRESHOLD="$threshold" "$shell" "$REPO/test/silt-threshold.bench.sh" "$REPO/shell/silt/api.sh" "$file" "$((lines - 1))" "$CALLS")"
  rm -f "$file"
  printf '%s ms' "$ms"
}

# A map of N string leaves, key0 to keyN-1.
wide_map() {
  local i doc=''
  for ((i = 0; i < $1; i++)); do
    doc="$doc${doc:+$'\n'}0.\"key$i\":str=\"value number $i\""
  done
  printf '%s' "$doc"
}

main "$@"
