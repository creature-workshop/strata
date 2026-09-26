#!/bin/sh

: <<'MODULE'
JSON string literals: unwrap decodes one to text and wrap encodes text to
one, every escape included.
MODULE

: <<'FUN'
Decodes the escape at the front of <rest>, the text just after a backslash,
appending the character to __silt__ANSWER and leaving what follows the
escape in __silt__REST.

args:
  $1  The text after the backslash
FUN
__silt__unescape_head() {
  case "$1" in
    "$__silt__QUOTE"*) __silt__unescape_one "$__silt__QUOTE" "$1" ;;
    "$__silt__BACKSLASH"*) __silt__unescape_one "$__silt__BACKSLASH" "$1" ;;
    /*) __silt__unescape_one / "$1" ;;
    n*) __silt__unescape_one "$__silt__NL" "$1" ;;
    t*) __silt__unescape_one "$__silt__TAB" "$1" ;;
    r*) __silt__unescape_one "$__silt__CR" "$1" ;;
    b*) __silt__unescape_one "$__silt__BS" "$1" ;;
    f*) __silt__unescape_one "$__silt__FF" "$1" ;;
    # structs-lint: allow -- the four hex digits of a JSON \u escape (RFC 8259); SILT sits beneath structs
    u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]*) __silt__unescape_unicode "$1" || return 1 ;;
    *) __silt__unescape_refuse "$1" ;;
  esac
}

: <<'FUN'
Decodes a one-letter escape: appends the character it stands for to
__silt__ANSWER and leaves the text after the letter in __silt__REST.

args:
  $1  The character the escape stands for
  $2  The text from the escape's letter
FUN
__silt__unescape_one() {
  __silt__ANSWER="$__silt__ANSWER$1"
  __silt__REST="${2#?}"
}

: <<'FUN'
Refuses an escape JSON does not have.

args:
  $1  The text after the backslash
FUN
__silt__unescape_refuse() {
  __silt__fail "not a JSON escape: $__silt__BACKSLASH$1"
  return 1
}

: <<'FUN'
Decodes a \uXXXX escape, and the low surrogate that follows a high one, to
UTF-8, appending to __silt__ANSWER and leaving the text after the escape in
__silt__REST. This costs one subshell, the one place the library pays for a
process, since the shell cannot spell an arbitrary byte without printf.

args:
  $1  The text from the u of the escape
FUN
__silt__unescape_unicode() {
  __silt__unescape_unicode__hex="${1#u}"
  __silt__unescape_unicode__hex="${__silt__unescape_unicode__hex%"${__silt__unescape_unicode__hex#????}"}"
  __silt__REST="${1#u????}"
  __silt__POINT=$((0x$__silt__unescape_unicode__hex))

  if [ "$__silt__POINT" -ge 55296 ] && [ "$__silt__POINT" -le 56319 ]; then
    __silt__unescape_low_surrogate
  fi

  __silt__ANSWER="$__silt__ANSWER$(__silt__utf8 "$__silt__POINT")"
}

: <<'FUN'
Joins the low surrogate at the front of __silt__REST, when one is there, to
the high surrogate in __silt__POINT, leaving the text after it in
__silt__REST. A high surrogate with no low one after it stays as it is.
FUN
__silt__unescape_low_surrogate() {
  case "$__silt__REST" in
    # structs-lint: allow -- a low surrogate's \u escape, DC00 to DFFF (RFC 8259); SILT sits beneath structs
    \\u[Dd][C-Fc-f][0-9A-Fa-f][0-9A-Fa-f]*) ;;
    *) return 0 ;;
  esac

  __silt__unescape_low_surrogate__low="${__silt__REST#??}"
  __silt__unescape_low_surrogate__low="${__silt__unescape_low_surrogate__low%"${__silt__unescape_low_surrogate__low#????}"}"
  __silt__REST="${__silt__REST#??????}"

  __silt__POINT=$((65536 + (__silt__POINT - 55296) * 1024 + $((0x$__silt__unescape_low_surrogate__low)) - 56320))
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
    "$__silt__QUOTE"*"$__silt__QUOTE") ;;
    *)
      __silt__fail "not a string literal: $2"
      return 1
      ;;
  esac

  __silt__unwrap__rest="${2#"$__silt__QUOTE"}"
  __silt__unwrap__rest="${__silt__unwrap__rest%"$__silt__QUOTE"}"
  __silt__ANSWER=''

  while :; do
    case "$__silt__unwrap__rest" in
      *"$__silt__BACKSLASH"*) ;;
      *) break ;;
    esac

    __silt__ANSWER="$__silt__ANSWER${__silt__unwrap__rest%%"$__silt__BACKSLASH"*}"
    __silt__unescape_head "${__silt__unwrap__rest#*"$__silt__BACKSLASH"}" || return 1
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
  __silt__wrap_literal "$2"
  __silt__ANSWER="$__silt__LITERAL"
  __silt__answer
}

: <<'FUN'
Builds in __silt__LITERAL the JSON string literal that spells <text>, for
silt__wrap and for the writers, which spell keys and parts while a document
of their own is building in __silt__ANSWER.

args:
  $1  The text
FUN
__silt__wrap_literal() {
  __silt__wrap_literal__rest="$1"
  __silt__LITERAL="$__silt__QUOTE"

  while :; do
    __silt__wrap_literal__head="${__silt__wrap_literal__rest%%[\\\"[:cntrl:]]*}"

    if [ "$__silt__wrap_literal__head" = "$__silt__wrap_literal__rest" ]; then
      break
    fi

    __silt__LITERAL="$__silt__LITERAL$__silt__wrap_literal__head"
    __silt__wrap_literal__rest="${__silt__wrap_literal__rest#"$__silt__wrap_literal__head"}"

    __silt__wrap_literal__char="${__silt__wrap_literal__rest%"${__silt__wrap_literal__rest#?}"}"
    __silt__wrap_literal__rest="${__silt__wrap_literal__rest#?}"
    __silt__escape "$__silt__wrap_literal__char"
  done

  __silt__LITERAL="$__silt__LITERAL$__silt__wrap_literal__rest$__silt__QUOTE"
}

: <<'FUN'
Appends the JSON escape of one character to __silt__LITERAL.

args:
  $1  The character: a quote, a backslash or a control character
FUN
__silt__escape() {
  case "$1" in
    "$__silt__QUOTE") __silt__escape_as "$__silt__QUOTE" ;;
    "$__silt__BACKSLASH") __silt__escape_as "$__silt__BACKSLASH" ;;
    "$__silt__NL") __silt__escape_as n ;;
    "$__silt__TAB") __silt__escape_as t ;;
    "$__silt__CR") __silt__escape_as r ;;
    "$__silt__BS") __silt__escape_as b ;;
    "$__silt__FF") __silt__escape_as f ;;
    *) __silt__escape_hex "$1" ;;
  esac
}

: <<'FUN'
Appends a backslash and the letter or character JSON names an escape by.

args:
  $1  The letter or character after the backslash
FUN
__silt__escape_as() {
  __silt__LITERAL="$__silt__LITERAL$__silt__BACKSLASH$1"
}

: <<'FUN'
Appends the \u00XX escape of a control character JSON has no letter for.
This costs one subshell for the hex.

args:
  $1  The character
FUN
__silt__escape_hex() {
  __silt__LITERAL="$__silt__LITERAL$(printf '\\u%04x' "'$1")"
}
