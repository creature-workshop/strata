#!/bin/sh

: <<'MODULE'
SILT, structured inline live text: a Strata document carried between shell
functions without its id column, and read here without starting a process.

A document is lines, one node each: "<depth>.<key>:<type>" for a collection
or a null, "<depth>.<key>:<type>=<value>" for a leaf (ADR.2@strata). It is
held in a variable without its final newline. The lines at depth 0 are the
document's members, string keys making it a map and indices a list
(ADR.4@strata), and one keyless line makes it a scalar (ADR.12@strata). A
str's value is its JSON literal, quotes and escapes included (ADR.3@strata).

Every verb answers in the variable the caller names first, and none starts a
process: a verb binds its parameters to names, splits the document into its
own positional parameters once, in C, with IFS a newline and globbing off, and
reads a line at a time from there. The split lives in each verb because the
positional parameters are the function's own; SILT has no empty line, which a
split would drop. A predicate here answers in a register
rather than printing, since printing would cost the subshell the library
exists to avoid. A document past __silt__THRESHOLD lines belongs to the awk
tier, which answers the same call the same way.

  silt__type      the kind of value a document is
  silt__get       the value at a path, as a document of its own
  silt__scalar    the value text of a scalar document
  silt__string    the text at a path, a str unquoted
  silt__has       whether a path holds a value
  silt__len       the number of members
  silt__keys      the members' keys, as a list document
  silt__each      a callback per member, with its key and its value
  silt__unwrap    a JSON string literal to text
  silt__wrap      text to a JSON string literal

A path names members from the top: ".a.b" the member b of the member a,
".a[2]" the third element of the list a, ".[0]" the first element of a list
document, and a key holding "." or "[" is quoted the way JSON spells it,
`."test/a.bats"` or `["test/a.bats"]`, and is matched by that spelling.
MODULE

: <<'CONST'
The line count past which a document is the awk tier's, measured on dash and
bash --posix on 2026-09-26: the split stays under the cost of one awk start
to about 1,700 lines under bash and past 4,000 under dash.
CONST
__silt__THRESHOLD=1000

: <<'CONST'
The characters the shell cannot spell in a literal: a newline for joining
lines, and the four control characters JSON names by letter.
CONST
__silt__NL='
'
__silt__TAB="$(printf '\t')"
__silt__CR="$(printf '\r')"
__silt__BS="$(printf '\b')"
__silt__FF="$(printf '\f')"

: <<'FUN'
Reports a failure of this library on stderr and returns 1, so a caller under
set -e stops and one without it reads the status.

args:
  $1  What went wrong, one line
FUN
__silt__fail() {
  printf 'silt: %s\n' "$1" >&2
  return 1
}

: <<'FUN'
Holds the caller's answer variable in __silt__OUT after checking it is a
name the shell accepts, so the eval that assigns it runs nothing else.

args:
  $1  The name of the variable to answer in
FUN
__silt__out() {
  case "$1" in
    # structs-lint: allow -- a variable name's spelling, checked before an eval; SILT sits beneath structs
    '' | [0-9]* | *[!A-Za-z0-9_]*)
      __silt__fail "not a variable name: '$1'"
      return 1
      ;;
  esac
  __silt__OUT="$1"
}

: <<'FUN'
Assigns __silt__ANSWER to the variable __silt__out held.
FUN
__silt__answer() {
  eval "$__silt__OUT=\$__silt__ANSWER"
}

: <<'FUN'
Sets __silt__ODD to true when <text> ends in an odd run of backslashes, the
sign that the character after it is escaped, and to false otherwise.

  __silt__trailing_backslashes_odd 'a\\'   ->  false
  __silt__trailing_backslashes_odd 'a\'    ->  true

args:
  $1  The text
FUN
__silt__trailing_backslashes_odd() {
  __silt__trailing_backslashes_odd__text="$1"
  __silt__trailing_backslashes_odd__count=0
  while [ "${__silt__trailing_backslashes_odd__text%\\}" != "$__silt__trailing_backslashes_odd__text" ]; do
    __silt__trailing_backslashes_odd__text="${__silt__trailing_backslashes_odd__text%\\}"
    __silt__trailing_backslashes_odd__count=$((__silt__trailing_backslashes_odd__count + 1))
  done
  case $((__silt__trailing_backslashes_odd__count % 2)) in
    1) __silt__ODD=true ;;
    *) __silt__ODD=false ;;
  esac
}

