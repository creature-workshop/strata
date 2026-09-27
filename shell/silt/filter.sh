#!/bin/sh

: <<'MODULE'
silt__filter: the members a predicate keeps.
MODULE

: <<'PUB_FUN'
Answers a document of the same kind as the one given, holding the members
the predicate answers true for: a map's under their keys, a list's numbered
on from 0. The predicate is called with the name of the variable to answer
in, the member's key as text, its value as a document, and the extra
arguments after them. It answers true or false, and it can run any verb, a
loop of its own included.

  passed() { silt__string status "$3" .status; ...answers whether it is passed }
  silt__filter passing "$tests" passed

  predicate <out> <key> <value> [extras...]  ->  answers true or false in <out>

args:
  $1  The name of the variable to answer in
  $2  The document, a map or a list
  $3  The predicate
  $@  Extra arguments the predicate receives after the key and the value
PUB_FUN
silt__filter() {
  __silt__out "$1" || return 1
  __silt__filter_members "$@" || return $?

  __silt__ANSWER="$__silt__COLLECTED"
  __silt__answer_in "$1"
}

: <<'FUN'
Walks the members, collecting in __silt__COLLECTED the ones the predicate
keeps.

args:
  $1  The name of the variable to answer in, unread here
  $2  The document
  $3  The predicate
  $@  The extras
FUN
__silt__filter_members() {
  __silt__filter_members__doc="$2"
  shift 2

  __silt__start_collecting "$__silt__filter_members__doc" || return 1
  silt__each __silt__filter_member "$__silt__filter_members__doc" "$@"
}

: <<'FUN'
Handles one member: asks the predicate, and keeps the member when it answers
true.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The predicate
  $@  The extras
FUN
__silt__filter_member() {
  __silt__verdict "$@" || return $?

  if [ "$__silt__VERDICT" = true ]; then
    __silt__keep_member "$1" "$2" || return 1
  fi
}
