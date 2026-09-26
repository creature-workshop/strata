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
# which the callback returns 3. A call written "as <name> <call>" keeps its
# answer in a register, "@<name>" in place of the document makes a call read
# that register, and a writer's words may name one as "$<name>": obj, arr,
# split and collect take their words alone; push, set, concat and join take
# the document first; str takes the rest of the line as its text.

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

# The call's line, then what the verb answered or why it refused. A line
# "as <name> <call>" also keeps the answer in the register <name>.
transcribe_call() {
  ANSWER=''
  STATUS=0
  printf '## %s\n' "$1"

  case "${1%% *}" in
    as) keep_answer "$(argument_of "$1")" ;;
    *) run_call "$1" ;;
  esac

  report_answer
}

# Runs the call after the register's name and keeps the answer under it.
keep_answer() {
  run_call "$(argument_of "$1")"
  eval "REGISTER_${1%% *}=\$ANSWER"
}

# The text after the first word and one space, or nothing.
argument_of() {
  __argument_of__rest="${1#"${1%% *}"}"
  printf '%s' "${__argument_of__rest# }"
}

# Runs one call: its verb on the document it names, "@<register>" first or
# the fileset's, with the rest of the line as its argument. A writer's
# arguments are words, and a word "$<register>" is that register's document.
run_call() {
  DOCUMENT_FOR_CALL="$DOCUMENT"
  __run_call__rest="$(argument_of "$1")"

  case "$__run_call__rest" in
    @*)
      DOCUMENT_FOR_CALL="$(register_of "${__run_call__rest%% *}")"
      __run_call__rest="$(argument_of "$__run_call__rest")"
      ;;
  esac

  # shellcheck disable=SC2086  # a writer's words are split on purpose
  case "${1%% *}" in
    obj | arr | push | set | concat | join | split | collect) run_writer "${1%% *}" $__run_call__rest ;;
    *) run_verb "${1%% *}" "$__run_call__rest" ;;
  esac
}

# The document a register holds, named with or without its @ or $.
register_of() {
  __register_of__name="${1#[@\$]}"
  eval "printf '%s' \"\$REGISTER_$__register_of__name\""
}

# Runs a writer on its words, each "$<register>" word replaced by the
# document it names, and the words of split and collect read through
# printf %b, so a line can spell a newline or the record separator.
run_writer() {
  __run_writer__verb="$1"
  shift

  __run_writer__count=$#
  while [ "$__run_writer__count" -gt 0 ]; do
    __run_writer__word="$1"
    shift
    case "$__run_writer__word" in
      \$*) set -- "$@" "$(register_of "$__run_writer__word")" ;;
      *) set -- "$@" "$(unescape "$__run_writer__word")" ;;
    esac
    __run_writer__count=$((__run_writer__count - 1))
  done

  case "$__run_writer__verb" in
    obj | arr | split | collect) capture "silt__$__run_writer__verb" ANSWER "$@" ;;
    *) capture "silt__$__run_writer__verb" ANSWER "$DOCUMENT_FOR_CALL" "$@" ;;
  esac
}

# Dispatches a reader verb, with the document where the verb takes one.
run_verb() {
  case "$1" in
    type | scalar | len | keys) capture "silt__$1" ANSWER "$DOCUMENT_FOR_CALL" ;;
    get | string | has) capture "silt__$1" ANSWER "$DOCUMENT_FOR_CALL" "$2" ;;
    unwrap) capture silt__unwrap ANSWER "$2" ;;
    wrap) capture silt__wrap ANSWER "$(unescape "$2")" ;;
    str) capture silt__str ANSWER "$(unescape "$2")" ;;
    roundtrip) roundtrip "$(unescape "$2")" ;;
    each) capture silt__each note "$DOCUMENT_FOR_CALL" "$2" ;;
    each-until) capture silt__each until_key "$DOCUMENT_FOR_CALL" "$2" ;;
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
