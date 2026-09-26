#!/bin/sh

: <<'MODULE'
Reading one line into the registers: its depth, its key (quoted or bare),
its type and its value.
MODULE

: <<'FUN'
Sets __silt__ODD to true when <text> ends in an odd run of backslashes, the
sign that the character after it is escaped, and to false otherwise.

  __silt__trailing_backslashes_odd 'a\\'   ->  false
  __silt__trailing_backslashes_odd 'a\'    ->  true

args:
  $1  The text
FUN
__silt__trailing_backslashes_odd() {
  __silt__trailing_backslashes_odd__run="${1##*[!\\]}"

  case $((${#__silt__trailing_backslashes_odd__run} % 2)) in
    1) __silt__ODD=true ;;
    *) __silt__ODD=false ;;
  esac
}

: <<'FUN'
Reads a quoted literal off the front of <text> into __silt__LITERAL, quotes
and escapes as written, and leaves what follows the closer in __silt__REST.
The literal ends at the first <closer> whose quote does not follow an odd run
of backslashes (ADR.4@strata); a closer escaped that way is part of it.

  __silt__quoted_literal '"a \"b\": c":int=1' '":'   ->  LITERAL '"a \"b\": c"'  REST 'int=1'
  __silt__quoted_literal '"a\"b".c' '"'              ->  LITERAL '"a\"b"'        REST '.c'

args:
  $1  The text from its opening quote
  $2  The closer: the closing quote and what must follow it
FUN
__silt__quoted_literal() {
  __silt__quoted_literal__rest="${1#"$__silt__QUOTE"}"
  __silt__LITERAL="$__silt__QUOTE"

  while :; do
    __silt__quoted_literal__head="${__silt__quoted_literal__rest%%"$2"*}"

    if [ "$__silt__quoted_literal__head" = "$__silt__quoted_literal__rest" ]; then
      __silt__fail "a quoted literal never closes: $1"
      return 1
    fi

    __silt__quoted_literal__rest="${__silt__quoted_literal__rest#*"$2"}"
    __silt__LITERAL="$__silt__LITERAL$__silt__quoted_literal__head"

    __silt__trailing_backslashes_odd "$__silt__quoted_literal__head"
    if [ "$__silt__ODD" = false ]; then
      break
    fi

    __silt__LITERAL="$__silt__LITERAL$2"
  done

  __silt__LITERAL="$__silt__LITERAL$__silt__QUOTE"
  __silt__REST="$__silt__quoted_literal__rest"
}

: <<'FUN'
Reads a quoted key off the front of a line's text after its depth into
__silt__KEY, and leaves what follows the key's closing quote and colon in
__silt__REST.

  __silt__quoted_key '"a \"b\": c":int=1'  ->  KEY '"a \"b\": c"'  REST 'int=1'

args:
  $1  The line's text from its opening quote
FUN
__silt__quoted_key() {
  __silt__quoted_literal "$1" "$__silt__QUOTE:" || return 1
  __silt__KEY="$__silt__LITERAL"
}

: <<'FUN'
Reads a bare key, an index or nothing at all, off the front of a line's text
after its depth into __silt__KEY, and leaves what follows the colon in
__silt__REST.

  __silt__bare_key '0:str="x"'  ->  KEY 0   REST 'str="x"'
  __silt__bare_key ':map'       ->  KEY ''  REST 'map'

args:
  $1  The line's text after its depth
FUN
__silt__bare_key() {
  __silt__KEY="${1%%:*}"
  __silt__REST="${1#*:}"
}

: <<'FUN'
Reads a line's key, quoted or bare, into __silt__KEY, and leaves what follows
the colon in __silt__REST.

args:
  $1  The line's text after its depth
FUN
__silt__parse_key() {
  case "$1" in
    "$__silt__QUOTE"*) __silt__quoted_key "$1" ;;
    *) __silt__bare_key "$1" ;;
  esac
}

: <<'FUN'
Reads a leaf's type and value into __silt__TYPE and __silt__VALUE, and sets
__silt__LEAF to true.

  __silt__leaf 'str="x"'  ->  TYPE str  VALUE '"x"'  LEAF true

args:
  $1  The line's text after its key, holding an equals sign
FUN
__silt__leaf() {
  __silt__TYPE="${1%%=*}"
  __silt__VALUE="${1#*=}"
  __silt__LEAF=true
}

: <<'FUN'
Reads a collection's or a null's type into __silt__TYPE, empties
__silt__VALUE, and sets __silt__LEAF to false.

  __silt__node 'map'  ->  TYPE map  VALUE ''  LEAF false

args:
  $1  The line's text after its key, a type alone
FUN
__silt__node() {
  __silt__TYPE="$1"
  __silt__VALUE=''
  __silt__LEAF=false
}

: <<'FUN'
Reads a line's type and value, the text after its key, into __silt__TYPE,
__silt__VALUE and __silt__LEAF: a leaf carries "=<value>" after its type, a
collection or a null carries nothing.

args:
  $1  The line's text after its key
FUN
__silt__parse_node() {
  case "$1" in
    *=*) __silt__leaf "$1" ;;
    *) __silt__node "$1" ;;
  esac
}

: <<'FUN'
Reads one line into the registers: __silt__DEPTH, __silt__KEY (a quoted
literal under a map, bare digits under a list, empty on a keyless line),
__silt__TYPE, __silt__VALUE and __silt__LEAF, true when the line carries a
value.

  __silt__parse '2."reads":list'        ->  DEPTH 2  KEY '"reads"'  TYPE list  LEAF false
  __silt__parse '3.0:str="lib/a.sh"'    ->  DEPTH 3  KEY 0  TYPE str  VALUE '"lib/a.sh"'  LEAF true

args:
  $1  The line
FUN
__silt__parse() {
  __silt__DEPTH="${1%%.*}"

  if [ "$__silt__DEPTH" = "$1" ]; then
    __silt__fail "not a SILT line: $1"
    return 1
  fi

  __silt__parse_key "${1#*.}" || return 1
  __silt__parse_node "$__silt__REST"
}
