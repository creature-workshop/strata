#!/bin/sh

: <<'MODULE'
silt__option and silt__option_is: read one option from a map of options. A
caller builds the map with silt__obj, and a verb that takes options reads
each one here, so every option has a name and a default in one place.
MODULE

: <<'PUB_FUN'
Answers the text of the option at a key, the way silt__string answers it.
Answers the default when the map does not hold the key, or holds a null or
a collection there. The key is the option's name as plain text, not a path.

  silt__option how '0."arrays":str="union"' arrays replace   ->  how=union
  silt__option how '0.:map' arrays replace                   ->  how=replace

args:
  $1  The name of the variable to answer in
  $2  The map of options
  $3  The key
  $4  The default; the empty string when not given
PUB_FUN
silt__option() {
  __silt__out "$1" || return 1
  __silt__option__out="$__silt__OUT"

  __silt__wrap_literal "$3"
  silt__string __silt__ANSWER "$2" ".$__silt__LITERAL" --default "${4:-}" || return 1

  __silt__OUT="$__silt__option__out"
  __silt__answer
}

: <<'PUB_FUN'
Answers true when the option at a key has the text given, and false
otherwise. An option that is missing or null never matches, whatever text
is given.

  silt__option_is yes '0."arrays":str="union"' arrays union   ->  yes=true
  silt__option_is yes '0.:map' arrays ''                      ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The map of options
  $3  The key
  $4  The text to compare with
PUB_FUN
silt__option_is() {  # file-segment-check: allow -- a public verb's name is the API's; renaming it is STRATA-217's call, not the sweep's
  __silt__out "$1" || return 1
  __silt__option_is__out="$__silt__OUT"

  __silt__wrap_literal "$3"
  __silt__option_is__held=''
  silt__get __silt__option_is__held "$2" ".$__silt__LITERAL" || return 1
  __silt__option__matches "$__silt__option_is__held" "${4:-}" || return 1

  __silt__OUT="$__silt__option_is__out"
  __silt__answer
}

: <<'FUN'
Sets __silt__ANSWER to true when the value is a scalar with the text given,
and to false for any other text, a null, a collection or no value.

args:
  $1  The value silt__get answered, a document or nothing
  $2  The text to compare with
FUN
__silt__option__matches() {
  __silt__option__matches__defined=''
  silt__defined __silt__option__matches__defined "$1" || return 1
  if [ "$__silt__option__matches__defined" = false ]; then
    __silt__ANSWER=false
    return 0
  fi

  __silt__string__text "$1" || return 1
  __silt__is_spelled "$__silt__ANSWER" "$2"
}
