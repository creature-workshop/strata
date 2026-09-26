#!/bin/sh

: <<'MODULE'
Reading a path one segment at a time: .a, .a[2], .[0], ."quoted" and ["quoted"].
MODULE

: <<'FUN'
Reads the next segment off the front of the path in __silt__PATH into
__silt__SEGMENT, spelled the way a line's key is: a quoted literal for a
member name, bare digits for an index. Sets __silt__PATH_DONE to true when
no segment is left.

  ".a[2].b"            ->  '"a"', then 2, then '"b"', then done
  '."x.y"["p q"].z'    ->  '"x.y"', then '"p q"', then '"z"', then done

args: none, reads __silt__PATH
FUN
__silt__next_segment() {
  __silt__PATH="${__silt__PATH#.}"
  __silt__PATH_DONE=false
  case "$__silt__PATH" in
    '')
      __silt__PATH_DONE=true
      ;;
    '"'*)
      __silt__quoted_segment "$__silt__PATH" || return 1
      ;;
    '["'*)
      __silt__quoted_segment "${__silt__PATH#\[}" || return 1
      __silt__PATH="${__silt__PATH#\]}"
      ;;
    \[*)
      __silt__SEGMENT="${__silt__PATH%%\]*}"
      __silt__SEGMENT="${__silt__SEGMENT#\[}"
      __silt__PATH="${__silt__PATH#*\]}"
      ;;
    *)
      __silt__next_segment__name="${__silt__PATH%%[.\[]*}"
      __silt__PATH="${__silt__PATH#"$__silt__next_segment__name"}"
      silt__wrap __silt__SEGMENT "$__silt__next_segment__name"
      ;;
  esac
}

: <<'FUN'
Reads a quoted key off the front of a path into __silt__SEGMENT, quotes and
escapes as written, and leaves the path after its closing quote in
__silt__PATH.

  __silt__quoted_segment '"a\"b".c'   ->  SEGMENT '"a\"b"'  PATH '.c'

args:
  $1  The path from its opening quote
FUN
__silt__quoted_segment() {
  __silt__quoted_literal "$1" '"' || return 1
  __silt__SEGMENT="$__silt__LITERAL"
  __silt__PATH="$__silt__REST"
}
