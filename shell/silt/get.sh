#!/bin/sh

# silt__get: the value at a path, as a document of its own.

: <<'PUB_FUN'
Answers the value at a path as a document of its own: a leaf becomes one
keyless line, a collection becomes its members at depth 0, an empty
collection or a null its one keyless line. Answers the empty string for a
path nothing holds, which no document is.

  silt__get runner "$doc" '.suites.unit.runner'   ->  runner='0.:str="bats"'
  silt__get reads "$doc" '.suites.unit.tests'     ->  reads='0."test/a.bats":map
                                                              1."reads":list
                                                              2.0:str="lib/a.sh"'

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path
PUB_FUN
silt__get() {
  __silt__out "$1" || return 1
  __silt__get__out="$__silt__OUT"
  __silt__PATH="$3"
  __silt__next_segment
  case "$__silt__PATH_DONE" in
    true)
      __silt__ANSWER="$2"
      __silt__OUT="$__silt__get__out"
      __silt__answer
      return 0
      ;;
  esac
  __silt__get__want=0
  __silt__get__found=false
  __silt__ANSWER=''
  __silt__get__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $2
  set +f
  IFS="$__silt__get__ifs"
  for __silt__get__line do
    __silt__parse "$__silt__get__line" || return 1
    case "$__silt__get__found" in
      true)
        if [ "$__silt__DEPTH" -le "$__silt__get__at" ]; then
          break
        fi
        case "$__silt__ANSWER" in
          0.:map | 0.:list) __silt__ANSWER='' ;;
        esac
        __silt__emit "$((__silt__DEPTH - __silt__get__at - 1)).${__silt__get__line#*.}"
        continue
        ;;
    esac
    if [ "$__silt__DEPTH" -lt "$__silt__get__want" ]; then
      break
    fi
    if [ "$__silt__DEPTH" -ne "$__silt__get__want" ] || [ "$__silt__KEY" != "$__silt__SEGMENT" ]; then
      continue
    fi
    __silt__next_segment
    case "$__silt__PATH_DONE" in
      true)
        __silt__get__found=true
        __silt__get__at="$__silt__DEPTH"
        case "$__silt__LEAF" in
          true) __silt__ANSWER="0.:$__silt__TYPE=$__silt__VALUE" ;;
          *) __silt__ANSWER="0.:$__silt__TYPE" ;;
        esac
        ;;
      *)
        __silt__get__want=$((__silt__get__want + 1))
        ;;
    esac
  done
  case "$__silt__get__found" in
    true) ;;
    *) __silt__ANSWER='' ;;
  esac
  __silt__OUT="$__silt__get__out"
  __silt__answer
}
