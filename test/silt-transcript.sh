#!/bin/sh
# Writes the transcript of one golden fileset for test/silt-goldens.bats:
# every call in the .calls file under a "## " line, its answer below it, and
# "!! <status> <message>" when the verb refuses. POSIX sh, so the same goldens
# are checked under every shell the bats file names. Its functions carry the
# transcript__ prefix because it sources the library into its own shell.
#
# Usage: <shell> test/silt-transcript.sh <api.sh> <calls> [<document>]
#
# A call is a verb and one argument; a blank line or a # line is skipped.
# type, scalar, len, keys, canon, to_json, to_yaml and to_toml take the
# document; get, string and has take it and a path; from_json, from_yaml and
# from_toml take a file, beside the calls file unless absolute, and read it
# on stdin; unwrap takes the literal; wrap and transcript__roundtrip take
# text read through printf %b, so a line can spell a newline or a control
# character; each takes an extra argument for its callback, and each-until
# the key at which the callback returns 3. A call written "as <name> <call>"
# keeps its answer in a register, "@<name>" in place of the document makes a
# call read that register, and a writer's words may name one as "$<name>":
# obj, arr and split take their words alone; push, set, concat, join and
# equals take the document first; str takes the rest of the line as its text.

set -u

main() {
  transcript__require_usage "$@"
  transcript__load_library "$1"
  CALLS_DIR="${2%/*}"
  DOCUMENT="$(transcript__read_document "${3:-}")"
  STDERR="${TMPDIR:-/tmp}/silt-transcript.$$"
  trap 'rm -f "$STDERR"' EXIT

  transcript__transcribe_calls < "$2"
}

# The library and the calls are required; the document is not.
transcript__require_usage() {
  if [ "$#" -lt 2 ]; then
    printf 'usage: silt-transcript.sh <api.sh> <calls> [<document>]\n' >&2
    exit 2
  fi
}

# Sources the reader, telling it where it lives for the shells that cannot tell.
transcript__load_library() {
  export SILT_DIR="${1%/*}"
  . "$1"
}

# The document's text, or nothing when no file was named.
transcript__read_document() {
  if [ -n "$1" ]; then
    cat "$1"
  fi
}

# One transcript block per call on stdin.
transcript__transcribe_calls() {
  while IFS= read -r __transcript__transcribe_calls__line; do
    case "$__transcript__transcribe_calls__line" in
      '' | '#'*) continue ;;
    esac
    transcript__transcribe_call "$__transcript__transcribe_calls__line"
  done
}

# The call's line, then what the verb answered or why it refused. A line
# "as <name> <call>" also keeps the answer in the register <name>.
transcript__transcribe_call() {
  ANSWER=''
  STATUS=0
  printf '## %s\n' "$1"

  case "${1%% *}" in
    as) transcript__keep_answer "$(transcript__argument_of "$1")" ;;
    *) transcript__run_call "$1" ;;
  esac

  transcript__report_answer
}

# Runs the call after the register's name and keeps the answer under it.
transcript__keep_answer() {
  transcript__run_call "$(transcript__argument_of "$1")"
  eval "REGISTER_${1%% *}=\$ANSWER"
}

# The text after the first word and one space, or nothing.
transcript__argument_of() {
  __transcript__argument_of__rest="${1#"${1%% *}"}"
  printf '%s' "${__transcript__argument_of__rest# }"
}

# Runs one call: its verb on the document it names, "@<register>" first or
# the fileset's, with the rest of the line as its argument. A writer's
# arguments are words, and a word "$<register>" is that register's document.
transcript__run_call() {
  DOCUMENT_FOR_CALL="$DOCUMENT"
  __transcript__run_call__rest="$(transcript__argument_of "$1")"

  case "$__transcript__run_call__rest" in
    @*)
      DOCUMENT_FOR_CALL="$(transcript__register_of "${__transcript__run_call__rest%% *}")"
      __transcript__run_call__rest="$(transcript__argument_of "$__transcript__run_call__rest")"
      ;;
  esac

  # shellcheck disable=SC2086  # a writer's words are split on purpose
  case "${1%% *}" in
    obj | arr | push | set | concat | join | split | equals) transcript__run_writer "${1%% *}" $__transcript__run_call__rest ;;
    *) transcript__run_verb "${1%% *}" "$__transcript__run_call__rest" ;;
  esac
}

