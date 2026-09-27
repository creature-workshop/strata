#!/usr/bin/env bash
# shellcheck disable=SC2119  # bare @obj is the structs empty constructor
# Files the failing cases of a fuzz run as one Linear issue in the Fuzzer
# project of the Strata team, through shellops' Linear client: the title
# counts the seeds, the description links the pipeline, the job and its
# artifacts and then holds each failing case, its value and what differed,
# and a link card points back at the job. The cases are read from the
# directory test/silt-fuzz.sh kept them under, one directory per tier and
# one per seed inside it. With --print the issue is written to stdout and
# nothing is filed.
#
# Usage: test/silt-fuzz-report.sh <kept directory> [--print]
#
#   SHELLOPS_DIR, PROJ     Where shellops is and the repository root, as
#                          every shellops caller sets them; the vendored
#                          shell/.ops and this repository unless given
#   LINEAR_API_KEY         The key the issue is filed with
#   SILT_FUZZ_TEAM_ID      The team, Strata unless given
#   SILT_FUZZ_PROJECT_ID   The project, Fuzzer unless given
#   CI_PIPELINE_URL, CI_JOB_URL, CI_JOB_ID
#                          The run the issue points back at, when set

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SHELLOPS_DIR="${SHELLOPS_DIR:-$REPO/shell/.ops}"
export PROJ="${PROJ:-$REPO}"
. "$SHELLOPS_DIR/.envrc"
import "$SHELLOPS_DIR/lib/linear/api.sh"

FUZZ="$REPO/test/fuzz"
ENDPOINT="https://api.linear.app/graphql"
TEAM_ID="${SILT_FUZZ_TEAM_ID:-52ffd0f6-7628-45f4-9e3b-d3e97e7ca906}"
PROJECT_ID="${SILT_FUZZ_PROJECT_ID:-e244fe05-6b2d-40cf-8d88-384733e06e3b}"
FULL_CASES=10
CASE_CHARS=2000
FENCE='```'
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

main() {
  require_usage "$@"
  local kept="$1" mode="${2:-}"

  list_cases "$kept" > "$WORK/cases"
  require_cases
  write_title > "$WORK/title"
  write_description "$kept" > "$WORK/description.md"

  if [ "$mode" = --print ]; then
    cat "$WORK/title" "$WORK/description.md"
    return
  fi

  file_issue
}

require_usage() {
  if [ "$#" -lt 1 ] || [ ! -d "$1" ]; then
    printf 'usage: silt-fuzz-report.sh <kept directory> [--print]\n' >&2
    exit 2
  fi
}

# Every failing case under the kept directory, one "<tier> <seed>" per line,
# tiers and seeds in order.
list_cases() {
  local tier seed
  for tier in "$1"/*/; do
    [ -d "$tier" ] || continue
    for seed in "$tier"*/; do
      [ -f "$seed/value.json" ] || continue
      printf '%s %s\n' "$(basename "$tier")" "$(basename "$seed")"
    done
  done
}

require_cases() {
  if [ ! -s "$WORK/cases" ]; then
    printf 'silt-fuzz-report: no failing case under the directory; nothing to file\n' >&2
    exit 0
  fi
}

# The issue's title: how many seeds failed, on which tiers, on which day.
write_title() {
  local count tiers
  count="$(wc -l < "$WORK/cases")"
  tiers="$(cut -d' ' -f1 "$WORK/cases" | sort -u | paste -sd' ' -)"
  # shellcheck disable=SC2086  # the tiers are words on purpose
  printf 'fuzz: %s failing seed%s on the %s, %s\n' "$count" "$(plural "$count")" "$(tiers_phrase $tiers)" "$(date -u +%Y-%m-%d)"
}

plural() {
  [ "$1" -eq 1 ] || printf 's'
}

# "shell tier", or "awk and shell tiers".
tiers_phrase() {
  if [ "$#" -eq 1 ]; then
    printf '%s tier' "$1"
  else
    printf '%s and %s tiers' "$1" "$2"
  fi
}

