#!/bin/sh

: <<'MODULE'
silt__string: the text at a path, a str unquoted.
MODULE

: <<'PUB_FUN'
Answers the text at a path the way jq -r would: a str unquoted, another
scalar as its spelling, a null as "null", and the empty string for a path
nothing holds or a collection. Given a default, answers that instead
wherever the path holds nothing, a null or a collection.

  silt__string runner "$doc" '.suites.unit.runner'          ->  runner=bats
  silt__string runner "$doc" '.suites.unit.runner' bats     ->  runner=bats, the path missing too

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path
  $4  The default, when given
PUB_FUN
silt__string() {
  __silt__out "$1" || return 1
  __silt__string__out="$__silt__OUT"

  __silt__string__value=''
  silt__get __silt__string__value "$2" "$3" || return 1

  if [ "$#" -ge 4 ]; then
    __silt__string_or "$__silt__string__value" "$4" || return 1
  else
    __silt__string_text "$__silt__string__value" || return 1
  fi

  __silt__OUT="$__silt__string__out"
  __silt__answer
}

: <<'FUN'
Sets __silt__ANSWER to the text of the value a path held: a scalar's text,
and the empty string for no value or a collection, empty or not. A document
opening with a keyless line is a scalar or an empty collection; any other
first line is a member, so the document is a collection.

args:
  $1  The value silt__get answered, a document or nothing
FUN
__silt__string_text() {
  case "$1" in
    # structs-lint: allow -- a first line with a key opens a collection; SILT sits beneath structs
    '' | 0.:map | 0.:list | 0.[!:]*) __silt__ANSWER='' ;;
    *) __silt__string_of_scalar "$1" || return 1 ;;
  esac
}

: <<'FUN'
Sets __silt__ANSWER to the text of the value a path held, or to the default
for no value, a null or a collection, empty or not.

args:
  $1  The value silt__get answered, a document or nothing
  $2  The default
FUN
__silt__string_or() {
  case "$1" in
    # structs-lint: allow -- a first line with a key opens a collection; SILT sits beneath structs
    '' | 0.:null | 0.:map | 0.:list | 0.[!:]*) __silt__ANSWER="$2" ;;
    *) __silt__string_of_scalar "$1" || return 1 ;;
  esac
}

: <<'FUN'
Sets __silt__ANSWER to the text of a scalar document the way jq -r prints
it: a str unwrapped, a null as the word null, any other as its value.

args:
  $1  The document, one keyless line
FUN
__silt__string_of_scalar() {
  __silt__parse "$1" || return 1

  case "$__silt__TYPE" in
    str) silt__unwrap __silt__ANSWER "$__silt__VALUE" || return 1 ;;
    null) __silt__ANSWER=null ;;
    *) __silt__ANSWER="$__silt__VALUE" ;;
  esac
}
