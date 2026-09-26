#!/bin/sh

# silt__string: the text at a path, a str unquoted.

: <<'PUB_FUN'
Answers the text at a path the way jq -r would: a str unquoted, another
scalar as its spelling, a null as "null", and the empty string for a path
nothing holds or a collection.

  silt__string runner "$doc" '.suites.unit.runner'   ->  runner=bats

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path
PUB_FUN
silt__string() {
  __silt__out "$1" || return 1
  __silt__string__out="$__silt__OUT"
  __silt__string__value=''
  silt__get __silt__string__value "$2" "$3" || return 1
  __silt__OUT="$__silt__string__out"
  __silt__ANSWER=''
  case "$__silt__string__value" in
    '' | *"$__silt__NL"*)
      __silt__answer
      return 0
      ;;
  esac
  __silt__parse "$__silt__string__value" || return 1
  case "$__silt__TYPE" in
    str)
      silt__unwrap __silt__ANSWER "$__silt__VALUE" || return 1
      ;;
    null)
      __silt__ANSWER=null
      ;;
    *)
      __silt__ANSWER="$__silt__VALUE"
      ;;
  esac
  __silt__OUT="$__silt__string__out"
  __silt__answer
}