# The issue's body: where the run is, then each failing case, the first
# FULL_CASES in full and the rest by seed alone.
write_description() {
  local kept="$1" index=0 tier seed
  write_run_links
  while read -r tier seed; do
    index=$((index + 1))
    if [ "$index" -le "$FULL_CASES" ]; then
      write_case "$kept/$tier/$seed" "$tier" "$seed"
    else
      printf -- '- seed %s on the %s tier\n' "$seed" "$tier"
    fi
  done < "$WORK/cases"
}

# The opening words, how a case reproduces and where it reduces to, and
# the links back at the run, when CI set them.
write_run_links() {
  # shellcheck disable=SC2016  # the backticks are the issue's markdown
  printf '%s\n' \
    'Filed by the nightly fuzz, `test/silt-fuzz.sh`, from the run below.' \
    'Each case reproduces with `bash test/silt-fuzz.sh --seeds 1 --from <seed>` on its tier (`SILT_THRESHOLD=0` for awk).' \
    'A twin reduces by hand into a golden fileset, `test/fixtures/silt/<name>/`, and a schema, kept in the seed'"'"'s `schemas.json`, into a case of `test/fixtures/silt/validate/cases/cases.json`.'
  if [ -n "${CI_PIPELINE_URL:-}" ]; then
    printf -- '- Pipeline: %s\n' "$CI_PIPELINE_URL"
  fi
  if [ -n "${CI_JOB_URL:-}" ]; then
    printf -- '- Job: %s\n- Artifacts: %s/artifacts/browse\n' "$CI_JOB_URL" "$CI_JOB_URL"
  fi
  printf '\n'
}

# One failing case: its seed and tier, its value, and what differed.
write_case() {
  local dir="$1" tier="$2" seed="$3"
  printf '## seed %s, %s tier\n\n' "$seed" "$tier"
  printf 'Value:\n\n%sjson\n%s\n%s\n\n' "$FENCE" "$(head -c "$CASE_CHARS" "$dir/value.json")" "$FENCE"
  if [ -s "$dir/report" ]; then
    printf 'What differed:\n\n%s\n%s\n%s\n\n' "$FENCE" "$(head -c "$CASE_CHARS" "$dir/report")" "$FENCE"
  fi
}

# Files the issue and its link card, and prints the issue's identifier and
# url.
file_issue() {
  require_key
  local issue
  issue="$(create_issue)"
  printf '%s %s\n' "$(@get "$issue" '.identifier')" "$(@get "$issue" '.url')"
  if [ -n "${CI_JOB_URL:-}" ]; then
    attach_run "$(@get "$issue" '.id')"
  fi
}

require_key() {
  if [ -z "${LINEAR_API_KEY:-}" ]; then
    printf 'silt-fuzz-report: LINEAR_API_KEY is not set\n' >&2
    exit 2
  fi
}

# Creates the issue inside the project from the title and the description
# written, through shellops' GraphQL client and the mutation beside this
# script, since the client's own issue-create names no project. Prints the
# issue object Linear answers with.
create_issue() {
  local variables data
  variables="$(@obj \
    '.teamId' "$TEAM_ID" \
    '.projectId' "$PROJECT_ID" \
    '.title' "$(cat "$WORK/title")" \
    '.description' "$(cat "$WORK/description.md")"
  )"
  data="$(graphql__request "$ENDPOINT" "$(@obj '.auth' "$LINEAR_API_KEY")" "$(cat "$FUZZ/issue-create.graphql")" "$variables")"
  @get "$data" '.issueCreate.issue'
}

# Puts a link card for the job on the issue, through shellops' Linear
# client.
attach_run() {
  local attachment options
  attachment="$(@set "$(linear__new_attachment)" \
    '.title' "fuzz run ${CI_JOB_ID:-}" \
    '.url' "$CI_JOB_URL" \
    '.subtitle' "the job and its artifacts"
  )"
  options="$(@set "$(linear__new_linear_options)" '.token' "$LINEAR_API_KEY")"
  linear__add_attachment "$1" "$attachment" "$options"
}

main "$@"
