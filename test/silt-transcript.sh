#!/bin/sh
# Writes the transcript of one golden fileset for test/silt-goldens.bats:
# every call in the .calls file under a "## " line, its answer below it, and
# "!! <status> <message>" when the verb refuses. POSIX sh, so the same goldens
# are checked under every shell the bats file names.
#
# Usage: <shell> test/silt-transcript.sh <api.sh> <calls> [<document>]
#
# A call is a verb and one argument; a blank line or a # line is skipped.
# type, scalar, len and keys take the document; get, string and has take it
# and a path; unwrap takes the literal; wrap and roundtrip take text read
# through printf %b, so a line can spell a newline or a control character;
# each takes an extra argument for its callback, and each-until the key at
# which the callback returns 3.

set -u

main() {
  require_usage "$@"
  load_library "$1"
  DOCUMENT="$(read_document "${3:-}")"
  STDERR="${TMPDIR:-/tmp}/silt-transcript.$$"
  trap 'rm -f "$STDERR"' EXIT

  transcribe_calls < "$2"
}

# The library and the calls are required; the document is not.
require_usage() {
  if [ "$#" -lt 2 ]; then
    printf 'usage: silt-transcript.sh <api.sh> <calls> [<document>]\n' >&2
    exit 2
  fi
}

# Sources the reader, telling it where it lives for the shells that cannot tell.
load_library() {
  export SILT_DIR="${1%/*}"
  . "$1"
}

# The document's text, or nothing when no file was named.
read_document() {
  if [ -n "$1" ]; then
    cat "$1"
  fi
}

# One transcript block per call on stdin.
transcribe_calls() {
  while IFS= read -r __transcribe_calls__line; do
    case "$__transcribe_calls__line" in
      '' | '#'*) continue ;;
    esac
    transcribe_call "$__transcribe_calls__line"
  done
}

# The call's line, then what the verb answered or why it refused.
transcribe_call() {
  ANSWER=''
  STATUS=0

  printf '## %s\n' "$1"
  run_verb "${1%% *}" "$(argument_of "$1")"
  report_answer
}

# The text after the verb and one space, or nothing.
argument_of() {
  __argument_of__rest="${1#"${1%% *}"}"
  printf '%s' "${__argument_of__rest# }"
}

# Dispatches a verb to the reader, with the document where the verb takes one.
run_verb() {
  case "$1" in
    type | scalar | len | keys) capture "silt__$1" ANSWER "$DOCUMENT" ;;
    get | string | has) capture "silt__$1" ANSWER "$DOCUMENT" "$2" ;;
    unwrap) capture silt__unwrap ANSWER "$2" ;;
    wrap) capture silt__wrap ANSWER "$(unescape "$2")" ;;
    roundtrip) roundtrip "$(unescape "$2")" ;;
    each) capture silt__each note "$DOCUMENT" "$2" ;;
    each-until) capture silt__each until_key "$DOCUMENT" "$2" ;;
    *) STATUS=127 ;;
  esac
}

# Runs a command, keeping its status in STATUS and its stderr in the scratch file.
capture() {
  "$@" 2>"$STDERR" || STATUS=$?
}

# Text spelled with printf escapes, as the characters it means.
unescape() {
  printf '%b' "$1"
}

# wrap then unwrap: the literal, then whether the text came back unchanged.
roundtrip() {
  capture silt__wrap LITERAL "$1"
  capture silt__unwrap BACK "$LITERAL"
  ANSWER="$LITERAL$__silt__NL$(identity_of "$1" "$BACK")"
}

# Whether two texts are the same, as a line of the transcript.
identity_of() {
  if [ "$1" = "$2" ]; then
    printf 'identity: true'
  else
    printf 'identity: false'
  fi
}

# The answer, and after a refusal its status and message.
report_answer() {
  if [ "$STATUS" -eq 0 ]; then
    printf '%s\n' "$ANSWER"
    return
  fi

  if [ -n "$ANSWER" ]; then
    printf '%s\n' "$ANSWER"
  fi
  printf '!! %s %s\n' "$STATUS" "$(cat "$STDERR")"
}

# each's callback: the key, the extra argument when one came, and the value.
note() {
  ANSWER="$ANSWER${ANSWER:+$__silt__NL}$1${3:+ $3}: $2"
}

# each's callback that stops the walk with status 3 at the key given.
until_key() {
  ANSWER="$ANSWER${ANSWER:+$__silt__NL}$1"
  [ "$1" != "$3" ] || return 3
}

main "$@"