: <<'FUN'
Reads a quoted key off the front of <rest>, the text after a line's depth,
into __silt__KEY with its quotes, and leaves what follows the key's closing
quote and colon in __silt__REST. The key ends at the first quote that is not
escaped, which is the first '":' whose quote does not follow an odd run of
backslashes (ADR.4@strata).

  __silt__quoted_key '"a \"b\": c":int=1'  ->  KEY '"a \"b\": c"'  REST 'int=1'

args:
  $1  The line's text from its opening quote
FUN
__silt__quoted_key() {
  __silt__quoted_key__rest="${1#\"}"
  __silt__quoted_key__key='"'
  while :; do
    __silt__quoted_key__head="${__silt__quoted_key__rest%%\":*}"
    if [ "$__silt__quoted_key__head" = "$__silt__quoted_key__rest" ]; then
      __silt__fail "a quoted key never closes: $1"
      return 1
    fi
    __silt__quoted_key__rest="${__silt__quoted_key__rest#*\":}"
    __silt__quoted_key__key="$__silt__quoted_key__key$__silt__quoted_key__head"
    __silt__trailing_backslashes_odd "$__silt__quoted_key__head"
    case "$__silt__ODD" in
      true) __silt__quoted_key__key="$__silt__quoted_key__key\":" ;;
      *) break ;;
    esac
  done
  __silt__KEY="$__silt__quoted_key__key\""
  __silt__REST="$__silt__quoted_key__rest"
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
  case "$1" in
    *.*) ;;
    *)
      __silt__fail "not a SILT line: $1"
      return 1
      ;;
  esac
  __silt__DEPTH="${1%%.*}"
  __silt__REST="${1#*.}"
  case "$__silt__REST" in
    \"*)
      __silt__quoted_key "$__silt__REST" || return 1
      ;;
    *)
      __silt__KEY="${__silt__REST%%:*}"
      __silt__REST="${__silt__REST#*:}"
      ;;
  esac
  case "$__silt__REST" in
    *=*)
      __silt__TYPE="${__silt__REST%%=*}"
      __silt__VALUE="${__silt__REST#*=}"
      __silt__LEAF=true
      ;;
    *)
      __silt__TYPE="$__silt__REST"
      __silt__VALUE=''
      __silt__LEAF=false
      ;;
  esac
}

: <<'FUN'
Appends a line to the document __silt__ANSWER is building, with the newline
that separates lines and none before the first.

args:
  $1  The line
FUN
__silt__emit() {
  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER="$1"
  else
    __silt__ANSWER="$__silt__ANSWER$__silt__NL$1"
  fi
}

: <<'FUN'
Decodes the escape at the front of <rest>, the text just after a backslash,
appending the character to __silt__ANSWER and leaving what follows the
escape in __silt__REST. A \u escape past ASCII costs one subshell, the one
place this library pays for a process, since the shell cannot spell an
arbitrary byte without printf's output.

args:
  $1  The text after the backslash
