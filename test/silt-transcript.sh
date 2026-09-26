#!/bin/sh
# The transcript of one golden fixture for test/silt-reader.bats: every call
# in the .calls file under a "## " line, its answer below it, and "!! <status>
# <message>" when the verb refuses. Written in POSIX sh so the same goldens are
# checked under every shell the bats case names.
#
# Usage: <shell> test/silt-transcript.sh <api.sh> <calls> [<document>]
#
# A call is a verb and one argument. type, scalar, len and keys take the
# document; get, string and has take it and a path; unwrap takes the literal;
# wrap and roundtrip take text read through printf %b, so a line can spell a
# newline or a control character; each takes an extra argument for its
# callback, and each-until the key at which the callback returns 3.

set -u

main() {
  . "$1"
  DOC=''
  if [ -n "${3:-}" ]; then
    DOC="$(cat "$3")"
  fi
  STDERR="${TMPDIR:-/tmp}/silt-transcript.$$"
  trap 'rm -f "$STDERR"' EXIT
  while IFS= read -r __main__line; do
    __main__verb="${__main__line%% *}"
    __main__argument="${__main__line#"$__main__verb"}"
    printf '## %s\n' "$__main__line"
    transcribe "$__main__verb" "${__main__argument# }"
  done < "$2"
}

# Runs one call and reports it.
transcribe() {
  got=''
  status=0
  case "$1" in
    type | scalar | len | keys) "silt__$1" got "$DOC" 2>"$STDERR" || status=$? ;;
    get | string | has) "silt__$1" got "$DOC" "$2" 2>"$STDERR" || status=$? ;;
    unwrap) silt__unwrap got "$2" 2>"$STDERR" || status=$? ;;
    wrap) wrap_text "$2" ;;
    roundtrip) roundtrip_text "$2" ;;
    each) silt__each note "$DOC" "$2" 2>"$STDERR" || status=$? ;;
    each-until) silt__each until_key "$DOC" "$2" 2>"$STDERR" || status=$? ;;
    *) status=127 ;;
  esac
  report
}

# The answer, then the refusal's status and message when there is one.
report() {
  if [ "$status" -eq 0 ]; then
    printf '%s\n' "$got"
    return
  fi
  if [ -n "$got" ]; then
    printf '%s\n' "$got"
  fi
  printf '!! %s %s\n' "$status" "$(cat "$STDERR" 2>/dev/null)"
}

# wrap over text spelled with printf escapes.
wrap_text() {
  __wrap_text__text="$(printf '%b' "$1")"
  silt__wrap got "$__wrap_text__text" 2>"$STDERR" || status=$?
}

# wrap then unwrap over text spelled with printf escapes: the literal, then
# whether the text came back unchanged.
roundtrip_text() {
  __roundtrip_text__text="$(printf '%b' "$1")"
  silt__wrap __roundtrip_text__literal "$__roundtrip_text__text" 2>"$STDERR" || status=$?
  silt__unwrap __roundtrip_text__back "$__roundtrip_text__literal" 2>"$STDERR" || status=$?
  got="$__roundtrip_text__literal"
  if [ "$__roundtrip_text__back" = "$__roundtrip_text__text" ]; then
    got="$got${__silt__NL}identity: true"
  else
    got="$got${__silt__NL}identity: false"
  fi
}

# each's callback: the key, the extra argument when one came, and the value.
note() {
  got="$got${got:+$__silt__NL}$1${3:+ $3}: $2"
}

# each's callback that stops the walk with status 3 at the key given.
until_key() {
  got="$got${got:+$__silt__NL}$1"
  [ "$1" != "$3" ] || return 3
}

main "$@"
