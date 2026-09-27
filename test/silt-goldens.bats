#!/usr/bin/env bats
# The golden fixtures of the SILT reader, under test/fixtures/silt/. One
# fileset is one case: <name>.name is its name and the test's name in the log,
# <name>.about explains it in plain words and prints when the case fails,
# <name>.calls lists verbs to run with their one argument, <name>.silt is the
# document they run against (absent, the module's own <name>.fixture.silt),
# and <name>.expected is the transcript test/silt-transcript.sh writes. A
# document a call reads by name, <file>.json, .yaml, .toml, .strh or .strt,
# carries its own <file>.name and <file>.about beside it, and a test checks
# that each does.
#
# Every fileset is registered as a test of its own under bash, dash and
# /bin/sh, on the shell tier and again with every walk handed to awk, so a
# new case is a new fileset and no new test code.
# UPDATE_GOLDENS=1 rewrites the .expected files from the live answers under
# bash, to be read before they are committed.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
FIXTURES="$BATS_TEST_DIRNAME/fixtures/silt"
SHELLS="bash dash sh"
TIERS="shell awk"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

# Registers every fileset as a test under each shell and each tier, named
# for the case. The awk tier is every walk handed to awk, SILT_THRESHOLD=0.
register_golden_cases() {
  local calls name shell tier
  for calls in "$FIXTURES"/*.calls; do
    name="$(basename "$calls" .calls)"
    for tier in $TIERS; do
      for shell in $SHELLS; do
        bats_test_function --description "golden, $tier tier under $shell: $(cat "$FIXTURES/$name.name")" -- golden_case "$name" "$shell" "$tier"
      done
    done
  done
}

# One fileset under one shell and tier: its transcript against its .expected.
golden_case() {
  local name="$1" shell="$2" tier="$3" actual
  actual="$(transcript "$name" "$shell" "$tier")"

  if [ "${UPDATE_GOLDENS:-}" = 1 ] && [ "$shell" = bash ] && [ "$tier" = shell ]; then
    printf '%s\n' "$actual" > "$FIXTURES/$name.expected"
  fi

  if ! diff "$FIXTURES/$name.expected" - <<< "$actual"; then
    echo "## $(cat "$FIXTURES/$name.name") ($name, $tier tier under $shell): the transcript differs from $name.expected"
    cat "$FIXTURES/$name.about"
    false
  fi
}

# The transcript of a fileset's calls, written by the script under the shell
# and the tier.
transcript() {
  local name="$1" shell="$2" tier="$3"
  SILT_THRESHOLD="$(threshold_of "$tier")" "$shell" "$REPO/test/silt-transcript.sh" "$REPO/shell/silt/api.sh" "$FIXTURES/$name.calls" "$(document_of "$name")"
}

# The threshold that puts every walk on a tier: the library's own for the
# shell tier, 0 for awk.
threshold_of() {
  if [ "$1" = awk ]; then
    printf '0'
  else
    printf '1000000'
  fi
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

# Every document a call reads by name carries a name and an about of its own.
@test "golden documents: every .json, .yaml, .toml, .strh and .strt under the fixtures has a .name and an .about beside it" {
  local document missing=''
  for document in "$FIXTURES"/*.json "$FIXTURES"/*.yaml "$FIXTURES"/*.toml "$FIXTURES"/*.strh "$FIXTURES"/*.strt; do
    [ -f "$document.name" ] && [ -f "$document.about" ] || missing="$missing $(basename "$document")"
  done
  [ -z "$missing" ] || fail "documents with no name or about:$missing"
}

register_golden_cases