FUN
__silt__unescape_head() {
  case "$1" in
    \"*) __silt__ANSWER="$__silt__ANSWER\""; __silt__REST="${1#?}" ;;
    \\*) __silt__ANSWER="$__silt__ANSWER\\"; __silt__REST="${1#?}" ;;
    /*) __silt__ANSWER="$__silt__ANSWER/"; __silt__REST="${1#?}" ;;
    n*) __silt__ANSWER="$__silt__ANSWER$__silt__NL"; __silt__REST="${1#?}" ;;
    t*) __silt__ANSWER="$__silt__ANSWER$__silt__TAB"; __silt__REST="${1#?}" ;;
    r*) __silt__ANSWER="$__silt__ANSWER$__silt__CR"; __silt__REST="${1#?}" ;;
    b*) __silt__ANSWER="$__silt__ANSWER$__silt__BS"; __silt__REST="${1#?}" ;;
    f*) __silt__ANSWER="$__silt__ANSWER$__silt__FF"; __silt__REST="${1#?}" ;;
    # structs-lint: allow -- the four hex digits of a JSON \u escape (RFC 8259); SILT sits beneath structs
    u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]*) __silt__unescape_unicode "$1" || return 1 ;;
    *)
      __silt__fail "not a JSON escape: \\$1"
      return 1
      ;;
  esac
}

: <<'FUN'
Decodes a \uXXXX escape, and the low surrogate that follows a high one, to
UTF-8, appending to __silt__ANSWER and leaving the text after the escape in
__silt__REST.

args:
  $1  The text from the u of the escape
FUN
__silt__unescape_unicode() {
  __silt__unescape_unicode__hex="${1#u}"
  __silt__unescape_unicode__hex="${__silt__unescape_unicode__hex%"${__silt__unescape_unicode__hex#????}"}"
  __silt__REST="${1#u????}"
  __silt__unescape_unicode__point=$((0x$__silt__unescape_unicode__hex))
  if [ "$__silt__unescape_unicode__point" -ge 55296 ] && [ "$__silt__unescape_unicode__point" -le 56319 ]; then
    # structs-lint: allow -- a low surrogate's \u escape, DC00 to DFFF (RFC 8259); SILT sits beneath structs
    case "$__silt__REST" in
      \\u[Dd][C-Fc-f][0-9A-Fa-f][0-9A-Fa-f]*)
        __silt__unescape_unicode__low="${__silt__REST#\\u}"
        __silt__unescape_unicode__low="${__silt__unescape_unicode__low%"${__silt__unescape_unicode__low#????}"}"
        __silt__REST="${__silt__REST#\\u????}"
        __silt__unescape_unicode__point=$((65536 + (__silt__unescape_unicode__point - 55296) * 1024 + $((0x$__silt__unescape_unicode__low)) - 56320))
        ;;
    esac
  fi
  __silt__ANSWER="$__silt__ANSWER$(__silt__utf8 "$__silt__unescape_unicode__point")"
}

: <<'FUN'
Prints the UTF-8 bytes of one code point, through printf's octal escapes.

  __silt__utf8 233  ->  é

args:
  $1  The code point, decimal
FUN
__silt__utf8() {
  if [ "$1" -lt 128 ]; then
    __silt__octal "$1"
  elif [ "$1" -lt 2048 ]; then
    __silt__octal $((192 + $1 / 64)) $((128 + $1 % 64))
  elif [ "$1" -lt 65536 ]; then
    __silt__octal $((224 + $1 / 4096)) $((128 + $1 / 64 % 64)) $((128 + $1 % 64))
  else
    __silt__octal $((240 + $1 / 262144)) $((128 + $1 / 4096 % 64)) $((128 + $1 / 64 % 64)) $((128 + $1 % 64))
  fi
}

: <<'FUN'
Prints the bytes given as decimal numbers, each through a printf octal escape.

args:
  $@  The bytes, 0 to 255 each
FUN
__silt__octal() {
  for __silt__octal__byte do
    printf '%b' "\\0$((__silt__octal__byte / 64))$((__silt__octal__byte / 8 % 8))$((__silt__octal__byte % 8))"
  done
}

: <<'PUB_FUN'
Answers the text a JSON string literal spells: the quotes off and every
escape decoded.

  silt__unwrap text '"lib/a.sh"'          ->  text=lib/a.sh
  silt__unwrap text '"a \"b\"\nc"'        ->  text=a "b"<newline>c

args:
  $1  The name of the variable to answer in
  $2  The literal, quotes included
PUB_FUN
silt__unwrap() {
  __silt__out "$1" || return 1
  case "$2" in
    \"*\") ;;
    *)
      __silt__fail "not a string literal: $2"
      return 1
      ;;
  esac
  __silt__unwrap__rest="${2#\"}"
  __silt__unwrap__rest="${__silt__unwrap__rest%\"}"
  __silt__ANSWER=''
  while :; do
    case "$__silt__unwrap__rest" in
      *\\*) ;;
      *) break ;;
    esac
    __silt__ANSWER="$__silt__ANSWER${__silt__unwrap__rest%%\\*}"
    __silt__unescape_head "${__silt__unwrap__rest#*\\}" || return 1
    __silt__unwrap__rest="$__silt__REST"
  done
  __silt__ANSWER="$__silt__ANSWER$__silt__unwrap__rest"
  __silt__answer
}

: <<'PUB_FUN'
Answers the JSON string literal that spells <text>: quoted, with the quote,
the backslash and every control character escaped, the four JSON names by
letter and the rest as \u00XX.

  silt__wrap literal 'a "b"'   ->  literal='"a \"b\""'

args:
  $1  The name of the variable to answer in
  $2  The text
PUB_FUN
silt__wrap() {
  __silt__out "$1" || return 1
  __silt__wrap__rest="$2"
  __silt__ANSWER='"'
  while :; do
    __silt__wrap__head="${__silt__wrap__rest%%[\\\"[:cntrl:]]*}"
    if [ "$__silt__wrap__head" = "$__silt__wrap__rest" ]; then
      break
    fi
    __silt__ANSWER="$__silt__ANSWER$__silt__wrap__head"
    __silt__wrap__rest="${__silt__wrap__rest#"$__silt__wrap__head"}"
    __silt__wrap__char="${__silt__wrap__rest%"${__silt__wrap__rest#?}"}"
    __silt__wrap__rest="${__silt__wrap__rest#?}"
    __silt__escape "$__silt__wrap__char"
  done
  __silt__ANSWER="$__silt__ANSWER$__silt__wrap__rest\""
  __silt__answer
}

: <<'FUN'
Appends the JSON escape of one character to __silt__ANSWER. A control
character outside JSON's four names costs one subshell for its hex.

args:
  $1  The character: a quote, a backslash or a control character
FUN
__silt__escape() {
  case "$1" in
    \") __silt__ANSWER="$__silt__ANSWER\\\"" ;;
    \\) __silt__ANSWER="$__silt__ANSWER\\\\" ;;
    "$__silt__NL") __silt__ANSWER="$__silt__ANSWER\\n" ;;
    "$__silt__TAB") __silt__ANSWER="$__silt__ANSWER\\t" ;;
    "$__silt__CR") __silt__ANSWER="$__silt__ANSWER\\r" ;;
    "$__silt__BS") __silt__ANSWER="$__silt__ANSWER\\b" ;;
    "$__silt__FF") __silt__ANSWER="$__silt__ANSWER\\f" ;;
    *) __silt__ANSWER="$__silt__ANSWER$(printf '\\u%04x' "'$1")" ;;
  esac
}

: <<'PUB_FUN'
Answers what kind of value a document is: map or list from the key of its
first member, else the type of its one keyless line.

  silt__type kind '0."a":int=1'   ->  kind=map
  silt__type kind '0.0:int=1'     ->  kind=list
  silt__type kind '0.:str="x"'    ->  kind=str

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__type() {
  __silt__out "$1" || return 1
  __silt__parse "${2%%"$__silt__NL"*}" || return 1
  case "$__silt__KEY" in
    '') __silt__ANSWER="$__silt__TYPE" ;;
    \"*) __silt__ANSWER=map ;;
    *) __silt__ANSWER=list ;;
  esac
  __silt__answer
}

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
    \"*)
      __silt__quoted_segment "$__silt__PATH" || return 1
      ;;
    \[\"*)
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
__silt__PATH. The key ends at the first quote that does not follow an odd
run of backslashes.

  __silt__quoted_segment '"a\"b".c'   ->  SEGMENT '"a\"b"'  PATH '.c'

args:
  $1  The path from its opening quote
FUN
__silt__quoted_segment() {
  __silt__quoted_segment__rest="${1#\"}"
  __silt__quoted_segment__key='"'
  while :; do
    __silt__quoted_segment__head="${__silt__quoted_segment__rest%%\"*}"
    if [ "$__silt__quoted_segment__head" = "$__silt__quoted_segment__rest" ]; then
      __silt__fail "a quoted path segment never closes: $1"
      return 1
    fi
    __silt__quoted_segment__rest="${__silt__quoted_segment__rest#*\"}"
    __silt__quoted_segment__key="$__silt__quoted_segment__key$__silt__quoted_segment__head"
    __silt__trailing_backslashes_odd "$__silt__quoted_segment__head"
    case "$__silt__ODD" in
      true) __silt__quoted_segment__key="$__silt__quoted_segment__key\"" ;;
      *) break ;;
    esac
  done
  __silt__SEGMENT="$__silt__quoted_segment__key\""
  __silt__PATH="$__silt__quoted_segment__rest"
}

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

: <<'PUB_FUN'
Answers the value text of a scalar document: the JSON literal of a str, the
digits of an int, "true" or "false", and the empty string for a null or an
empty collection.

  silt__scalar text '0.:str="bats"'   ->  text='"bats"'
  silt__scalar text '0.:int=3'        ->  text=3

args:
  $1  The name of the variable to answer in
  $2  The document, one keyless line
PUB_FUN
silt__scalar() {
  __silt__out "$1" || return 1
  case "$2" in
    *"$__silt__NL"*)
      __silt__fail "not a scalar document: $2"
      return 1
      ;;
  esac
  __silt__parse "$2" || return 1
  if [ -n "$__silt__KEY" ]; then
    __silt__fail "not a scalar document: $2"
    return 1
  fi
  __silt__ANSWER="$__silt__VALUE"
  __silt__answer
}

: <<'PUB_FUN'
Answers the text at a path the way jq -r would: a str unquoted, another
scalar as its spelling, a null as "null", and the empty string for a path
nothing holds or a collection.

  silt__string runner "$doc" '.suites.unit.runner'   ->  runner=bats

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path
PUB_FUN
silt__string() {
  __silt__out "$1" || return 1
  __silt__string__out="$__silt__OUT"
  __silt__string__value=''
  silt__get __silt__string__value "$2" "$3" || return 1
  __silt__OUT="$__silt__string__out"
  __silt__ANSWER=''
  case "$__silt__string__value" in
    '' | *"$__silt__NL"*)
      __silt__answer
      return 0
      ;;
  esac
  __silt__parse "$__silt__string__value" || return 1
  case "$__silt__TYPE" in
    str)
      silt__unwrap __silt__ANSWER "$__silt__VALUE" || return 1
      ;;
    null)
      __silt__ANSWER=null
      ;;
    *)
      __silt__ANSWER="$__silt__VALUE"
      ;;
  esac
  __silt__OUT="$__silt__string__out"
  __silt__answer
}

: <<'PUB_FUN'
Answers true when the document holds a value at the path, a null included,
and false otherwise.

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The path
PUB_FUN
silt__has() {
  __silt__out "$1" || return 1
  __silt__has__out="$__silt__OUT"
  __silt__has__value=''
  silt__get __silt__has__value "$2" "$3" || return 1
  __silt__OUT="$__silt__has__out"
  if [ -n "$__silt__has__value" ]; then
    __silt__ANSWER=true
  else
    __silt__ANSWER=false
  fi
  __silt__answer
}

: <<'PUB_FUN'
Answers how many members a map or a list holds, how many characters a str
spells, and 0 for a null.

  silt__len n '0."a":int=1
  0."b":map
  1."c":int=2'   ->  n=2

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__len() {
  __silt__out "$1" || return 1
  __silt__len__out="$__silt__OUT"
  __silt__len__kind=''
  __silt__len__literal=''
  __silt__len__text=''
  silt__type __silt__len__kind "$2" || return 1
  case "$__silt__len__kind" in
    map | list)
      __silt__len__count=0
      __silt__len__ifs="$IFS"
      IFS="$__silt__NL"
      set -f
      # shellcheck disable=SC2086
      set -- $2
      set +f
      IFS="$__silt__len__ifs"
      for __silt__len__line do
        case "$__silt__len__line" in
          0.*) __silt__len__count=$((__silt__len__count + 1)) ;;
        esac
      done
      case "$1" in
        0.:map | 0.:list) __silt__len__count=0 ;;
      esac
      __silt__ANSWER="$__silt__len__count"
      ;;
    str)
      silt__scalar __silt__len__literal "$2" || return 1
      silt__unwrap __silt__len__text "$__silt__len__literal" || return 1
      __silt__ANSWER="${#__silt__len__text}"
      ;;
    null)
      __silt__ANSWER=0
      ;;
    *)
      __silt__fail "a $__silt__len__kind has no length"
      return 1
      ;;
  esac
  __silt__OUT="$__silt__len__out"
  __silt__answer
}

: <<'PUB_FUN'
Answers the members' keys as a list document: a map's as str leaves holding
the key literals in the order they sit, a list's as int leaves.

  silt__keys names '0."b":int=1
  0."a":int=2'   ->  names='0.0:str="b"
  0.1:str="a"'

args:
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__keys() {
  __silt__out "$1" || return 1
  __silt__keys__out="$__silt__OUT"
  __silt__keys__kind=''
  silt__type __silt__keys__kind "$2" || return 1
  case "$__silt__keys__kind" in
    map | list) ;;
    *)
      __silt__fail "a $__silt__keys__kind has no keys"
      return 1
      ;;
  esac
  __silt__ANSWER=''
  __silt__keys__index=0
  __silt__keys__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $2
  set +f
  IFS="$__silt__keys__ifs"
  for __silt__keys__line do
    case "$__silt__keys__line" in
      0.:*) break ;;
      0.*) ;;
      *) continue ;;
    esac
    __silt__parse "$__silt__keys__line" || return 1
    case "$__silt__keys__kind" in
      map) __silt__emit "0.$__silt__keys__index:str=$__silt__KEY" ;;
      *) __silt__emit "0.$__silt__keys__index:int=$__silt__KEY" ;;
    esac
    __silt__keys__index=$((__silt__keys__index + 1))
  done
  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER='0.:list'
  fi
  __silt__OUT="$__silt__keys__out"
  __silt__answer
}

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
      __silt__fail "a $__silt__each__kind has no members"
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
        \"*) silt__unwrap __silt__each__key "$__silt__KEY" || return 1 ;;
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
