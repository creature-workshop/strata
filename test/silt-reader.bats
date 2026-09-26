#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # bats runs each case in a subshell of its own; a variable set in one is meant to stay there
# The SILT reader (shell/silt/api.sh): a Strata document carried inline,
# read in strict POSIX shell without a process.
#
# Most cases are golden fixtures under test/fixtures/silt/, one fileset each:
# a <name>.name holding the case's name, which is the test's name in the log,
# a <name>.about explaining it in plain words, printed when the case fails, a
# <name>.calls listing verbs to run, one per line with the verb's one argument
# after it, an optional <name>.silt holding the document they run against
# (absent, the module's own <name>.fixture.silt), and a <name>.expected holding
# the transcript test/silt-transcript.sh writes: each call under a "## " line,
# its answer below it, or "!! " with the status and the message for a refusal.
# Every fixture is registered as a test of its own under bash and under dash,
# the CI image's sh, and diffs the transcripts, so a new case is a new fileset
# and no new test code; UPDATE_GOLDENS=1 rewrites the .expected files from the
# live answers under bash, to be read before they are committed. The remaining
# cases are the properties a transcript cannot carry: the jq oracle over the
# JSON twin, the answer variable's check, and the process and timing cases,
# which run test/silt-exercise.sh under strace and under the clock.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
FIXTURES="$BATS_TEST_DIRNAME/fixtures/silt"

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

# The document a golden fixture's calls run against: <name>.silt beside the
# calls, else the module's own <name>.fixture.silt, else nothing.
fixture_doc() {
  if [ -f "$FIXTURES/$1.silt" ]; then
    printf '%s' "$FIXTURES/$1.silt"
  elif [ -f "$REPO/shell/silt/$1.fixture.silt" ]; then
    printf '%s' "$REPO/shell/silt/$1.fixture.silt"
  fi
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

# One golden fixture under one shell: the transcript of its calls against its
# .expected, rewritten first when UPDATE_GOLDENS=1 and the shell is bash.
golden_case() {
  local name="$1" shell="$2" actual
  actual="$("$shell" "$REPO/test/silt-transcript.sh" "$REPO/shell/silt/api.sh" "$FIXTURES/$name.calls" "$(fixture_doc "$name")")"
  if [ "${UPDATE_GOLDENS:-}" = 1 ] && [ "$shell" = bash ]; then
    printf '%s\n' "$actual" > "$FIXTURES/$name.expected"
  fi
  if ! diff "$FIXTURES/$name.expected" - <<< "$actual"; then
    echo "## $(cat "$FIXTURES/$name.name") ($name, under $shell): the transcript differs from $name.expected"
    cat "$FIXTURES/$name.about"
    false
  fi
}

# Registers every fixture as a test under each shell, named for the case.
register_golden_cases() {
  local calls name shell
  for calls in "$FIXTURES"/*.calls; do
    name="$(basename "$calls" .calls)"
    for shell in bash dash; do
      bats_test_function --description "golden under $shell: $(cat "$FIXTURES/$name.name")" -- golden_case "$name" "$shell"
    done
  done
}

register_golden_cases

@test "the twin: string, len, keys and unwrap answer as jq does over the fixture's JSON" {
  silt__string got "$MAP" '.tests["test/a.bats"].reads[1]'
  assert_equal "$got" "$(jq -r '.tests["test/a.bats"].reads[1]' "$MAP_JSON")"
  silt__string got "$MAP" '."a \"quoted\" key: with.dots"'
  assert_equal "$got" "$(jq -r '."a \"quoted\" key: with.dots"' "$MAP_JSON")"
  silt__string got "$MAP" .text; assert_equal "$got" "$(jq -r .text "$MAP_JSON")"
  silt__string got "$MAP" .unicode; assert_equal "$got" "$(jq -r .unicode "$MAP_JSON")"
  silt__len got "$MAP"; assert_equal "$got" "$(jq length "$MAP_JSON")"
  silt__keys got "$MAP"
  assert_equal "$(list_as_json "$got" | jq -c .)" "$(jq -c keys_unsorted "$MAP_JSON")"
  silt__unwrap got '"\/\b\f"'; assert_equal "$got" "$(jq -rn '"\/\b\f"')"
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

@test "linear: get, len and each over 4,000 lines take under a second, under dash and under bash" {
  wide_map 4000 > "$BATS_TEST_TMPDIR/wide.silt"
  for shell in dash bash; do
    run "$shell" "$REPO/test/silt-exercise.sh" "$REPO/shell/silt/api.sh" "$BATS_TEST_TMPDIR/wide.silt" timed
    assert_success
    assert_line --index 0 '0.:str="value number 3999"'
    assert_line --index 1 4000
    [ "${lines[2]}" -lt 1000 ] || fail "under $shell the three verbs took ${lines[2]} ms"
  done
}
