#!/usr/bin/env bash
# Checks that SILT runs with shellops absent, the run-time rule of
# ADR.33@strata: strata takes shell-logs at run time and nothing else. Two
# checks, and it fails when either does. No file under shell/silt names
# shellops, by its submodule's path or by SHELLOPS_DIR. And every golden
# fileset runs to its expected transcript under dash, on the shell tier and
# the awk tier, from a copy of the library that holds shell/silt and
# shell-logs' own files and nothing else, with SHELLOPS_DIR unset.
#
# Usage: test/silt-alone.sh

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$REPO/test/fixtures/silt"
ALONE="$(mktemp -d "${TMPDIR:-/tmp}/silt-alone.XXXXXX")"
trap 'rm -rf "$ALONE"' EXIT

main() {
  local failed=0

  names_no_shellops || failed=1
  copy_library
  runs_every_golden || failed=1

  report "$failed"
}

# No file under shell/silt names shellops; prints each line that does.
names_no_shellops() {
  local found
  found="$(grep -rnE 'SHELLOPS|shellops|\.ops' "$REPO/shell/silt" || true)"

  if [ -n "$found" ]; then
    printf '## shell/silt names shellops:\n%s\n' "$found"
    return 1
  fi
}

# The library as a caller at run time holds it: shell/silt, and shell-logs'
# own files where SILT looks for them.
copy_library() {
  mkdir -p "$ALONE/shell/.logs/shell"
  cp -R "$REPO/shell/silt" "$ALONE/shell/silt"
  cp -R "$REPO/shell/.logs/shell/log" "$ALONE/shell/.logs/shell/log"
}

# Every golden fileset on both tiers; prints each that differs.
runs_every_golden() {
  local calls name tier failed=0

  for calls in "$FIXTURES"/*/calls.txt; do
    name="$(basename "$(dirname "$calls")")"
    for tier in 1000000 0; do
      runs_golden "$name" "$tier" || failed=1
    done
  done

  return "$failed"
}

# One golden fileset from the copy, at the threshold that puts every walk
# on a tier, against its expected transcript.
runs_golden() {
  local name="$1" threshold="$2" actual
  actual="$(env -u SHELLOPS_DIR -u SILT_DIR SILT_THRESHOLD="$threshold" \
    dash "$REPO/test/silt-transcript.sh" "$ALONE/shell/silt/api.sh" "$FIXTURES/$name/calls.txt" "$(document_of "$name")" \
    2>&1
  )"

  if [ "$actual" != "$(cat "$FIXTURES/$name/expected.txt")" ]; then
    printf '## %s differs with shellops absent, threshold %s:\n' "$name" "$threshold"
    diff "$FIXTURES/$name/expected.txt" - <<< "$actual" | head -20
    return 1
  fi
}

# The document a fileset's calls run against: its own document.silt, else
# the module's own <name>.fixture.silt, else nothing.
document_of() {
  if [ -f "$FIXTURES/$1/document.silt" ]; then
    printf '%s' "$FIXTURES/$1/document.silt"
  elif [ -f "$REPO/shell/silt/$1.fixture.silt" ]; then
    printf '%s' "$REPO/shell/silt/$1.fixture.silt"
  fi
}

# The verdict.
report() {
  if [ "$1" -ne 0 ]; then
    printf 'silt-alone: SILT does not run with shellops absent\n' >&2
    exit 1
  fi
  printf 'alone: every golden runs with shellops absent, and shell/silt names none of it\n'
}

main "$@"
