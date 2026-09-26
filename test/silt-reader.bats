#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # bats runs each case in a subshell of its own; a variable set in one is meant to stay there
# The SILT reader (shell/silt/api.sh): a Strata document carried inline,
# read in strict POSIX shell without a process.
#
# Most cases are golden fixtures under test/fixtures/silt/: a <name>.calls
# listing verbs to run, one per line with the verb's one argument after it, an
# optional <name>.silt holding the document they run against (absent, the
# module's own <name>.fixture.silt), and a <name>.expected holding the
# transcript test/silt-transcript.sh writes: each call under a "## " line, its
# answer below it, or "!! " with the status and the message for a refusal. The
# first case runs every fixture under bash and under dash, the CI image's sh,
# and diffs the transcripts, so a new case is one more line in a .calls file
# and its block in .expected; UPDATE_GOLDENS=1 rewrites the .expected files
# from the live answers under bash, to be read before they are committed. The
# remaining cases are the properties a transcript cannot carry: the jq oracle
# over the JSON twin, the answer variable's check, strace and time.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
FIXTURES="$BATS_TEST_DIRNAME/fixtures/silt"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

setup() {
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

@test "every golden fixture: the transcript of its calls matches, under bash and under dash" {
  failed=''
  for calls in "$FIXTURES"/*.calls; do
    name="$(basename "$calls" .calls)"
    for shell in bash dash; do
      actual="$("$shell" "$REPO/test/silt-transcript.sh" "$REPO/shell/silt/api.sh" "$calls" "$(fixture_doc "$name")")"
      if [ "${UPDATE_GOLDENS:-}" = 1 ] && [ "$shell" = bash ]; then
        printf '%s\n' "$actual" > "$FIXTURES/$name.expected"
      fi
      if ! diff "$FIXTURES/$name.expected" - <<< "$actual"; then
        echo "## transcript mismatch for fixture: $name under $shell"
        failed="$failed $name@$shell"
      fi
    done
  done
  [ -z "$failed" ] || fail "mismatched fixtures:$failed"
}

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

@test "no process: a type, a get, a string, a has, a len, a keys and an each over 4,000 lines start nothing beyond the import" {
  command -v strace >/dev/null || skip "strace is not installed"
  doc="$(wide_map 4000)"
  printf '%s' "$doc" > "$BATS_TEST_TMPDIR/wide.silt"
  # shellcheck disable=SC2016  # the programs are dash's to expand, not this shell's
  import_only='. "$1/shell/silt/api.sh"; d="$(cat "$2")"'
  # shellcheck disable=SC2016
  verbs='. "$1/shell/silt/api.sh"; d="$(cat "$2")"; silt__type t "$d"; silt__get g "$d" ".key3999"; silt__string s "$d" ".key7"; silt__has h "$d" ".key1"; silt__len n "$d"; silt__keys k "$d"; cb() { :; }; silt__each cb "$d" extra'
  strace -f -qq -e trace=clone,clone3,fork,vfork,execve -o "$BATS_TEST_TMPDIR/import.trace" dash -c "$import_only" dash "$REPO" "$BATS_TEST_TMPDIR/wide.silt"
  strace -f -qq -e trace=clone,clone3,fork,vfork,execve -o "$BATS_TEST_TMPDIR/verbs.trace" dash -c "$verbs" dash "$REPO" "$BATS_TEST_TMPDIR/wide.silt"
  # The import pays for the four control-character constants and both runs
  # for the cat; the verbs add nothing.
  assert_equal "$(grep -c 'clone\|fork\|execve' "$BATS_TEST_TMPDIR/verbs.trace")" "$(grep -c 'clone\|fork\|execve' "$BATS_TEST_TMPDIR/import.trace")"
}

@test "linear: a get, a len and an each over 4,000 lines stay far under what the quadratic idioms cost, under dash and bash alike" {
  doc="$(wide_map 4000)"
  printf '%s' "$doc" > "$BATS_TEST_TMPDIR/wide.silt"
  # Outside bats's own process, whose DEBUG trap prices every command.
  # shellcheck disable=SC2016  # the program is each shell's to expand, not this one's
  timed='. "$1/shell/silt/api.sh"; d="$(cat "$2")"; s=$(date +%s%N); silt__get g "$d" .key3999; silt__len n "$d"; cb() { :; }; silt__each cb "$d"; e=$(date +%s%N); printf "%s|%s|%s\n" "$g" "$n" $(( (e - s) / 1000000 ))'
  for shell in dash bash; do
    run "$shell" -c "$timed" "$shell" "$REPO" "$BATS_TEST_TMPDIR/wide.silt"
    assert_success
    IFS='|' read -r got n elapsed_ms <<< "$output"
    assert_equal "$got" '0.:str="value number 3999"'
    assert_equal "$n" 4000
    [ "$elapsed_ms" -lt 1000 ] || fail "under $shell three verbs over 4,000 lines took ${elapsed_ms} ms; the expansion loop and \${doc#*pat} take seconds here"
  done
}
