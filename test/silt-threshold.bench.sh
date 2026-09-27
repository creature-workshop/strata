#!/bin/sh
# The timed half of test/silt-threshold.sh, under whatever shell runs it:
# sources the library, reads the document, runs silt__get of key<last> the
# given number of times, and prints the milliseconds one call took.
#
# Usage: <shell> test/silt-threshold.bench.sh <api.sh> <document> <last> <calls>

set -u

main() {
  export SILT_DIR="${1%/*}"
  . "$1"
  DOC="$(cat "$2")"

  __main__started="$(date +%s%N)"
  __main__i=0
  while [ "$__main__i" -lt "$4" ]; do
    silt__get __main__got "$DOC" ".key$3"
    __main__i=$((__main__i + 1))
  done
  __main__ended="$(date +%s%N)"

  printf '%s\n' $(( (__main__ended - __main__started) / 1000000 / $4 ))
}

main "$@"
