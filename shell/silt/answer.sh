#!/bin/sh

: <<'MODULE'
How a verb reports: a failure, the answer variable checked and assigned, a
document built one line at a time.
MODULE

: <<'FUN'
Reports a failure of this library and returns 1, so a caller under set -e
stops and one without it reads the status.

args:
  $1  What went wrong, one line
FUN
__silt__fail() {
  error "silt: $1"
  return 1
}

: <<'FUN'
Holds the caller's answer variable in __silt__OUT after checking it is a
name the shell accepts, so the eval that assigns it runs nothing else.

args:
  $1  The name of the variable to answer in
FUN
__silt__out() {
  case "$1" in
    # structs-lint: allow -- a variable name's spelling, checked before an eval; SILT sits beneath structs
    '' | [0-9]* | *[!A-Za-z0-9_]*)
      __silt__fail "not a variable name: '$1'"
      return 1
      ;;
  esac

  __silt__OUT="$1"
}

: <<'FUN'
Assigns __silt__ANSWER to the variable __silt__out held.
FUN
__silt__answer() {
  eval "$__silt__OUT=\$__silt__ANSWER"
}

: <<'FUN'
Appends a line to the document __silt__ANSWER is building, with the newline
that separates lines and none before the first.

args:
  $1  The line
FUN
__silt__emit() {
  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER="$1"
  else
    __silt__ANSWER="$__silt__ANSWER$__silt__NL$1"
  fi
}

: <<'FUN'
Assigns __silt__ANSWER to the variable named, one __silt__out has checked
already, for a verb whose callbacks answered through __silt__OUT meanwhile.

args:
  $1  The name of the variable to answer in
FUN
__silt__answer__in() {
  __silt__OUT="$1"
  __silt__answer
}
