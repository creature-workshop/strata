#!/usr/bin/env bats
# The twins: a SILT call and a jq program that must answer the same text over
# the same value, one pair per line of a <name>.twins file under
# test/fixtures/silt, written "<call> => <jq program>", checked by
# test/silt-twins.sh. The jq side reads the JSON twin,
# shell/silt/<name>.fixture.json, and may start with null to ignore it. One
# test per twins file and tier, named for it; a mismatch prints both answers.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
FIXTURES="$BATS_TEST_DIRNAME/fixtures/silt"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

# Registers one test per twins file and tier.
register_twin_cases() {
  local twins name tier
  for twins in "$FIXTURES"/*.twins; do
    name="$(basename "$twins" .twins)"
    for tier in shell awk; do
      bats_test_function --description "twins, $tier tier: every $name call answers as its jq program does" -- twin_case "$name" "$tier"
    done
  done
}

# One twins file on one tier, through test/silt-twins.sh.
twin_case() {
  local threshold=1000000
  if [ "$2" = awk ]; then
    threshold=0
  fi

  run env SILT_THRESHOLD="$threshold" bash "$REPO/test/silt-twins.sh" "$FIXTURES/$1.twins" "$REPO/shell/silt/$1.fixture.json" "$REPO/shell/silt/$1.fixture.silt"
  echo "$output"
  assert_success
}

register_twin_cases
