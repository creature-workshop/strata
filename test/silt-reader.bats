#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # bats runs each case in a subshell of its own; a variable set in one is meant to stay there
# The SILT reader (shell/silt/api.sh): a Strata document carried inline,
# read in strict POSIX shell without a process. Every case that has a JSON
# twin checks the shell's answer against jq over that twin, the oracle while
# jq lasts; the dash cases prove the library runs on the CI image's sh; the
# strace case proves a verb starts nothing; the timing case keeps the
# quadratic idioms out.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

setup() {
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

@test "type: a map by its first key, a list by its first index, a scalar by its one line" {
  silt__type kind "$MAP"; assert_equal "$kind" map
  silt__type kind '0.0:int=1'; assert_equal "$kind" list
  silt__type kind '0.:str="x"'; assert_equal "$kind" str
  silt__type kind '0.:null'; assert_equal "$kind" null
  silt__type kind '0.:map'; assert_equal "$kind" map
}

@test "string: a str at a path unquoted, as jq -r reads it" {
  silt__string got "$MAP" .runner
  assert_equal "$got" "$(jq -r .runner "$MAP_JSON")"
  silt__string got "$MAP" '.tests."test/a.bats".status'
  assert_equal "$got" "$(jq -r '.tests."test/a.bats".status' "$MAP_JSON")"
  silt__string got "$MAP" '.tests["test/a.bats"].reads[1]'
  assert_equal "$got" "$(jq -r '.tests["test/a.bats"].reads[1]' "$MAP_JSON")"
}

@test "string: the other scalars as their spelling, null as null, a collection and an absent path as nothing" {
  silt__string got "$MAP" .count; assert_equal "$got" "$(jq -r .count "$MAP_JSON")"
  silt__string got "$MAP" .ratio; assert_equal "$got" "-1.5e3"
  silt__string got "$MAP" .clean; assert_equal "$got" true
  silt__string got "$MAP" .nothing; assert_equal "$got" null
  silt__string got "$MAP" .tests; assert_equal "$got" ""
  silt__string got "$MAP" .missing; assert_equal "$got" ""
}

@test "get: a leaf is one keyless line, a collection its members at depth 0, an empty one its line" {
  silt__get got "$MAP" .runner
  assert_equal "$got" '0.:str="bats"'
  silt__get got "$MAP" '.tests."test/a.bats".reads'
  assert_equal "$got" "0.0:str=\"lib/a.sh\"${NL}0.1:str=\"test/a.bats\""
  silt__get got "$MAP" '.tests."test/b.bats"'
  assert_equal "$got" "0.\"status\":str=\"failed\"${NL}0.\"reads\":list"
  silt__get got "$MAP" .empty; assert_equal "$got" '0.:map'
  silt__get got "$MAP" .none; assert_equal "$got" '0.:list'
  silt__get got "$MAP" .nothing; assert_equal "$got" '0.:null'
}

@test "get: the empty path is the document, and a path nothing holds is the empty string" {
  silt__get got "$MAP" ''; assert_equal "$got" "$MAP"
  silt__get got "$MAP" .; assert_equal "$got" "$MAP"
  silt__get got "$MAP" .missing; assert_equal "$got" ""
  silt__get got "$MAP" '.tests."test/c.bats"'; assert_equal "$got" ""
  silt__get got "$MAP" '.tests."test/a.bats".reads[7]'; assert_equal "$got" ""
  silt__get got "$MAP" .runner.deeper; assert_equal "$got" ""
}

@test "get: a subtree's depths are lowered so its own root is 0, and a sibling's children never leak in" {
  silt__get got "$MAP" .tests
  assert_equal "$(printf '%s\n' "$got" | head -1)" '0."test/a.bats":map'
  assert_equal "$(printf '%s\n' "$got" | wc -l)" 8
  silt__get again "$got" '."test/a.bats".reads[0]'
  assert_equal "$again" '0.:str="lib/a.sh"'
}

@test "has: true for a value held, a null included, false for a path nothing holds" {
  silt__has got "$MAP" .runner; assert_equal "$got" true
  silt__has got "$MAP" .nothing; assert_equal "$got" true
  silt__has got "$MAP" .none; assert_equal "$got" true
  silt__has got "$MAP" .missing; assert_equal "$got" false
}

@test "scalar: the value text of a scalar document, and a refusal for anything wider" {
  silt__scalar got '0.:str="bats"'; assert_equal "$got" '"bats"'
  silt__scalar got '0.:int=3'; assert_equal "$got" 3
  silt__scalar got '0.:null'; assert_equal "$got" ""
  run silt__scalar got "$MAP"
  assert_failure
  assert_output --partial "not a scalar document"
}

@test "len: members of a map or a list, characters of a str, 0 for a null, as jq length" {
  silt__len got "$MAP"; assert_equal "$got" "$(jq length "$MAP_JSON")"
  silt__get reads "$MAP" '.tests."test/a.bats".reads'
  silt__len got "$reads"; assert_equal "$got" 2
  silt__get runner "$MAP" .runner
  silt__len got "$runner"; assert_equal "$got" "$(jq '.runner | length' "$MAP_JSON")"
  silt__len got '0.:null'; assert_equal "$got" 0
  silt__len got '0.:map'; assert_equal "$got" 0
  run silt__len got '0.:bool=true'
  assert_failure
}

@test "keys: a map's as str leaves in their order, a list's as int leaves, as jq keys_unsorted" {
  silt__keys got "$MAP"
  assert_equal "$(list_as_json "$got" | jq -c .)" "$(jq -c keys_unsorted "$MAP_JSON")"
  silt__get reads "$MAP" '.tests."test/a.bats".reads'
  silt__keys got "$reads"
  assert_equal "$(list_as_json "$got" | jq -c .)" '[0,1]'
  silt__keys got '0.:map'; assert_equal "$got" '0.:list'
  run silt__keys got '0.:int=1'
  assert_failure
}

@test "each: the callback sees every member's key as text and its value as a document, in order" {
  seen=''
  note() { seen="$seen$1=$2;"; }
  silt__get tests "$MAP" .tests
  silt__each note "$tests"
  assert_equal "$seen" "test/a.bats=0.\"status\":str=\"passed\"${NL}0.\"reads\":list${NL}1.0:str=\"lib/a.sh\"${NL}1.1:str=\"test/a.bats\";test/b.bats=0.\"status\":str=\"failed\"${NL}0.\"reads\":list;"
  count=0
  tally() { count=$((count + 1)); }
  silt__each tally "$MAP"
  assert_equal "$count" "$(jq length "$MAP_JSON")"
}

@test "each: extra arguments reach the callback, and a callback's non-zero status stops the walk with it" {
  keys=''
  first_two() { keys="$keys$1,"; [ "$3" = tag ] || return 9; [ "$1" = count ] && return 3; return 0; }
  run silt__each first_two "$MAP" tag
  assert_equal "$status" 3
  silt__each first_two "$MAP" tag || true
  assert_equal "$keys" "runner,count,"
}

@test "each: a list's keys are its indices" {
  seen=''
  note() { seen="$seen$1:$2 "; }
  silt__get reads "$MAP" '.tests."test/a.bats".reads'
  silt__each note "$reads"
  assert_equal "$seen" '0:0.:str="lib/a.sh" 1:0.:str="test/a.bats" '
}

@test "a quoted key carries every mark a line is split on, and a quoted path segment reaches it" {
  silt__string got "$MAP" '."a \"quoted\" key: with.dots"'
  assert_equal "$got" "$(jq -r '."a \"quoted\" key: with.dots"' "$MAP_JSON")"
  silt__keys keys "$MAP"
  assert_equal "$(list_as_json "$keys" | jq -r '.[8]')" 'a "quoted" key: with.dots'
}

@test "unwrap: every JSON escape, a surrogate pair included, decodes as jq -r does" {
  silt__get text "$MAP" .text
  silt__scalar literal "$text"
  silt__unwrap got "$literal"
  assert_equal "$got" "$(jq -r .text "$MAP_JSON")"
  silt__get unicode "$MAP" .unicode
  silt__scalar literal "$unicode"
  silt__unwrap got "$literal"
  assert_equal "$got" "$(jq -r .unicode "$MAP_JSON")"
  silt__unwrap got '"\/\b\f"'
  assert_equal "$got" "$(jq -rn '"\/\b\f"')"
}

@test "unwrap: refuses what is not a string literal or holds an escape JSON lacks" {
  run silt__unwrap got 'bats'
  assert_failure
  assert_output --partial "not a string literal"
  run silt__unwrap got '"a\qb"'
  assert_failure
  assert_output --partial "not a JSON escape"
}

@test "wrap: the literal jq writes for the same text, control characters included" {
  text="a \"quote\", a \\ backslash,${NL}a line$(printf '\t')and a tab, $(printf '\r\b\f') and $(printf '\001')"
  silt__wrap got "$text"
  assert_equal "$got" "$(jq -cn --arg t "$text" '$t')"
  silt__wrap got 'plain'
  assert_equal "$got" '"plain"'
  silt__wrap got ''
  assert_equal "$got" '""'
}

@test "wrap and unwrap: a round trip is the identity on text, and on a literal jq accepts" {
  text="café 😀 with \"quotes\" and \\ and${NL}lines"
  silt__wrap literal "$text"
  silt__unwrap back "$literal"
  assert_equal "$back" "$text"
  assert_equal "$(jq -r . <<< "$literal")" "$text"
}

@test "the answer variable is checked before anything is evaluated through it" {
  run silt__get 'x; touch /tmp/silt-pwned' "$MAP" .runner
  assert_failure
  assert_output --partial "not a variable name"
  run silt__type '1abc' "$MAP"
  assert_failure
}

@test "a line without a depth, or a quoted key that never closes, is refused by name" {
  run silt__get got 'not a line' .a
  assert_failure
  assert_output --partial "not a SILT line"
  run silt__get got '0."open:str="x"' .open
  assert_failure
  assert_output --partial "never closes"
}

@test "dash: the reader runs on the CI image's sh and answers as under bash" {
  # shellcheck disable=SC2016  # the program is dash's to expand, not this shell's
  run dash -c '. "$1/shell/silt/api.sh"; doc="$(cat "$1/shell/silt/map.fixture.silt")"; silt__string r "$doc" ".tests[\"test/a.bats\"].reads[1]"; silt__len n "$doc"; silt__keys k "$doc"; printf "%s|%s|%s\n" "$r" "$n" "$(printf "%s" "$k" | wc -l)"' dash "$REPO"
  assert_success
  assert_output "test/a.bats|$(jq length "$MAP_JSON")|$(( $(jq length "$MAP_JSON") - 1 ))"
}

@test "dash: unwrap and wrap agree with jq there too" {
  # shellcheck disable=SC2016  # the program is dash's to expand, not this shell's
  run dash -c '. "$1/shell/silt/api.sh"; silt__unwrap t "$2"; silt__wrap w "$t"; printf "%s\n%s\n" "$t" "$w"' dash "$REPO" "$(jq -c .unicode "$MAP_JSON")"
  assert_success
  assert_line --index 0 "$(jq -r .unicode "$MAP_JSON")"
  assert_equal "$(jq -r . <<< "${lines[1]}")" "$(jq -r .unicode "$MAP_JSON")"
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
