#!/bin/sh

: <<'FRAGMENT'
silt__apply: a command run once, with the elements of a list as its last
arguments.
FRAGMENT

: <<'PUB_FUN'
The plumbing of @apply: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_apply.sh documents it.
PUB_FUN
silt__apply() {
  __silt__require_list "${1:-}" apply || return 1
  if [ "$#" -lt 2 ]; then
    __silt__fail 'apply requires a command'
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
