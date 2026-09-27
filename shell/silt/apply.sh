#!/bin/sh

: <<'MODULE'
silt__apply: a command run once, with the elements of a list as its last
arguments.
MODULE

: <<'PUB_FUN'
Runs a command once, with the text of each element of a list added after
the command's own arguments, and returns the command's status. Each element
is read the way silt__string reads it: a str unquoted, another scalar as
written. Use it for a command that takes any number of files or names.

  silt__apply "$files" git add --   ->  runs: git add -- a.sh b.sh

Refuses a document that is not a list, and a call with no command.

args:
  $1  The list
  $@  The command and its own arguments
PUB_FUN
silt__apply() {
  __silt__require_list "${1:-}" apply || return 1
  if [ "$#" -lt 2 ]; then
    __silt__fail 'apply takes a command'
    return 1
  fi
  __silt__apply__list="$1"
  shift

  __silt__apply__count=0
  silt__len __silt__apply__count "$__silt__apply__list" || return 1
  __silt__apply__at=0

  while [ "$__silt__apply__at" -lt "$__silt__apply__count" ]; do
    silt__string __silt__apply__text "$__silt__apply__list" ".[$__silt__apply__at]" || return 1
    # structs-lint: allow -- this verb is what builds the argument list; SILT sits beneath structs
    set -- "$@" "$__silt__apply__text"
    __silt__apply__at=$((__silt__apply__at + 1))
  done

  "$@"
}
