#!/bin/sh
# Exercises the reader over one document, for the process and timing cases in
# test/silt-reader.bats, under whatever shell runs it.
#
# Usage: <shell> test/silt-exercise.sh <api.sh> <document> import|verbs|timed
#
#   import  sources the library and reads the document, nothing more
#   verbs   runs type, get, string, has, len, keys and each over it
#   timed   runs get, len and each, then prints the get's answer, the len and
#           the milliseconds the three took, one per line

set -u

main() {
  require_usage "$@"
  load_library "$1"
  DOC="$(cat "$2")"
  case "$3" in
    import) ;;
    verbs) run_verbs ;;
    timed) run_timed ;;
    *)
      printf 'silt-exercise: %s is not a mode\n' "$3" >&2
      exit 2
      ;;
  esac
}

# The library, the document and the mode are all required.
require_usage() {
  if [ "$#" -ne 3 ]; then
    printf 'usage: silt-exercise.sh <api.sh> <document> import|verbs|timed\n' >&2
    exit 2
  fi
}

# Sources the reader, telling it where it lives for the shells that cannot tell.
load_library() {
  export SILT_DIR="${1%/*}"
  . "$1"
}

# The callback each gets: it does nothing.
nothing() {
  :
}

# Every reader verb once, over the document.
run_verbs() {
  silt__type t "$DOC"
  silt__get g "$DOC" .key3999
  silt__string s "$DOC" .key7
  silt__has h "$DOC" .key1
  silt__len n "$DOC"
  silt__keys k "$DOC"
  silt__each nothing "$DOC" extra
}

# get, len and each over the document, timed with date, which is outside the
# measured span.
run_timed() {
  __run_timed__started="$(date +%s%N)"
  silt__get g "$DOC" .key3999
  silt__len n "$DOC"
  silt__each nothing "$DOC"
  __run_timed__ended="$(date +%s%N)"
  printf '%s\n%s\n%s\n' "$g" "$n" $(( (__run_timed__ended - __run_timed__started) / 1000000 ))
}

main "$@"
