#!/usr/bin/env bash
# Compares silt__validate with the shellops jq validator
# (lib/structs/jsonschema.jq), which defines the behaviour silt__validate
# must match.
#
# The cases file is a JSON list of {name, schema, value}. For every case,
# both validators must report the same errors in the same order. The script
# prints each case where they differ, with both results, and exits non-zero
# if there are any.
#
# SHELLOPS_DIR sets which shellops checkout provides the jq validator. The
# default is the vendored submodule.
#
# Usage: test/silt-validate.sh [<cases file>]
#
# The default cases file is test/fixtures/silt/validate/cases/cases.json.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STRUCTS="${SHELLOPS_DIR:-$REPO/shell/.ops}/lib/structs"
CASES="${1:-$REPO/test/fixtures/silt/validate/cases/cases.json}"

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

# Exits with a usage error if the jq validator cannot be found.
require_oracle() {
  if [ ! -f "$STRUCTS/jsonschema.jq" ]; then
    printf 'silt-validate: no validator at %s; set SHELLOPS_DIR or run git submodule update --init\n' "$STRUCTS/jsonschema.jq" >&2
    exit 2
  fi
}

# Runs one case through both validators and compares the results.
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

# Prints the errors from silt__validate, one per line. If silt__validate
# fails, prints its error message instead.
errors_of_silt() {
  local schema value errors text=''
  silt__from_json schema <<< "$1" || return 1
  silt__from_json value <<< "$2" || return 1
  silt__validate errors "$value" "$schema" 2>&1 || return 1
  silt__join text "$errors" "$__silt__NL" || return 1
  printf '%s' "$text"
}

# Prints the errors from the jq validator, one per line. The value is
# passed both on stdin and as $data, because different versions of the
# validator read it from different places.
errors_of_jq() {
  printf '%s' "$2" \
    | jq \
      -L "$STRUCTS/jq" \
      -f "$STRUCTS/jsonschema.jq" \
      --argjson schema "$1" \
      --argjson data "$2" \
      2>&1
}

# Prints the result and exits non-zero if any case differed.
report() {
  if [ -n "$2" ]; then
    printf 'silt-validate: FAILED. These cases (by index) differ from the jq validator:%s\n' "$2" >&2
    exit 1
  fi
  printf 'silt-validate: passed. All %s cases match the jq validator.\n' "$1"
}

main "$@"
