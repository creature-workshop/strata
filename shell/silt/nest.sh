#!/bin/sh

: <<'MODULE'
Placing a document under a key. Every writer adds its members this way.
MODULE

: <<'FUN'
Appends a document to the answer as the member <key> at <depth>. A scalar
or an empty collection becomes one line, "<depth>.<key>:<type>[=<value>]".
A collection with members becomes one line naming its type, followed by its
members, each one level deeper than before.

  __silt__nest '"a"' '0.:int=1' 0          ->  0."a":int=1
  __silt__nest '"reads"' '0.0:str="x"' 1   ->  1."reads":list
                                               2.0:str="x"

args:
  $1  The key, written as a line writes it: a quoted literal or bare digits
  $2  The document
  $3  The depth of the member
FUN
__silt__nest() {
  __silt__parse "${2%%"$__silt__NL"*}" || return 1

  if [ -z "$__silt__KEY" ]; then
    __silt__emit "$3.$1:${2#0.:}"
    return
  fi

  case "$__silt__KEY" in
    "$__silt__QUOTE"*) __silt__emit "$3.$1:map" ;;
    *) __silt__emit "$3.$1:list" ;;
  esac

  __silt__NEST_DEPTH="$3"
  __silt__AWK='nest'
  __silt__walk "$2" __silt__nest_line
  __silt__absorb_handed
}

: <<'FUN'
Appends one line of a collection to the answer, one level deeper than the
member it now sits under, whose depth is in __silt__NEST_DEPTH.

args:
  $1  The line
FUN
__silt__nest_line() {
  __silt__emit "$((${1%%.*} + __silt__NEST_DEPTH + 1)).${1#*.}"
}
