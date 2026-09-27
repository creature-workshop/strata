#!/bin/sh

: <<'MODULE'
silt__read, silt__to_line and silt__from_line: a document from text that
may be written in more than one way, and a document written on one line.
MODULE

: <<'CONST'
The character that stands for a newline when a document is written on one
line: the unit separator, which no SILT line and no JSON text holds.
CONST
__silt__UNIT="$(printf '\037')"

: <<'PUB_FUN'
Answers the document a text spells, whichever way the text is written:

  as SILT                 the text itself
  as SILT on one line     the text with its newlines put back
  as JSON                 the JSON translated

A JSON scalar is read in the shell. JSON that holds a map or a list goes
through silt__from_json, which starts one awk. Fails, without a message,
when the text is none of the three; the empty string is none of them. The
caller decides what such text means.

  silt__read doc '{"a":[1]}'   ->  doc='0."a":list
                                        1.0:int=1'
  silt__read doc '"bats"'      ->  doc='0.:str="bats"'
  silt__read doc 'bats'        ->  fails

args:
  $1  Name of the variable that receives the result
  $2  The text
PUB_FUN
silt__read() {
  __silt__out "$1" || return 1
  __silt__read__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__read_text "$2" || return 1

  __silt__OUT="$__silt__read__out"
  __silt__answer
}

: <<'FUN'
Sets __silt__ANSWER to the document the text spells, trying SILT first,
then a JSON scalar the shell can read, then any other JSON. Fails when the
text is none of them.

args:
  $1  The text
FUN
__silt__read_text() {
  __silt__is_document "$1"
  if [ "$__silt__IS_DOCUMENT" = true ]; then
    __silt__lines_of "$1"
    return 0
  fi

  __silt__read_scalar "$1" && return 0
  __silt__read_json "$1"
}

: <<'FUN'
Sets __silt__IS_DOCUMENT to true when the text opens the way a SILT line
does: a depth, a dot, and then a quoted key, an index and a colon, or the
colon of a keyless line. Sets it to false otherwise. A JSON number such as
0.5 opens on digits and a dot too, and holds no colon, so it is false.

  0."a":int=1  ->  true
  0.:list      ->  true
  0.5          ->  false

args:
  $1  The text
FUN
__silt__is_document() {
  __silt__IS_DOCUMENT=false
  __silt__is_document__rest="${1#"${1%%[!0-9]*}"}"

  case "$__silt__is_document__rest" in
    "$1") return 0 ;;
    .:* | ."$__silt__QUOTE"*) __silt__IS_DOCUMENT=true ;;
    .[0-9]*) __silt__is_indexed "${__silt__is_document__rest#.}" ;;
  esac
}

: <<'FUN'
Sets __silt__IS_DOCUMENT to true when the text, read from after a line's
depth and dot, is an index followed by a colon.

args:
  $1  The text after the depth and the dot
FUN
__silt__is_indexed() {
  case "${1#"${1%%[!0-9]*}"}" in
    :*) __silt__IS_DOCUMENT=true ;;
  esac
}

: <<'FUN'
Sets __silt__ANSWER to the document of a JSON scalar the shell can read
without starting a process: true, false, null, the empty map, the empty
list, a whole number, and a string that holds no quote, backslash or control
character. Fails for any other text, which may still be JSON.

  "bats"  ->  0.:str="bats"
  {}      ->  0.:map
  -12     ->  0.:int=-12

args:
  $1  The text
FUN
__silt__read_scalar() {
  case "$1" in
    true | false) __silt__ANSWER="0.:bool=$1" ;;
    null) __silt__ANSWER='0.:null' ;;
    '{}') __silt__ANSWER='0.:map' ;;
    '[]') __silt__ANSWER='0.:list' ;;
    "$__silt__QUOTE"*) __silt__read_plain_string "$1" ;;
    0 | [1-9]* | -[1-9]*) __silt__read_whole_number "$1" ;;
    *) return 1 ;;
  esac
}

: <<'FUN'
Sets __silt__ANSWER to an int document when the text is digits after an
optional minus sign. Fails for any other text.