# The document a register holds, named with or without its @ or $.
transcript__register_of() {
  __transcript__register_of__name="${1#[@\$]}"
  eval "printf '%s' \"\$REGISTER_$__transcript__register_of__name\""
}

# Runs a writer on its words, each "$<register>" word replaced by the
# document it names, and every word read through printf %b, so a line can
# spell a newline or a control character.
transcript__run_writer() {
  __transcript__run_writer__verb="$1"
  shift

  __transcript__run_writer__count=$#
  while [ "$__transcript__run_writer__count" -gt 0 ]; do
    __transcript__run_writer__word="$1"
    shift
    case "$__transcript__run_writer__word" in
      \$*) set -- "$@" "$(transcript__register_of "$__transcript__run_writer__word")" ;;
      *) set -- "$@" "$(transcript__unescape "$__transcript__run_writer__word")" ;;
    esac
    __transcript__run_writer__count=$((__transcript__run_writer__count - 1))
  done

  case "$__transcript__run_writer__verb" in
    obj | arr | split) transcript__capture "silt__$__transcript__run_writer__verb" ANSWER "$@" ;;
    *) transcript__capture "silt__$__transcript__run_writer__verb" ANSWER "$DOCUMENT_FOR_CALL" "$@" ;;
  esac
}

# Dispatches a reader verb, with the document where the verb takes one.
transcript__run_verb() {
  case "$1" in
    type | scalar | len | keys | canon | to_json | to_yaml | to_toml) transcript__capture "silt__$1" ANSWER "$DOCUMENT_FOR_CALL" ;;
    get | string | has) transcript__capture "silt__$1" ANSWER "$DOCUMENT_FOR_CALL" "$2" ;;
    from_json | from_yaml | from_toml) transcript__capture "silt__$1" ANSWER < "$(transcript__file_of "$2")" ;;
    unwrap) transcript__capture silt__unwrap ANSWER "$2" ;;
    wrap) transcript__capture silt__wrap ANSWER "$(transcript__unescape "$2")" ;;
    str) transcript__capture silt__str ANSWER "$(transcript__unescape "$2")" ;;
    roundtrip) transcript__roundtrip "$(transcript__unescape "$2")" ;;
    each) transcript__capture silt__each transcript__note "$DOCUMENT_FOR_CALL" "$2" ;;
    each-until) transcript__capture silt__each transcript__until_key "$DOCUMENT_FOR_CALL" "$2" ;;
    *) STATUS=127 ;;
  esac
}

# A file a call reads by name: as given when absolute, else beside the calls file.
transcript__file_of() {
  case "$1" in
    /*) printf '%s' "$1" ;;
    *) printf '%s/%s' "$CALLS_DIR" "$1" ;;
  esac
}

# Runs a command, keeping its status in STATUS and its stderr in the scratch file.
transcript__capture() {
  "$@" 2>"$STDERR" || STATUS=$?
}

# Text spelled with printf escapes, as the characters it means.
transcript__unescape() {
  printf '%b' "$1"
}

# wrap then unwrap: the literal, then whether the text came back unchanged.
transcript__roundtrip() {
  transcript__capture silt__wrap LITERAL "$1"
  transcript__capture silt__unwrap BACK "$LITERAL"
  ANSWER="$LITERAL$__silt__NL$(transcript__identity_of "$1" "$BACK")"
}

# Whether two texts are the same, as a line of the transcript.
transcript__identity_of() {
  if [ "$1" = "$2" ]; then
    printf 'identity: true'
  else
    printf 'identity: false'
  fi
}

# The answer, and after a refusal its status and message.
transcript__report_answer() {
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
transcript__note() {
  ANSWER="$ANSWER${ANSWER:+$__silt__NL}$1${3:+ $3}: $2"
}

# each's callback that stops the walk with status 3 at the key given.
transcript__until_key() {
  ANSWER="$ANSWER${ANSWER:+$__silt__NL}$1"
  [ "$1" != "$3" ] || return 3
}

main "$@"
