#!/usr/bin/env bash
# Checks that SILT works without shellops installed, which is the run-time
# rule of ADR.33@strata: shell-logs is SILT's only run-time dependency.
#
# It makes two checks and fails if either one fails:
#
#   1. No file under shell/silt mentions shellops, either by the submodule
#      path or by SHELLOPS_DIR.
#   2. Every golden test passes under dash, on the shell tier and the awk
#      tier, when run from a temporary copy that contains only shell/silt
#      and shell-logs, with SHELLOPS_DIR unset.
#
# Usage: test/silt-without-shellops.sh

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$REPO/test/fixtures/silt"
COPY="$(mktemp -d "${TMPDIR:-/tmp}/silt-without-shellops.XXXXXX")"
trap 'rm -rf "$COPY"' EXIT

main() {
  local failed=0

  check_no_mention_of_shellops || failed=1
  copy_library
  check_goldens_pass || failed=1

  report "$failed"
}

# Fails if any file under shell/silt mentions shellops, and prints each
# line that does.
check_no_mention_of_shellops() {
  local found
  found="$(grep -rnE 'SHELLOPS|shellops|\.ops' "$REPO/shell/silt" || true)"

  if [ -n "$found" ]; then
    printf '## shell/silt mentions shellops:\n%s\n' "$found"
    return 1
  fi
}

# Copies shell/silt and shell-logs into the temporary directory, laid out
# the way SILT expects to find them. shellops is not copied.
copy_library() {
  mkdir -p "$COPY/shell/.logs/shell"
  cp -R "$REPO/shell/silt" "$COPY/shell/silt"
  cp -R "$REPO/shell/.logs/shell/log" "$COPY/shell/.logs/shell/log"
}

# Runs every golden test on both tiers and prints each one that fails.
check_goldens_pass() {
  local calls name threshold failed=0

  for calls in "$FIXTURES"/*/calls.txt; do
    name="$(basename "$(dirname "$calls")")"
    for threshold in 1000000 0; do
      check_golden "$name" "$threshold" || failed=1
    done
  done

  return "$failed"
}

# Runs one golden test from the copy and compares the output with the
# expected transcript. A threshold of 1000000 keeps every call on the shell
# tier, and 0 sends every call to awk.
check_golden() {
  local name="$1" threshold="$2" actual
  actual="$(env -u SHELLOPS_DIR -u SILT_DIR SILT_THRESHOLD="$threshold" \
    dash "$REPO/test/silt-transcript.sh" "$COPY/shell/silt/api.sh" "$FIXTURES/$name/calls.txt" "$(document_of "$name")" \
    2>&1
  )"

  if [ "$actual" != "$(cat "$FIXTURES/$name/expected.txt")" ]; then
    printf '## %s failed without shellops (SILT_THRESHOLD=%s):\n' "$name" "$threshold"
    diff "$FIXTURES/$name/expected.txt" - <<< "$actual" | head -20
    return 1
  fi
}

# Prints the path of the input document for a golden test: its own
# document.silt if it has one, otherwise shell/silt/<name>.fixture.silt if
# that exists, otherwise nothing.
document_of() {
  if [ -f "$FIXTURES/$1/document.silt" ]; then
    printf '%s' "$FIXTURES/$1/document.silt"
  elif [ -f "$REPO/shell/silt/$1.fixture.silt" ]; then
    printf '%s' "$REPO/shell/silt/$1.fixture.silt"
  fi
}

# Prints the result and exits non-zero if a check failed.
report() {
  if [ "$1" -ne 0 ]; then
    printf 'silt-without-shellops: FAILED. SILT depends on shellops at run time; see the output above.\n' >&2
    exit 1
  fi
  printf 'silt-without-shellops: passed. SILT does not depend on shellops at run time.\n'
}

main "$@"
