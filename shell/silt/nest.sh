#!/bin/sh

: <<'MODULE'
Placing a document under a key: what every writer does per member.
MODULE

: <<'FUN'
Appends <document> to the answer as the member <key> at <depth>: a scalar or
an empty collection becomes the one line "<depth>.<key>:<type>[=<value>]", a
collection with members becomes that line for its type, then its members
one level deeper than they were.

  __silt__nest '"a"' '0.:int=1' 0          ->  0."a":int=1
  __silt__nest '"reads"' '0.0:str="x"' 1   ->  1."reads":list
                                               2.0:str="x"

args:
  $1  The key, spelled as a line spells it: a quoted literal or bare digits
  $2  The document
  $3  The depth the member sits at
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

  __silt__nest_members "$2" "$3"
}

: <<'FUN'
Appends a collection's lines to the answer, each one level deeper than the
member they now sit under.

args:
  $1  The document, a collection with members
  $2  The depth the member sits at
FUN
__silt__nest_members() {
  __silt__nest_members__depth="$2"

  __silt__nest_members__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $1
  set +f
  IFS="$__silt__nest_members__ifs"

  for __silt__nest_members__line do
    __silt__emit "$((${__silt__nest_members__line%%.*} + __silt__nest_members__depth + 1)).${__silt__nest_members__line#*.}"
  done
}
