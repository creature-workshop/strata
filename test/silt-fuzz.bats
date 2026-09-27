#!/usr/bin/env bats
# A few seeds of the differential fuzz, test/silt-fuzz.sh, so a merge request
# runs the fuzzer at all; the nightly run in .gitlab-ci.yml takes hundreds.
# Skipped where yq, or node with fast-check under test/fuzz, is not
# installed, since jq and yq are the oracles and fast-check the generator.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

@test "fuzz: three seeds agree with jq and yq on the shell tier and the awk tier" {
  command -v yq >/dev/null || skip "yq is not installed"
  command -v node >/dev/null && [ -d "$REPO/test/fuzz/node_modules/fast-check" ] || skip "node with fast-check under test/fuzz is not installed"
  run env SILT_THRESHOLD=1000000 bash "$REPO/test/silt-fuzz.sh" --seeds 3 --from 1
  echo "$output"
  assert_success
  run env SILT_THRESHOLD=0 bash "$REPO/test/silt-fuzz.sh" --seeds 3 --from 4
  echo "$output"
  assert_success
}
