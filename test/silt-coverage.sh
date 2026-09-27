#!/usr/bin/env bash
# Measures how much of shell/silt the golden fixtures and the exercise script
# run, on the shell tier and with every walk handed to awk, and fails when
# either share is under its bar; there is no warning band. bash traces every command it runs with the file, the line and the
# function it sits in, so the goldens run once more under the trace and the
# trace is the coverage: which functions were entered, and which lines of
# each file were executed.
#
# Usage: test/silt-coverage.sh [--functions <percent>] [--lines <percent>]
#
#   --functions  The share of functions that must be entered; 100 unless given
#   --lines      The share of executable lines that must run; 95 unless given
#
# An executable line is one inside a function body that is not blank, not a
# comment, and not syntax alone (fi, esac, done, else, then, do, a closing
# brace, or a case arm with nothing to run).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIBRARY="$REPO/shell/silt"
FIXTURES="$REPO/test/fixtures/silt"
TRACE="$(mktemp)"
trap 'rm -f "$TRACE" "$TRACE.raw" "$TRACE.executable"' EXIT

FUNCTIONS_BAR=100
LINES_BAR=95

main() {
  parse_args "$@"

  trace_goldens
  trace_exercise

  report_functions
  report_lines
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --functions) FUNCTIONS_BAR="$2"; shift ;;
      --lines) LINES_BAR="$2"; shift ;;
      *) printf 'silt-coverage: unknown argument %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
  done
}

# Runs every golden fileset's transcript under bash -x, appending the trace,
# once on the shell tier and once with every walk handed to the awk tier.
trace_goldens() {
  local calls name
  for calls in "$FIXTURES"/*/calls.txt; do
    name="$(basename "$(dirname "$calls")")"
    traced "$REPO/test/silt-transcript.sh" "$LIBRARY/api.sh" "$calls" "$(document_of "$name")"
    SILT_THRESHOLD=0 traced "$REPO/test/silt-transcript.sh" "$LIBRARY/api.sh" "$calls" "$(document_of "$name")"
  done
}

# Runs the exercise script's verbs over a small document under bash -x.
trace_exercise() {
  local doc="$TRACE.doc"
  printf '0."key%d":str="value"\n' 0 1 2 3 > "$doc"
  traced "$REPO/test/silt-exercise.sh" "$LIBRARY/api.sh" "$doc" verbs
  rm -f "$doc"
}

# Runs a script under test/silt-trace.bash, which puts bash's trace on a
# descriptor of its own so a redirection of stderr inside the script cannot
# swallow it, and keeps the trace lines from the library, each as
# file:line:function.
traced() {
  bash "$REPO/test/silt-trace.bash" "$@" 9>>"$TRACE.raw" >/dev/null 2>&1 || true
  awk -v library="$LIBRARY/" 'sub(/^\++cov /, "") && index($1, library) == 1 { print $1 }' "$TRACE.raw" >> "$TRACE"
  : > "$TRACE.raw"
}

# The document a fileset's calls run against, or nothing.
document_of() {
  if [ -f "$FIXTURES/$1/document.silt" ]; then
    printf '%s' "$FIXTURES/$1/document.silt"
  elif [ -f "$LIBRARY/$1.fixture.silt" ]; then
    printf '%s' "$LIBRARY/$1.fixture.silt"
  fi
}

# Every function the library defines against every function the trace entered.
report_functions() {
  local defined entered missing total percent
  defined="$(grep -h '^[a-z_]*() {' "$LIBRARY"/*.sh | sed 's/() {//' | sort -u)"
  entered="$(cut -d: -f3 "$TRACE" | grep -v '^source$' | sort -u)"
  missing="$(comm -23 <(printf '%s\n' "$defined") <(printf '%s\n' "$entered"))"
  total="$(printf '%s\n' "$defined" | wc -l)"
  percent="$(percent_of "$((total - $(count_lines "$missing")))" "$total")"

  printf 'functions: %s of %s entered, %s%% (bar %s%%)\n' "$((total - $(count_lines "$missing")))" "$total" "$percent" "$FUNCTIONS_BAR"
  if [ -n "$missing" ]; then
    printf '%s\n' "$missing" | sed 's/^/  never entered: /'
  fi
  [ "$percent" -ge "$FUNCTIONS_BAR" ] || fail "function coverage is under the bar"
}

# Executed lines against executable lines, per file and in total.
report_lines() {
  local file executable executed total_executable=0 total_executed=0 percent
  for file in "$LIBRARY"/*.sh; do
    executable_lines "$file"
    executable="$(wc -l < "$TRACE.executable")"
    executed="$(executed_lines "$file")"
    total_executable=$((total_executable + executable))
    total_executed=$((total_executed + executed))
    printf '  %-14s %3s of %3s lines, %3s%%\n' "$(basename "$file")" "$executed" "$executable" "$(percent_of "$executed" "$executable")"
  done

  percent="$(percent_of "$total_executed" "$total_executable")"
  printf 'lines: %s of %s executed, %s%% (bar %s%%)\n' "$total_executed" "$total_executable" "$percent" "$LINES_BAR"
  [ "$percent" -ge "$LINES_BAR" ] || fail "line coverage is under the bar"
}

# Writes the numbers of a file's executable lines, one per line, to the
# scratch file the line count reads.
executable_lines() {
  awk '
    /^[a-z_]+\(\) \{/ { in_function = 1; next }
    in_function && /^\}/ { in_function = 0; next }
    !in_function { next }
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*(fi|esac|done|else|then|do|\}|;;)[[:space:]]*$/ { next }
    /^[[:space:]]*[^)]*\)[[:space:]]*;;[[:space:]]*$/ { next }
    /^[[:space:]]*[^)]*\)[[:space:]]*$/ { next }
    { print NR }
  ' "$1" > "$TRACE.executable"
}

# How many of a file's executable lines the trace reached.
executed_lines() {
  local reached
  reached="$(grep "^$1:" "$TRACE" | cut -d: -f2 | sort -u)"
  comm -12 <(sort "$TRACE.executable") <(printf '%s\n' "$reached") | count_lines_of_stdin
}

percent_of() {
  if [ "$2" -eq 0 ]; then printf '100'; else printf '%s' "$(( $1 * 100 / $2 ))"; fi
}

count_lines() {
  if [ -z "$1" ]; then printf '0'; else printf '%s\n' "$1" | wc -l; fi
}

count_lines_of_stdin() {
  grep -c . || true
}

fail() {
  printf 'silt-coverage: %s\n' "$1" >&2
  exit 1
}

main "$@"
