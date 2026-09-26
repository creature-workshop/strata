#!/bin/sh

: <<'MODULE'
JSON string literals: unwrap decodes one to text and wrap encodes text to one, every escape included.
MODULE

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
    '"'*) __silt__ANSWER="$__silt__ANSWER\""; __silt__REST="${1#?}" ;;
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
    '"'*'"') ;;
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
