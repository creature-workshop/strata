#!/usr/bin/env bash
# The differential fuzz of the SILT library against jq and yq, one case per
# seed: fast-check draws a JSON value from the seed through
# test/fuzz/value.mjs, yq writes it as YAML in block style and in flow style
# and, for a map holding no null, as TOML, test/fuzz/calls.awk draws the
# calls to run over it with the jq program each must agree with, and
# test/silt-twins.sh checks the pairs. Beside the twins, the value written
# back as JSON must be the bytes it was read from, and written as YAML or
# TOML must read through yq to the same value; node writes the value's .strh
# and .strt through test/fuzz/store.mjs, a second opinion on the corpus
# translators, and to_strh and to_strt must give them byte for byte under
# the seeds and the index it drew. test/fuzz/schema.mjs draws schemas from
# the seed for the value, one derived from it, two that one loosened or
# broken, and two free of it, and test/silt-validate.sh holds silt__validate
# over each to shellops' jq validator, error for error. A case that fails
# is kept under the work directory and named with its seed, what differed
# in its report file, so it reproduces, reduces to a golden by hand, and
# files as an issue through test/silt-fuzz-report.sh. SILT_TRANSCRIPT names
# the implementation under test as test/silt-twins.sh reads it. Needs node
# with fast-check installed under test/fuzz (npm ci --prefix test/fuzz), jq
# and yq.
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

# jq and yq are the oracles and node with fast-check the generator; without
# any of them there is nothing to fuzz.
require_oracles() {
  local tool
  for tool in jq yq node; do
    command -v "$tool" >/dev/null || { printf 'silt-fuzz: %s is not installed\n' "$tool" >&2; exit 2; }
  done
  [ -d "$FUZZ/node_modules/fast-check" ] || { printf 'silt-fuzz: fast-check is not installed; run npm ci --prefix test/fuzz\n' >&2; exit 2; }
}

# One seed: its files written under <dir>, then every check, what they
# found written to <dir>/report; the directory is removed when every check
# passes.
run_case() {
  local seed="$1" dir="$2" status=0
  mkdir -p "$dir"

  write_case "$seed" "$dir"
  check_twins "$dir" > "$dir/report" 2>&1 || status=1
  check_written "$dir" >> "$dir/report" 2>&1 || status=1
  check_stored "$dir" >> "$dir/report" 2>&1 || status=1
  check_validated "$dir" >> "$dir/report" 2>&1 || status=1

  if [ "$status" -ne 0 ]; then
    cat "$dir/report"
    printf 'seed %s: fails, kept under %s\n' "$seed" "$dir"
  else
    rm -rf "$dir"
  fi
  return "$status"
}

# The case's files: the value, its YAML spellings, its TOML when TOML can
# hold it, its .strh and .strt with their index and the seeds they were drawn
# under, the schemas drawn for it, its paths and its twins. The YAML and the TOML twins are left out
# when yq cannot read its own spelling back as the value, which it cannot
# for a string ending in a space.
write_case() {
  local seed="$1" dir="$2" root yaml=1 toml=0
  node "$FUZZ/value.mjs" "$seed" > "$dir/value.json"
  yq -p json -o yaml . "$dir/value.json" > "$dir/block.yaml"
  yq -p json -o yaml '.. style="flow"' "$dir/value.json" > "$dir/flow.yaml"
  if ! yq_reads_back "$dir" block.yaml yaml || ! yq_reads_back "$dir" flow.yaml yaml; then
    printf 'seed %s: yq does not read its own YAML back as the value; the YAML twins are left out\n' "$seed"
    yaml=0
  fi
  if toml_holds "$dir/value.json"; then
    yq -p json -o toml . "$dir/value.json" > "$dir/table.toml" 2>/dev/null && yq_reads_back "$dir" table.toml toml && toml=1
  fi
  if [ "$toml" -eq 0 ]; then
    rm -f "$dir/table.toml"
  fi

  node "$FUZZ/store.mjs" "$seed" "$dir" > "$dir/seeds"
  node "$FUZZ/schema.mjs" "$seed" "$dir"
  jq -r -f "$FUZZ/paths.jq" "$dir/value.json" > "$dir/paths"
  root="$(jq -r type "$dir/value.json")"
  awk -v seed="$seed" -v root="$root" -v yaml="$yaml" -v toml="$toml" -f "$FUZZ/calls.awk" "$dir/paths" > "$dir/value.twins"
}

