#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # bats runs each case in a subshell of its own; a variable set in one is meant to stay there
# The properties of the SILT library (shell/silt/) that neither a golden
# transcript (test/silt-goldens.bats) nor a jq twin (test/silt-twins.bats)
# can carry: the answer variable's check, the process and timing cases, which
# run test/silt-exercise.sh under strace and under the clock, the coverage
# gate, test/silt-coverage.sh, which reads bash's trace of the goldens, and
# the shape check, test/silt-shape.sh.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

setup() {
  export SILT_DIR="$REPO/shell/silt"
  # shellcheck source=../shell/silt/api.sh
  . "$REPO/shell/silt/api.sh"
  MAP="$(cat "$REPO/shell/silt/map.fixture.silt")"
  NL=$'\n'
}

# A map document of N string leaves, for the timing and the strace cases.
wide_map() {
  local i doc=''
  for ((i = 0; i < $1; i++)); do
    doc="$doc${doc:+$NL}0.\"key$i\":str=\"value number $i\""
  done
  printf '%s' "$doc"
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

# How many processes of one mode of test/silt-exercise.sh became an awk, from
# the same trace: one per process, whatever PATH entries it tried first and
# whether a wrapper handed it on to the real awk.
awk_starts() {
  awk '/execve\("[^"]*awk"/ && !seen[$1]++' "$BATS_TEST_TMPDIR/$1.trace" | wc -l
}

@test "no process: on the shell tier the verbs over 4,000 lines start nothing beyond the import" {
  command -v strace >/dev/null || skip "strace is not installed"
  wide_map 4000 > "$BATS_TEST_TMPDIR/wide.silt"
  export SILT_THRESHOLD=1000000
  assert_equal "$(process_starts verbs)" "$(process_starts import)"
}

@test "hand-off: past the threshold each walking verb starts one awk and nothing else new" {
  command -v strace >/dev/null || skip "strace is not installed"
  wide_map 4000 > "$BATS_TEST_TMPDIR/wide.silt"
  unset SILT_THRESHOLD
  process_starts verbs >/dev/null
  assert_equal "$(awk_starts verbs)" 6
}

@test "linear: get, len and each over 4,000 lines stay under three seconds, where the quadratic idioms take nine, under dash, bash and sh" {
  wide_map 4000 > "$BATS_TEST_TMPDIR/wide.silt"
  export SILT_THRESHOLD=1000000
  for shell in dash bash sh; do
    run "$shell" "$REPO/test/silt-exercise.sh" "$REPO/shell/silt/api.sh" "$BATS_TEST_TMPDIR/wide.silt" timed
    assert_success
    assert_line --index 0 '0.:str="value number 3999"'
    assert_line --index 1 4000
    [ "${lines[2]}" -lt 3000 ] || fail "under $shell the three verbs took ${lines[2]} ms; the expansion loop and \${doc#*pat} take about nine seconds here"
  done
}

@test "to_json: jq reads the map fixture's JSON back as the fixture's value" {
  silt__to_json json "$MAP"
  assert_equal "$(printf '%s' "$json" | jq -c .)" "$(jq -c . "$REPO/shell/silt/map.fixture.json")"
}

@test "coverage: the goldens enter every function in shell/silt and run at least 95% of its lines" {
  run bash "$REPO/test/silt-coverage.sh"
  echo "$output"
  assert_success
}

@test "shape: no function under shell/silt runs past 60 lines or nests past two levels" {
  run bash "$REPO/test/silt-shape.sh"
  echo "$output"
  assert_success
}
