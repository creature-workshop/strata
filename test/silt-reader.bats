#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # bats runs each case in a subshell of its own; a variable set in one is meant to stay there
# The properties of the SILT library (shell/silt/) that neither a golden
# transcript (test/silt-goldens.bats) nor a jq twin (test/silt-twins.bats)
# can carry: the answer variable's check, the process and timing cases, which
# run test/silt-exercise.sh under strace and under the clock, the coverage
# gate, test/silt-coverage.sh, which reads bash's trace of the goldens, the
# shape check, test/silt-shape.sh, the check that SILT works without
# shellops, test/silt-without-shellops.sh, and the check that it works for a
# caller with IFS unset, test/silt-unset-ifs.sh.

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

@test "from_strh: the map fixture's .strh twin reads back as the fixture" {
  silt__from_strh doc < "$BATS_TEST_DIRNAME/fixtures/silt/strh/map/map.strh"
  assert_equal "$doc" "$MAP"
}

@test "from_strt: the map fixture's .strt twin reads back as the fixture under its index" {
  silt__split index 'runner,count,ratio,clean,nothing,empty,none,tests,test/a.bats,status,reads,test/b.bats,a "quoted" key: with.dots,text,unicode' ,
  silt__from_strt doc "$index" < "$BATS_TEST_DIRNAME/fixtures/silt/strt/map/map.strt"
  assert_equal "$doc" "$MAP"
}

@test "to_strt: the map fixture under its index is its .strt twin" {
  silt__split index 'runner,count,ratio,clean,nothing,empty,none,tests,test/a.bats,status,reads,test/b.bats,a "quoted" key: with.dots,text,unicode' ,
  silt__to_strt terse "$MAP" "$index"
  assert_equal "$terse" "$(cat "$BATS_TEST_DIRNAME/fixtures/silt/strt/map/map.strt")"
}

@test "to_strh: the map fixture as document 1 under ADR.9's seeds is its .strh twin" {
  silt__to_strh stored "$MAP" 1299709 104729 1
  assert_equal "$stored" "$(cat "$BATS_TEST_DIRNAME/fixtures/silt/strh/map/map.strh")"
}

@test "to_strh: the header, document 0, draws the LIDs of ADR.9's vector" {
  silt__to_strh stored "0.0:int=1${NL}0.1:int=2${NL}0.2:int=3" 1299709 104729 0
  assert_equal "$stored" "505b3e7c79c7e1f3 0.0:int=1${NL}505b3e7c68c84c23 0.1:int=2${NL}505b3e7c7b970259 0.2:int=3"
}

# Puts a fake date command first on PATH. It appends a line to starts.log
# each time it runs, then runs the given line of shell.
stub_date() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  printf '#!/bin/sh\necho date >> "%s/starts.log"\n%s\n' "$BATS_TEST_TMPDIR" "$1" > "$BATS_TEST_TMPDIR/bin/date"
  chmod +x "$BATS_TEST_TMPDIR/bin/date"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "silt__now: runs date once, and uses nine zeros when date does not print fractional seconds" {
  stub_date "echo 2026-09-27T14:03:11.NZ"
  silt__now doc
  assert_equal "$doc" '0.:time-rfc3339-utc=2026-09-27T14:03:11.000000000Z'
  assert_equal "$(cat "$BATS_TEST_TMPDIR/starts.log")" date
}

@test "silt__now: fails with a clear message when the date command fails" {
  stub_date "exit 1"
  run silt__now doc
  assert_failure
  assert_output --partial "could not read the current time"
}

@test "silt__validate: returns the same errors as the shellops jq validator for every case, on both tiers" {
  run bash "$REPO/test/silt-validate.sh"
  echo "$output"
  assert_success
  SILT_THRESHOLD=0 run bash "$REPO/test/silt-validate.sh"
  echo "$output"
  assert_success
}

@test "SILT works without shellops: no file mentions it, and every golden test passes with it removed (ADR.33@strata)" {
  run bash "$REPO/test/silt-without-shellops.sh"
  echo "$output"
  assert_success
}

@test "SILT works for a caller with IFS unset under set -u, and leaves IFS as it found it, under sh, dash and bash" {
  local shell
  for shell in sh dash bash; do
    run "$shell" "$REPO/test/silt-unset-ifs.sh" "$REPO/shell/silt/api.sh"
    echo "$shell: $output"
    assert_success
  done
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
