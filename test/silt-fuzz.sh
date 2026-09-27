#!/usr/bin/env bash
# The differential fuzz of the SILT library against jq and yq, one case per
# seed: test/fuzz/value.awk draws a JSON value from the seed, yq writes it
# as YAML in block style and in flow style, test/fuzz/calls.awk draws the
# calls to run over it with the jq program each must agree with, and
# test/silt-twins.sh checks the pairs. Beside the twins, the value written
# back as JSON must be the bytes it was read from, and written as YAML must
# read through yq to the same value. A case that fails is kept under the
# work directory and named with its seed, so it reproduces and reduces to
# a golden by hand. SILT_TRANSCRIPT names the implementation under test as
# test/silt-twins.sh reads it.
#
# Usage: test/silt-fuzz.sh [--seeds <count>] [--from <seed>] [--keep <dir>]
#
#   --seeds  How many seeds to run; 20 unless given
#   --from   The first seed; 1 unless given
#   --keep   Where the failing cases are kept; a fresh directory under
#            TMPDIR unless given

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FUZZ="$REPO/test/fuzz"
TRANSCRIPT="${SILT_TRANSCRIPT:-bash $REPO/test/silt-transcript.sh $REPO/shell/silt/api.sh}"

SEEDS=20
FROM=1
KEEP=''

main() {
  parse_args "$@"
  require_oracles
  local work failed='' seed last
  work="${KEEP:-$(mktemp -d "${TMPDIR:-/tmp}/silt-fuzz.XXXXXX")}"

  last=$((FROM + SEEDS - 1))
  for ((seed = FROM; seed <= last; seed++)); do
    run_case "$seed" "$work/$seed" || failed="$failed $seed"
  done

  report "$work" "$failed"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --seeds) SEEDS="$2"; shift ;;
      --from) FROM="$2"; shift ;;
      --keep) KEEP="$2"; shift ;;
      *) printf 'silt-fuzz: unknown argument %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
  done
}

# jq and yq are the oracles; without either there is nothing to fuzz against.
require_oracles() {
  local tool
  for tool in jq yq; do
    command -v "$tool" >/dev/null || { printf 'silt-fuzz: %s is not installed\n' "$tool" >&2; exit 2; }
  done
}

# One seed: its files written under <dir>, then every check; the directory
# is removed when every check passes.
run_case() {
  local seed="$1" dir="$2" status=0
  mkdir -p "$dir"

  write_case "$seed" "$dir"
  check_twins "$dir" || status=1
  check_written "$dir" || status=1

  if [ "$status" -ne 0 ]; then
    printf 'seed %s: fails, kept under %s\n' "$seed" "$dir"
  else
    rm -rf "$dir"
  fi
  return "$status"
}

# The case's files: the value, its two YAML spellings, its paths and its
# twins. The YAML twins are left out when yq cannot read its own YAML back
# as the value, which it cannot for a string ending in a space.
write_case() {
  local seed="$1" dir="$2" root yaml=1
  awk -v seed="$seed" -f "$FUZZ/value.awk" > "$dir/value.json"
  yq -p json -o yaml . "$dir/value.json" > "$dir/block.yaml"
  yq -p json -o yaml '.. style="flow"' "$dir/value.json" > "$dir/flow.yaml"
  if ! yq_reads_back "$dir"; then
    printf 'seed %s: yq does not read its own YAML back as the value; the YAML twins are left out\n' "$seed"
    yaml=0
  fi

  jq -r -f "$FUZZ/paths.jq" "$dir/value.json" > "$dir/paths"
  root="$(jq -r type "$dir/value.json")"
  awk -v seed="$seed" -v root="$root" -v yaml="$yaml" -f "$FUZZ/calls.awk" "$dir/paths" > "$dir/value.twins"
}

# Whether yq reads both YAML spellings it wrote back as the value.
yq_reads_back() {
  local style
  for style in block flow; do
    cmp -s <(jq -S -c . "$1/value.json") <(yq -p yaml -o json -I 0 . "$1/$style.yaml" 2>/dev/null | jq -S -c .) || return 1
  done
}

# Every twin of the case, through test/silt-twins.sh.
check_twins() {
  SILT_TRANSCRIPT="$TRANSCRIPT" bash "$REPO/test/silt-twins.sh" "$1/value.twins" "$1/value.json" > "$1/twins.log" 2>&1 \
    || { cat "$1/twins.log"; return 1; }
}

# The value written back: as JSON it is the bytes it was read from, and as
# YAML it reads through yq to the same value.
check_written() {
  local dir="$1" status=0
  printf 'as d from_json %s/value.json\nto_json @d\nto_yaml @d\n' "$dir" > "$dir/written.calls"
  # shellcheck disable=SC2086  # the transcript command is words on purpose
  $TRANSCRIPT "$dir/written.calls" > "$dir/written.transcript" 2>&1

  answer_of 2 "$dir/written.transcript" > "$dir/written.json"
  answer_of 3 "$dir/written.transcript" > "$dir/written.yaml"

  cmp -s "$dir/value.json" "$dir/written.json" || { printf 'to_json is not the bytes read: %s\n' "$dir/written.json"; status=1; }
  yq -p yaml -o json -I 0 . "$dir/written.yaml" 2>/dev/null | jq -S -c . > "$dir/written.yaml.json"
  cmp -s <(jq -S -c . "$dir/value.json") "$dir/written.yaml.json" || { printf 'to_yaml does not read back through yq as the value: %s\n' "$dir/written.yaml"; status=1; }
  return "$status"
}

# The answer lines of block number <index> of a transcript.
answer_of() {
  awk -v wanted="$1" -f "$FUZZ/answer.awk" "$2"
}

# The run's outcome: every seed that failed, or a clean line.
report() {
  if [ -n "$2" ]; then
    printf 'silt-fuzz: seeds that fail:%s (kept under %s)\n' "$2" "$1" >&2
    exit 1
  fi
  printf 'silt-fuzz: %s seeds from %s agree with jq and yq\n' "$SEEDS" "$FROM"
  [ -n "$KEEP" ] || rmdir "$1" 2>/dev/null || true
}

main "$@"
