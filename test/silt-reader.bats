#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # bats runs each case in a subshell of its own; a variable set in one is meant to stay there
# The properties of the SILT reader (shell/silt/api.sh) that a golden
# transcript cannot carry; the goldens themselves are test/silt-goldens.bats.
# Here: the jq oracle over the fixture's JSON twin, the answer variable's
# check, the process and timing cases, which run test/silt-exercise.sh under
# strace and under the clock, and the coverage gate, test/silt-coverage.sh,
# which reads bash's trace of the goldens.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

setup() {
  export SILT_DIR="$REPO/shell/silt"
  # shellcheck source=../shell/silt/api.sh
  . "$REPO/shell/silt/api.sh"
  MAP="$(cat "$REPO/shell/silt/map.fixture.silt")"
  MAP_JSON="$REPO/shell/silt/map.fixture.json"
  NL=$'\n'
}

# A SILT list document of str or int leaves, as the JSON array it spells:
# each leaf's value is already a JSON literal, so the array is the values
# joined by commas.
list_as_json() {
  local line values=''
  while IFS= read -r line; do
    values="$values${values:+,}${line#*=}"
  done <<< "$1"
  printf '[%s]' "$values"
}

# A map document of N string leaves, for the timing and the strace cases.
wide_map() {
  local i doc=''
  for ((i = 0; i < $1; i++)); do
    doc="$doc${doc:+$NL}0.\"key$i\":str=\"value number $i\""
  done
  printf '%s' "$doc"
}

# Asserts silt__string answers a path as jq -r does over the JSON twin.
assert_string_like_jq() {
  local path="$1" got
  silt__string got "$MAP" "$path"
  assert_equal "$got" "$(jq -r "$path" "$MAP_JSON")"
}

@test "the twin: string answers a path as jq -r does" {
  assert_string_like_jq '.tests["test/a.bats"].reads[1]'
  assert_string_like_jq '."a \"quoted\" key: with.dots"'
  assert_string_like_jq .text
  assert_string_like_jq .unicode
}

@test "the twin: len and keys answer as jq length and keys_unsorted do" {
  silt__len got "$MAP"
  assert_equal "$got" "$(jq length "$MAP_JSON")"

  silt__keys got "$MAP"
  assert_equal "$(list_as_json "$got" | jq -c .)" "$(jq -c keys_unsorted "$MAP_JSON")"
}

@test "the twin: unwrap decodes the escapes jq -r does" {
  silt__unwrap got '"\/\b\f"'
  assert_equal "$got" "$(jq -rn '"\/\b\f"')"
}

@test "the answer variable is checked before anything is evaluated through it" {
  run silt__get 'x; touch /tmp/silt-pwned' "$MAP" .runner
  assert_failure
  assert_output --partial "not a variable name"
  run silt__type '1abc' "$MAP"
  assert_failure
}

# The process starts (clone, fork, execve) one mode of test/silt-exercise.sh
# makes under dash over the wide document, counted by strace.
process_starts() {
  strace -f -qq -e trace=clone,clone3,fork,vfork,execve -o "$BATS_TEST_TMPDIR/$1.trace" \
    dash "$REPO/test/silt-exercise.sh" "$REPO/shell/silt/api.sh" "$BATS_TEST_TMPDIR/wide.silt" "$1"
  grep -c 'clone\|fork\|execve' "$BATS_TEST_TMPDIR/$1.trace"
}

@test "no process: the verbs over 4,000 lines start nothing beyond the import" {
  command -v strace >/dev/null || skip "strace is not installed"
  wide_map 4000 > "$BATS_TEST_TMPDIR/wide.silt"
  assert_equal "$(process_starts verbs)" "$(process_starts import)"
}

@test "linear: get, len and each over 4,000 lines take under a second, under dash, bash and sh" {
  wide_map 4000 > "$BATS_TEST_TMPDIR/wide.silt"
  for shell in dash bash sh; do
    run "$shell" "$REPO/test/silt-exercise.sh" "$REPO/shell/silt/api.sh" "$BATS_TEST_TMPDIR/wide.silt" timed
    assert_success
    assert_line --index 0 '0.:str="value number 3999"'
    assert_line --index 1 4000
    [ "${lines[2]}" -lt 1000 ] || fail "under $shell the three verbs took ${lines[2]} ms"
  done
}

@test "coverage: the goldens enter every function in shell/silt and run at least 90% of its lines" {
  run bash "$REPO/test/silt-coverage.sh"
  echo "$output"
  assert_success
}
