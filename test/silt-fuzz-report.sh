#!/usr/bin/env bash
# Files the failing cases of a fuzz run as one Linear issue in the Fuzzer
# project of the Strata team: the title counts the seeds, the description
# links the pipeline, the job and its artifacts and then holds each failing
# case, its value and what differed, and a link card points back at the
# job. The cases are read from the directory test/silt-fuzz.sh kept them
# under, one directory per tier and one per seed inside it. With --print the
# issue is written to stdout and nothing is filed.
#
# Usage: test/silt-fuzz-report.sh <kept directory> [--print]
#
#   LINEAR_API_KEY         The key the issue is filed with
#   SILT_FUZZ_TEAM_ID      The team, Strata unless given
#   SILT_FUZZ_PROJECT_ID   The project, Fuzzer unless given
#   CI_PIPELINE_URL, CI_JOB_URL, CI_JOB_ID, CI_PROJECT_URL
#                          The run the issue points back at, when set

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FUZZ="$REPO/test/fuzz"
ENDPOINT="https://api.linear.app/graphql"
TEAM_ID="${SILT_FUZZ_TEAM_ID:-52ffd0f6-7628-45f4-9e3b-d3e97e7ca906}"
PROJECT_ID="${SILT_FUZZ_PROJECT_ID:-e244fe05-6b2d-40cf-8d88-384733e06e3b}"
FULL_CASES=10
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

# The opening words, from test/fuzz/report-intro.md, and the links back at
# the run, when CI set them.
write_run_links() {
  cat "$FUZZ/report-intro.md"
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
  printf 'Value:\n\n%sjson\n%s\n%s\n\n' "$FENCE" "$(head -c 4000 "$dir/value.json")" "$FENCE"
  if [ -s "$dir/report" ]; then
    printf 'What differed:\n\n%s\n%s\n%s\n\n' "$FENCE" "$(head -c 4000 "$dir/report")" "$FENCE"
  fi
}

# Files the issue and its link card, and prints the issue's url.
file_issue() {
  require_key
  local issue
  issue="$(create_issue)"
  printf '%s\n' "$(jq -r '.identifier + " " + .url' <<< "$issue")"
  if [ -n "${CI_JOB_URL:-}" ]; then
    attach_run "$(jq -r '.id' <<< "$issue")"
  fi
}

require_key() {
  if [ -z "${LINEAR_API_KEY:-}" ]; then
    printf 'silt-fuzz-report: LINEAR_API_KEY is not set\n' >&2
    exit 2
  fi
}

# Creates the issue from the title and the description written, and prints
# the issue object Linear answers with.
create_issue() {
  jq -n \
    --rawfile query "$FUZZ/issue-create.graphql" \
    --arg teamId "$TEAM_ID" \
    --arg projectId "$PROJECT_ID" \
    --rawfile title "$WORK/title" \
    --rawfile description "$WORK/description.md" \
    '{query: $query, variables: {teamId: $teamId, projectId: $projectId, title: ($title | rtrimstr("\n")), description: $description}}' > "$WORK/create.json"
  post "$WORK/create.json" | jq -e '.data.issueCreate | select(.success) | .issue'
}

# Puts a link card for the job on the issue.
attach_run() {
  jq -n \
    --rawfile query "$FUZZ/attachment-create.graphql" \
    --arg issueId "$1" \
    --arg title "fuzz run ${CI_JOB_ID:-}" \
    --arg url "$CI_JOB_URL" \
    --arg subtitle "the job and its artifacts" \
    '{query: $query, variables: {issueId: $issueId, title: $title, url: $url, subtitle: $subtitle}}' > "$WORK/attach.json"
  post "$WORK/attach.json" | jq -e '.data.attachmentCreate.success' > /dev/null
}

# One GraphQL request to Linear, the payload read from a file; prints the
# response and fails on a transport error or a GraphQL error.
post() {
  local response
  response="$(curl -sS --fail-with-body "$ENDPOINT" -H "Authorization: $LINEAR_API_KEY" -H 'Content-Type: application/json' --data @"$1")"
  if jq -e '.errors' <<< "$response" > /dev/null 2>&1; then
    printf 'silt-fuzz-report: Linear refused: %s\n' "$(jq -c '.errors' <<< "$response")" >&2
    return 1
  fi
  printf '%s' "$response"
}

main "$@"
