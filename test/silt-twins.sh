#!/usr/bin/env bash
# Checks one twins file: every "<call> => <jq program>" line's SILT answer
# against jq's over the JSON twin, the calls run as one transcript so a call
# may keep a register for a later line; a line with no jq side only runs.
# Prints each pair that differs, with both answers, and fails when any does.
# A file a call reads by name, from_json, from_yaml, from_toml, from_strh or
# from_strt, is found beside the twins file. SILT_TRANSCRIPT names the command that writes a transcript for
# a calls file, test/silt-transcript.sh over shell/silt when not set, so
# another implementation runs the same twins through its own.
#
# Usage: test/silt-twins.sh <twins> <json> [<silt document>]

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRANSCRIPT="${SILT_TRANSCRIPT:-bash $REPO/test/silt-transcript.sh $REPO/shell/silt/api.sh}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

main() {
  require_usage "$@"
  local twins="$1" json="$2" document="${3:-}"

  write_calls "$twins" > "$WORK/calls"
  # shellcheck disable=SC2086  # the transcript command is words on purpose
  $TRANSCRIPT "$WORK/calls" $document > "$WORK/transcript"

  compare_pairs "$twins" "$json"
}

require_usage() {
  if [ "$#" -lt 2 ]; then
    printf 'usage: silt-twins.sh <twins> <json> [<silt document>]\n' >&2
    exit 2
  fi
}

# The calls of a twins file, each jq side taken off, and a file a call reads
# by name made absolute beside the twins file.
write_calls() {
  local dir
  dir="$(cd "$(dirname "$1")" && pwd)"
  sed -E -e 's/ => .*$//' -e "s#^((as [A-Za-z0-9_]+ )?from_(json|yaml|toml|strh|strt)( -s| --sort)?) ([^/])#\1 $dir/\5#" "$1"
}

# Every pair of the twins file against the transcript, by line.
compare_pairs() {
  local index=0 line failed=''
  while IFS= read -r line; do
    index=$((index + 1))
    case "$line" in
      *' => '*) compare_pair "$2" "$index" "${line%% => *}" "${line#* => }" || failed="$failed $index" ;;
    esac
  done < "$1"

  if [ -n "$failed" ]; then
    printf 'twins that differ, by line:%s\n' "$failed"
    return 1
  fi
}

# One pair: the transcript's answer to call number <index> against jq's.
compare_pair() {
  local json="$1" index="$2" call="$3" program="$4" ours theirs
  ours="$(answer_of "$index")"
  theirs="$(jq -r "$program" "$json")"

  if [ "$ours" != "$theirs" ]; then
    echo "## $call"
    echo "silt: $ours"
    echo "jq:   $theirs"
    return 1
  fi
}

# The answer lines of block number <index> of the transcript: what follows
# its "## " header up to the next.
answer_of() {
  awk -v wanted="$1" -f "$REPO/test/fuzz/answer.awk" "$WORK/transcript"
}

main "$@"
