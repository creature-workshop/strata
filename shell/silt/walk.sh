#!/bin/sh

: <<'MODULE'
Walking a document line by line. Every verb that reads lines goes through
here.
MODULE

: <<'FUN'
Calls <callback> once per line of a document, in order, with the line as its
argument. The walk ends early when the callback sets __silt__STOP to true,
and returns the callback's status when it fails.

The split is one expansion: IFS a newline and globbing off, so a value's *
stays as it is. A document has no empty line, which the split would drop.

args:
  $1  The document
  $2  The callback, a function taking the line
FUN
__silt__walk() {
  __silt__walk__callback="$2"
  __silt__STOP=false

  __silt__walk__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $1
  set +f
  IFS="$__silt__walk__ifs"

  for __silt__walk__line do
    "$__silt__walk__callback" "$__silt__walk__line" || return $?

    if [ "$__silt__STOP" = true ]; then
      return 0
    fi
  done
}
