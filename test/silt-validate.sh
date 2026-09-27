#!/usr/bin/env bash
# Holds silt__validate to shellops' validator, lib/structs/jsonschema.jq,
# which is the contract it matches: over every case of a cases file, a JSON
# list of {name, schema, value}, the errors silt__validate answers must be
# the lines the jq validator reports, in its order. Prints each case that
# differs, with both answers, and fails when any does. SHELLOPS_DIR names
# the shellops whose validator is the oracle, the vendored one when not set.
#
# Usage: test/silt-validate.sh [<cases>]; test/fixtures/silt/validate/cases.json
# when none is given

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STRUCTS="${SHELLOPS_DIR:-$REPO/shell/.ops}/lib/structs"
CASES="${1:-$REPO/test/fixtures/silt/validate/cases.json}"

export SILT_DIR="$REPO/shell/silt"
# shellcheck source=../shell/silt/api.sh
. "$SILT_DIR/api.sh"

main() {
  require_oracle
  local count index failed=''
  count="$(jq length "$CASES")"

  for ((index = 0; index < count; index++)); do
    check_case "$index" || failed="$failed $index"
  done

  report "$count" "$failed"
}

# The jq validator has to be where SHELLOPS_DIR or the submodule puts it.
require_oracle() {
  if [ ! -f "$STRUCTS/jsonschema.jq" ]; then
    printf 'silt-validate: no validator at %s; set SHELLOPS_DIR or run git submodule update --init\n' "$STRUCTS/jsonschema.jq" >&2
    exit 2
  fi
}

# One case: both validators' errors over its schema and its value.
check_case() {
  local schema value ours theirs
  schema="$(jq -c ".[$1].schema" "$CASES")"
  value="$(jq -c ".[$1].value" "$CASES")"
  ours="$(errors_of_silt "$schema" "$value")"
  theirs="$(errors_of_jq "$schema" "$value")"

  if [ "$ours" != "$theirs" ]; then
    printf '## %s\nschema: %s\nvalue:  %s\nsilt:\n%s\njq:\n%s\n' "$(jq -r ".[$1].name" "$CASES")" "$schema" "$value" "$ours" "$theirs"
    return 1
  fi
}

# The errors silt__validate answers, one per line, or its refusal.
errors_of_silt() {
  local schema value errors text=''
  silt__from_json schema <<< "$1" || return 1
  silt__from_json value <<< "$2" || return 1
  silt__validate errors "$value" "$schema" 2>&1 || return 1
  silt__join text "$errors" "$__silt__NL" || return 1
  printf '%s' "$text"
}

# The errors the jq validator reports, one per line. The value goes in on
# stdin and as $data, since a validator reads it from one or the other.
errors_of_jq() {
  printf '%s' "$2" \
    | jq \
      -L "$STRUCTS/jq" \
      -f "$STRUCTS/jsonschema.jq" \
      --argjson schema "$1" \
      --argjson data "$2" \
      2>&1
}

# The verdict: how many cases agreed, or which differed.
report() {
  if [ -n "$2" ]; then
    printf 'silt-validate: cases that differ from the jq validator, by index:%s\n' "$2" >&2
    exit 1
  fi
  printf 'validate: %s cases answer as the jq validator does\n' "$1"
}

main "$@"
