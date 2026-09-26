#!/bin/sh

: <<'MODULE'
silt__each: a callback per member, with its key and its value.
MODULE

: <<'PUB_FUN'
Calls <callback> once per member of a map or a list, with the member's key
as text (a map's unquoted, a list's index), the member's value as a document
of its own, and the extra arguments after them. Stops at the first callback
that returns non-zero, returning its status.

The extra arguments are held by name while the split has the positional
parameters, and the call is assembled from those names, so nothing in a value
is ever re-read as shell.

  count_reads() { silt__len n "$2"; total=$((total + n)); }
  total=0
  silt__each count_reads "$tests"

args:
  $1  The callback
  $2  The document
  $@  Extra arguments the callback receives after the key and the value
PUB_FUN
silt__each() {
  __silt__each__callback="$1"
  __silt__each__doc="$2"
  shift 2
  __silt__each__kind=''
  silt__type __silt__each__kind "$__silt__each__doc" || return 1
  case "$__silt__each__kind" in
    map | list) ;;
    *)
      __silt__fail "$__silt__each__kind has no members"
      return 1
      ;;
  esac
  __silt__each__extras=''
  __silt__each__count=0
  for __silt__each__extra do
    __silt__each__count=$((__silt__each__count + 1))
    eval "__silt__each__extra_$__silt__each__count=\$__silt__each__extra"
    __silt__each__extras="$__silt__each__extras \"\$__silt__each__extra_$__silt__each__count\""
  done
  __silt__each__key=''
  __silt__each__value=''
  __silt__each__open=false
  __silt__each__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $__silt__each__doc
  set +f
  IFS="$__silt__each__ifs"
  for __silt__each__line do
    __silt__parse "$__silt__each__line" || return 1
    if [ "$__silt__DEPTH" -eq 0 ]; then
      case "$__silt__each__open" in
        true) __silt__each_call || return $? ;;
      esac
      case "$__silt__KEY" in
        '') return 0 ;;
        '"'*) silt__unwrap __silt__each__key "$__silt__KEY" || return 1 ;;
        *) __silt__each__key="$__silt__KEY" ;;
      esac
      case "$__silt__LEAF" in
        true) __silt__each__value="0.:$__silt__TYPE=$__silt__VALUE" ;;
        *) __silt__each__value="0.:$__silt__TYPE" ;;
      esac
      __silt__each__open=true
    else
      case "$__silt__each__value" in
        0.:map | 0.:list) __silt__each__value="$((__silt__DEPTH - 1)).${__silt__each__line#*.}" ;;
        *) __silt__each__value="$__silt__each__value$__silt__NL$((__silt__DEPTH - 1)).${__silt__each__line#*.}" ;;
      esac
    fi
  done
  case "$__silt__each__open" in
    true) __silt__each_call || return $? ;;
  esac
}

: <<'FUN'
Calls silt__each's callback with the member in the registers and the extra
arguments held by name, returning the callback's status.
FUN
__silt__each_call() {
  eval "\"\$__silt__each__callback\" \"\$__silt__each__key\" \"\$__silt__each__value\"$__silt__each__extras"
}
