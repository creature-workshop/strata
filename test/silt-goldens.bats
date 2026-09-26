#!/usr/bin/env bats
# The golden fixtures of the SILT reader, under test/fixtures/silt/. One
# fileset is one case: <name>.name is its name and the test's name in the log,
# <name>.about explains it in plain words and prints when the case fails,
# <name>.calls lists verbs to run with their one argument, <name>.silt is the
# document they run against (absent, the module's own <name>.fixture.silt),
# and <name>.expected is the transcript test/silt-transcript.sh writes.
#
# Every fileset is registered as a test of its own under bash, dash and
# /bin/sh, so a new case is a new fileset and no new test code.
# UPDATE_GOLDENS=1 rewrites the .expected files from the live answers under
# bash, to be read before they are committed.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
FIXTURES="$BATS_TEST_DIRNAME/fixtures/silt"
SHELLS="bash dash sh"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

# Registers every fileset as a test under each shell, named for the case.
register_golden_cases() {
  local calls name shell
  for calls in "$FIXTURES"/*.calls; do
    name="$(basename "$calls" .calls)"
    for shell in $SHELLS; do
      bats_test_function --description "golden under $shell: $(cat "$FIXTURES/$name.name")" -- golden_case "$name" "$shell"
    done
  done
}

# One fileset under one shell: its transcript against its .expected.
golden_case() {
  local name="$1" shell="$2" actual
  actual="$(transcript "$name" "$shell")"

  if [ "${UPDATE_GOLDENS:-}" = 1 ] && [ "$shell" = bash ]; then
    printf '%s\n' "$actual" > "$FIXTURES/$name.expected"
  fi

  if ! diff "$FIXTURES/$name.expected" - <<< "$actual"; then
    echo "## $(cat "$FIXTURES/$name.name") ($name, under $shell): the transcript differs from $name.expected"
    cat "$FIXTURES/$name.about"
    false
  fi
}

# The transcript of a fileset's calls, written by the script under the shell.
transcript() {
  local name="$1" shell="$2"
  "$shell" "$REPO/test/silt-transcript.sh" "$REPO/shell/silt/api.sh" "$FIXTURES/$name.calls" "$(document_of "$name")"
}

# The document a fileset's calls run against: <name>.silt beside the calls,
# else the module's own <name>.fixture.silt, else nothing.
document_of() {
  if [ -f "$FIXTURES/$1.silt" ]; then
    printf '%s' "$FIXTURES/$1.silt"
  elif [ -f "$REPO/shell/silt/$1.fixture.silt" ]; then
    printf '%s' "$REPO/shell/silt/$1.fixture.silt"
  fi
}

register_golden_cases
