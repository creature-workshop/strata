#!/bin/sh

: <<'MODULE'
Reading a path one segment at a time: .a, .a[2], .[0], ."quoted" and
["quoted"].
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
    '') __silt__segment_end ;;
    "$__silt__QUOTE"*) __silt__quoted_segment "$__silt__PATH" ;;
    "[$__silt__QUOTE"*) __silt__bracketed_segment ;;
    \[*) __silt__index_segment ;;
    *) __silt__name_segment ;;
  esac
}

: <<'FUN'
Marks the path read to its end.
FUN
__silt__segment_end() {
  __silt__PATH_DONE=true
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
  __silt__quoted_literal "$1" "$__silt__QUOTE" || return 1
  __silt__SEGMENT="$__silt__LITERAL"
  __silt__PATH="$__silt__REST"
}

: <<'FUN'
Reads a bracketed quoted key, ["a.b"], off the front of __silt__PATH into
__silt__SEGMENT, and leaves the path after the closing bracket.
FUN
__silt__bracketed_segment() {
  __silt__quoted_segment "${__silt__PATH#\[}" || return 1
  __silt__PATH="${__silt__PATH#\]}"
}

: <<'FUN'
Reads a bracketed index, [2], off the front of __silt__PATH into
__silt__SEGMENT as bare digits, and leaves the path after the closing bracket.
FUN
__silt__index_segment() {
  __silt__SEGMENT="${__silt__PATH%%\]*}"
  __silt__SEGMENT="${__silt__SEGMENT#\[}"
  __silt__PATH="${__silt__PATH#*\]}"
}

: <<'FUN'
Reads a bare member name, up to the next dot or bracket, off the front of
__silt__PATH into __silt__SEGMENT as the quoted literal a line's key spells.
FUN
__silt__name_segment() {
  __silt__name_segment__name="${__silt__PATH%%[.\[]*}"
  __silt__PATH="${__silt__PATH#"$__silt__name_segment__name"}"
  __silt__wrap_literal "$__silt__name_segment__name"
  __silt__SEGMENT="$__silt__LITERAL"
}

: <<'FUN'
Reads every segment left in __silt__PATH into __silt__SEGMENTS, one per
line, from the one in __silt__SEGMENT on, and leaves __silt__PATH where it
was so the shell's own walk reads the same segments again.

args: none, reads __silt__SEGMENT and __silt__PATH
FUN
__silt__all_segments() {
  __silt__all_segments__path="$__silt__PATH"
  __silt__SEGMENTS="$__silt__SEGMENT"

  while :; do
    __silt__next_segment || return 1
    if [ "$__silt__PATH_DONE" = true ]; then
      break
    fi
    __silt__SEGMENTS="$__silt__SEGMENTS$__silt__NL$__silt__SEGMENT"
  done

  __silt__PATH="$__silt__all_segments__path"
  __silt__next_segment_back
}

: <<'FUN'
Puts __silt__SEGMENT back to the first segment of __silt__PATH after
__silt__all_segments read them all, by reading the first again.
FUN
__silt__next_segment_back() {
  __silt__SEGMENT="${__silt__SEGMENTS%%"$__silt__NL"*}"
  __silt__PATH_DONE=false
}
