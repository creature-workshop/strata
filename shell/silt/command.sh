#!/bin/sh

: <<'MODULE'
silt__succeeds and silt__fails: the exit status of a command as the word
true or false. Commands such as [ and grep -q report a yes or a no in their
exit status. A function that wraps one of them uses these verbs to return
the answer as a value.
MODULE

: <<'PUB_FUN'
Runs a command and answers true when it exits with status 0, and false
otherwise. The command reads the caller's stdin.

  silt__succeeds yes [ "$kind" = map ]                  ->  yes=true or yes=false
  printf '%s\n' "$text" | silt__succeeds yes grep -q x  ->  whether the text has an x

args:
  $1  The name of the variable to answer in
  $@  The command and its arguments
PUB_FUN
silt__succeeds() {
  __silt__out "$1" || return 1
  shift

  __silt__command__run true false "$@"
}

: <<'PUB_FUN'
Runs a command and answers true when it exits with a status other than 0,
and false when it exits with 0. The command reads the caller's stdin.

  silt__fails drifted ./install.sh --check   ->  drifted=true when the check fails

args:
  $1  The name of the variable to answer in
  $@  The command and its arguments
PUB_FUN
silt__fails() {
  __silt__out "$1" || return 1
  shift

  __silt__command__run false true "$@"
}

: <<'FUN'
Runs a command and assigns one of two words to the variable __silt__out
checked: the first when the command exits with 0, the second otherwise. The
command can call any verb, because the variable's name is kept in the
positional parameters while the command runs.

args:
  $1  The word for status 0
  $2  The word for any other status
  $@  The command and its arguments
FUN
__silt__command__run() {
  set -- "$__silt__OUT" "$@"

  if __silt__command__call "$@"; then
    __silt__ANSWER="$2"
  else
    __silt__ANSWER="$3"
  fi

  __silt__answer_in "$1"
}

: <<'FUN'
Runs the command that follows the first three arguments.

args:
  $1  The name of the variable to answer in
  $2  The word for status 0
  $3  The word for any other status
  $@  The command and its arguments
FUN
__silt__command__call() {
  shift 3
  "$@"
}