# Whether yq reads the spelling it wrote, <file> in <format>, back as the
# value.
yq_reads_back() {
  cmp -s <(jq -S -c . "$1/value.json") <(yq -p "$3" -o json -I 0 . "$1/$2" 2>/dev/null | jq -S -c .)
}

# Whether TOML can hold the value: a map, with no null anywhere in it.
toml_holds() {
  jq -e 'type == "object" and ([.. | select(. == null)] | length == 0)' "$1" >/dev/null
}

# Every twin of the case, through test/silt-twins.sh.
check_twins() {
  SILT_TRANSCRIPT="$TRANSCRIPT" bash "$REPO/test/silt-twins.sh" "$1/value.twins" "$1/value.json" > "$1/twins.log" 2>&1 \
    || { cat "$1/twins.log"; return 1; }
}

# The value written back: as JSON it is the bytes it was read from, and as
# YAML, and as TOML where TOML holds it, it reads through yq to the value.
check_written() {
  local dir="$1" status=0
  printf 'as d from_json %s/value.json\nto_json @d\nto_yaml @d\nto_toml @d\n' "$dir" > "$dir/written.calls"
  # shellcheck disable=SC2086  # the transcript command is words on purpose
  $TRANSCRIPT "$dir/written.calls" > "$dir/written.transcript" 2>&1

  answer_of 2 "$dir/written.transcript" > "$dir/written.json"
  answer_of 3 "$dir/written.transcript" > "$dir/written.yaml"
  answer_of 4 "$dir/written.transcript" > "$dir/written.toml"

  cmp -s "$dir/value.json" "$dir/written.json" || { printf 'to_json is not the bytes read: %s\n' "$dir/written.json"; status=1; }
  reads_back_as_value "$dir" written.yaml yaml || { printf 'to_yaml does not read back through yq as the value: %s\n' "$dir/written.yaml"; status=1; }
  if [ -f "$dir/table.toml" ]; then
    reads_back_as_value "$dir" written.toml toml || { printf 'to_toml does not read back through yq as the value: %s\n' "$dir/written.toml"; status=1; }
  fi
  return "$status"
}

# Whether a spelling we wrote, <file> in <format>, reads through yq as the
# value.
reads_back_as_value() {
  yq -p "$3" -o json -I 0 . "$1/$2" 2>/dev/null | jq -S -c . > "$1/$2.json"
  cmp -s <(jq -S -c . "$1/value.json") "$1/$2.json"
}

# The value written into a corpus: to_strh under the seeds node drew must be
# the .strh node wrote, and to_strt under the index it shuffled the .strt,
# byte for byte.
check_stored() {
  local dir="$1" seeds status=0
  seeds="$(cat "$dir/seeds")"
  # shellcheck disable=SC2016  # $i names the transcript's register, not a variable
  printf 'as d from_json %s/value.json\nto_strh @d %s\nas i from_json %s/index.json\nto_strt @d $i\n' "$dir" "$seeds" "$dir" > "$dir/stored.calls"
  # shellcheck disable=SC2086  # the transcript command is words on purpose
  $TRANSCRIPT "$dir/stored.calls" > "$dir/stored.transcript" 2>&1

  answer_of 2 "$dir/stored.transcript" > "$dir/stored.strh"
  answer_of 4 "$dir/stored.transcript" > "$dir/stored.strt"
  cmp -s "$dir/value.strh" "$dir/stored.strh" || { printf 'to_strh is not the .strh node drew: %s\n' "$dir/stored.strh"; status=1; }
  cmp -s "$dir/value.strt" "$dir/stored.strt" || { printf 'to_strt is not the .strt node drew: %s\n' "$dir/stored.strt"; status=1; }
  return "$status"
}

# The value against each schema drawn for it: silt__validate answers the
# errors the jq validator reports, through test/silt-validate.sh.
check_validated() {
  bash "$REPO/test/silt-validate.sh" "$1/schemas.json" > "$1/validated.log" 2>&1 \
    || { cat "$1/validated.log"; return 1; }
}

# The answer lines of block number <index> of a transcript.
answer_of() {
  awk -v wanted="$1" -f "$REPO/shell/.golden/shell/golden/answer.awk" "$2"
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
