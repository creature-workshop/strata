#!/bin/sh
# Two subshells of one process run the two-document verbs at once, for the
# subshell case in test/silt-reader.bats, under whatever shell runs it. Each
# worker merges its own overlay into a base map and sets its own value at a
# path, a round at a time, every walk handed to awk, and counts the answers
# that do not hold its own value. It prints one line, its name and that
# count, so two lines of a name and 0 mean neither read the other's
# document. Its functions carry the workers__ prefix because it sources the
# library into its own shell.
#
# Usage: <shell> test/silt-workers.sh <api.sh> <rounds>

set -u

main() {
  workers__require_usage "$@"
  workers__load_library "$1"
  ROUNDS="$2"
  ( workers__run A ) &
  ( workers__run B ) &
  wait
}

# The library and the count of rounds are both required.
workers__require_usage() {
  if [ "$#" -ne 2 ]; then
    printf 'usage: silt-workers.sh <api.sh> <rounds>\n' >&2
    exit 2
  fi
}

# Sources the library, telling it where it lives, with every walk handed to
# awk so the value of a set goes ahead of its document.
workers__load_library() {
  export SILT_DIR="${1%/*}"
  export SILT_THRESHOLD=0
  . "$1"
}

# Runs the rounds as one worker and prints its name and how many answers
# were not its own.
workers__run() {
  __workers__run__wrong=0
  __workers__run__round=0

  while [ "$__workers__run__round" -lt "$ROUNDS" ]; do
    workers__round "$1"
    __workers__run__round=$((__workers__run__round + 1))
  done

  printf '%s %s\n' "$1" "$__workers__run__wrong"
}

# One round: a merge and a set that each write the worker's name under who,
# counting every answer that holds another value or none.
workers__round() {
  __workers__round__merged=''
  silt__merge __workers__round__merged '0."k":int=0' "0.\"who\":str=\"$1\"" || __workers__round__merged=''
  workers__count_wrong "$__workers__round__merged" "$1"

  __workers__round__set=''
  silt__set __workers__round__set '0."k":int=0' .who "0.:str=\"$1\"" || __workers__round__set=''
  workers__count_wrong "$__workers__round__set" "$1"
}

# Counts an answer whose who is not the worker's name.
workers__count_wrong() {
  __workers__count_wrong__who=''
  if [ -n "$1" ]; then
    silt__string __workers__count_wrong__who "$1" .who || __workers__count_wrong__who=''
  fi

  if [ "$__workers__count_wrong__who" != "$2" ]; then
    __workers__run__wrong=$((__workers__run__wrong + 1))
  fi
}

main "$@"
