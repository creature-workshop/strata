#!/usr/bin/env bats
# The twins: a SILT call and a jq program that must answer the same text over
# the same value, one pair per line of a <name>.twins file under
# test/fixtures/silt, written "<call> => <jq program>". The calls run through
# test/silt-transcript.sh in one transcript, so a call may keep a register for
# a later line; a line with no jq side only runs. The jq side reads the JSON
# twin, shell/silt/<name>.fixture.json, and may start with null to ignore it.
# One test per twins file, named for it; a mismatch prints both answers.

bats_require_minimum_version 1.5.0

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
FIXTURES="$BATS_TEST_DIRNAME/fixtures/silt"

load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-support/load.bash"
load "${SHELLOPS_DIR:-$REPO/shell/.ops}/test/lib/bats-assert/load.bash"

# Registers one test per twins file.
register_twin_cases() {
  local twins name
  for twins in "$FIXTURES"/*.twins; do
    name="$(basename "$twins" .twins)"
    bats_test_function --description "twins: every $name call answers as its jq program does" -- twin_case "$name"
  done
}

# One twins file: the calls' transcript against jq, pair by pair.
twin_case() {
  local name="$1" calls="$BATS_TEST_TMPDIR/$1.calls" failed=''
  sed 's/ => .*$//' "$FIXTURES/$name.twins" > "$calls"
  bash "$REPO/test/silt-transcript.sh" "$REPO/shell/silt/api.sh" "$calls" "$REPO/shell/silt/$name.fixture.silt" > "$BATS_TEST_TMPDIR/$name.transcript"

  local index=0 line
  while IFS= read -r line; do
    index=$((index + 1))
    case "$line" in
      *' => '*) compare_pair "$name" "$index" "${line%% => *}" "${line#* => }" || failed="$failed $index" ;;
    esac
  done < "$FIXTURES/$name.twins"

  [ -z "$failed" ] || fail "twins that differ, by line:$failed"
}

# One pair: the transcript's answer to call number <index> against jq's.
compare_pair() {
  local name="$1" index="$2" call="$3" program="$4" ours theirs
  ours="$(answer_of "$BATS_TEST_TMPDIR/$name.transcript" "$index")"
  theirs="$(jq -r "$program" "$REPO/shell/silt/$name.fixture.json")"

  if [ "$ours" != "$theirs" ]; then
    echo "## $call"
    echo "silt: $ours"
    echo "jq:   $theirs"
    return 1
  fi
}

# The answer lines of block number <index> of a transcript: what follows its
# "## " header up to the next.
answer_of() {
  awk -v wanted="$2" '
    /^## / { block++; next }
    block == wanted { print }
  ' "$1"
}

register_twin_cases
