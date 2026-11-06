#!/bin/sh
# Exercises the reader over one document, for the process and timing cases in
# test/silt-reader.bats, under whatever shell runs it. Its functions carry the
# exercise__ prefix because it sources the library into its own shell.
#
# Usage: <shell> test/silt-exercise.sh <api.sh> <document> import|verbs|writers|timed
#
#   import  sources the library and reads the document, exercise__nothing more
#   verbs   runs type, get, string, has, len, keys and each over it
#   writers runs set with one pair, set with two pairs and patch over it
#   timed   runs get, len and each, then prints the get's answer, the len and
#           the milliseconds the three took, one per line

set -u

main() {
  exercise__require_usage "$@"
  exercise__load_library "$1"
  DOC="$(cat "$2")"
  case "$3" in
    import) ;;
    verbs) exercise__run_verbs ;;
    writers) exercise__run_writers ;;
    timed) exercise__run_timed ;;
    *)
      printf 'silt-exercise: %s is not a mode\n' "$3" >&2
      exit 2
      ;;
  esac
}

# The library, the document and the mode are all required.
exercise__require_usage() {
  if [ "$#" -ne 3 ]; then
    printf 'usage: silt-exercise.sh <api.sh> <document> import|verbs|writers|timed\n' >&2
    exit 2
  fi
}

# Sources the reader, telling it where it lives for the shells that cannot tell.
exercise__load_library() {
  export SILT_DIR="${1%/*}"
  . "$1"
}

# The callback each gets: it does nothing.
exercise__nothing() {
  :
}

# Every reader verb once, over the document.
exercise__run_verbs() {
  silt__type t "$DOC"
  silt__get g "$DOC" .key3999
  silt__string s "$DOC" .key7
  silt__has h "$DOC" .key1
  silt__len n "$DOC"
  silt__keys k "$DOC"
  silt__each "$DOC" exercise__nothing extra
}

# The writers that walk the document once per pair: set with one pair, set
# with two, and patch with one, each placing a value under a key it holds.
exercise__run_writers() {
  silt__set w "$DOC" .key7 '0.:str="seven"'
  silt__set w "$DOC" .key8 '0.:str="eight"' .key9 '0.:str="nine"'
  silt__patch w "$DOC" .key10 '0.:str="ten"'
}

# get, len and each over the document, timed with date, which is outside the
# measured span.
exercise__run_timed() {
  __exercise__run_timed__started="$(date +%s%N)"
  silt__get g "$DOC" .key3999
  silt__len n "$DOC"
  silt__each "$DOC" exercise__nothing
  __exercise__run_timed__ended="$(date +%s%N)"
  printf '%s\n%s\n%s\n' "$g" "$n" $(( (__exercise__run_timed__ended - __exercise__run_timed__started) / 1000000 ))
}

main "$@"