args:
  $1  The text, which opens on a digit or a minus sign
FUN
__silt__read_whole_number() {
  case "${1#-}" in
    *[!0-9]*) return 1 ;;
  esac
  __silt__ANSWER="0.:int=$1"
}

: <<'FUN'
Sets __silt__ANSWER to a str document when the text is a JSON string that
holds no quote, backslash or control character between its quotes, so it is
a SILT literal as written. Fails for any other text.

args:
  $1  The text, which opens on a quote
FUN
__silt__read_plain_string() {
  case "$1" in
    "$__silt__QUOTE") return 1 ;;
    *"$__silt__QUOTE") ;;
    *) return 1 ;;
  esac

  __silt__read_plain_string__inside="${1#"$__silt__QUOTE"}"
  case "${__silt__read_plain_string__inside%"$__silt__QUOTE"}" in
    *[\"\\]* | *[[:cntrl:]]*) return 1 ;;
  esac
  __silt__ANSWER="0.:str=$1"
}

: <<'FUN'
Sets __silt__ANSWER to the JSON text as a document, through
silt__from_json. Fails, without a message, when the text is not JSON. Text
that cannot open a JSON value fails without starting a process.

args:
  $1  The text
FUN
__silt__read_json() {
  case "$1" in
    '{'* | '['* | "$__silt__QUOTE"* | -* | [0-9]*) ;;
    *) return 1 ;;
  esac

  silt__from_json __silt__read_json__doc 2>/dev/null <<EOF || return 1
$1
EOF
  __silt__ANSWER="$__silt__read_json__doc"
}

: <<'PUB_FUN'
Answers the document written on one line: every newline becomes the unit
separator. A caller that reads values a line at a time, one value per line,
can then carry a whole document as one of them. silt__from_line and
silt__read both read the line back.

  silt__to_line text '0."a":list
  1.0:int=1'   ->  text='0."a":list<US>1.0:int=1'

args:
  $1  Name of the variable that receives the result
  $2  The document
PUB_FUN
silt__to_line() {
  __silt__out "$1" || return 1
  __silt__to_line__out="$__silt__OUT"

  __silt__rejoin "$2" "$__silt__NL" "$__silt__UNIT"

  __silt__OUT="$__silt__to_line__out"
  __silt__answer
}

: <<'PUB_FUN'
Answers the document that silt__to_line wrote on one line: every unit
separator becomes a newline again. A document that was never on one line
answers itself.

  silt__from_line doc '0."a":list<US>1.0:int=1'   ->  doc='0."a":list
                                                           1.0:int=1'

args:
  $1  Name of the variable that receives the result
  $2  The document on one line
PUB_FUN
silt__from_line() {
  __silt__out "$1" || return 1
  __silt__from_line__out="$__silt__OUT"

  __silt__lines_of "$2"

  __silt__OUT="$__silt__from_line__out"
  __silt__answer
}

: <<'FUN'
Sets __silt__ANSWER to the text with every unit separator turned into a
newline.

args:
  $1  The text
FUN
__silt__lines_of() {
  __silt__rejoin "$1" "$__silt__UNIT" "$__silt__NL"
}

: <<'FUN'
Sets __silt__ANSWER to the text with every <from> character turned into
<to>. It splits the text on <from> and joins the parts with <to>, which the
shell does in one pass. Text that holds no <from> is answered as it is.

args:
  $1  The text
  $2  The character to replace
  $3  The character to put in its place
FUN
__silt__rejoin() {
  __silt__ANSWER="$1"
  case "$1" in
    *"$2"*) ;;
    *) return 0 ;;
  esac

  __silt__rejoin__ifs_was_set="${IFS+true}"
  __silt__rejoin__ifs="${IFS-}"
  __silt__rejoin__to="$3"
  IFS="$2"
  set -f
  # shellcheck disable=SC2086  # the split is the point
  set -- $1
  set +f
  IFS="$__silt__rejoin__to"
  __silt__ANSWER="$*"
  __silt__give_back_ifs "$__silt__rejoin__ifs_was_set" "$__silt__rejoin__ifs"
}
