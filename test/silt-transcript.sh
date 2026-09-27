#!/bin/sh
# Writes the transcript of one golden fileset for test/silt-goldens.bats:
# every call in the calls file under a "## " line, its answer below it, and
# "!! <status> <message>" when the verb refuses. POSIX sh, so the same goldens
# are checked under every shell the bats file names. Its functions carry the
# transcript__ prefix because it sources the library into its own shell.
#
# Usage: <shell> test/silt-transcript.sh <api.sh> <calls> [<document>]
#
# A call is a verb and one argument; a blank line or a # line is skipped.
# type, scalar, len, keys, canon, unique, is_true, is_false, is_zero,
# to_json, to_yaml and to_toml take the document; get, string, has and pluck
# take it and a path; string-or takes a default word, then the path;
# from_json, from_yaml, from_toml and from_strh take a file, beside the calls
# file unless absolute, and read it on stdin, and from_strt such a file and
# then the register holding the corpus's keys; unwrap takes the literal; wrap
# and transcript__roundtrip take text read through printf %b, so a line can
# spell a newline or a control character; each takes an extra argument for
# its callback, each-until the key at which the callback returns 3, and
# each-string a path its callback reads. map, filter, find, any and all take
# the name of one of the callbacks below, without its prefix, and the extras
# after it; project takes its keys. A call written "as <name> <call>" keeps
# its answer in a register, "@<name>" in place of the document makes a call
# read that register, and a writer's words may name one as "$<name>": obj,
# arr and split take their words alone; push, set, concat, join, equals,
# merge, difference, intersect, validate, to_strh and to_strt take the
# document first;
# str and time take the rest of the line as their text. now takes no
# argument, and its result is printed with every digit replaced by 9,
# because the current time is different on every run.

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
    obj | arr | push | set | concat | join | split | equals | merge | difference | intersect | validate | to_strh | to_strt) transcript__run_writer "${1%% *}" $__transcript__run_call__rest ;;
    map | filter | find | any | all | project) transcript__run_collection "${1%% *}" $__transcript__run_call__rest ;;
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

# Runs a verb over each on its words: project on its keys, the others on the
# callback named by its first word, one of this script's, and the extras after it.
transcript__run_collection() {
  __transcript__run_collection__verb="$1"
  shift

  case "$__transcript__run_collection__verb" in
    project) transcript__capture silt__project ANSWER "$DOCUMENT_FOR_CALL" "$@" ;;
    *) transcript__run_with_callback "$__transcript__run_collection__verb" "$@" ;;
  esac
}

# Runs a verb over each with one of this script's callbacks and the extras given.
transcript__run_with_callback() {
  __transcript__run_with_callback__verb="$1"
  __transcript__run_with_callback__callback="transcript__$2"
  shift 2

  transcript__capture "silt__$__transcript__run_with_callback__verb" ANSWER "$DOCUMENT_FOR_CALL" "$__transcript__run_with_callback__callback" "$@"
}

# Dispatches a reader verb, with the document where the verb takes one.
transcript__run_verb() {
  case "$1" in
    type | scalar | len | keys | canon | unique | is_true | is_false | is_zero | to_json | to_yaml | to_toml) transcript__capture "silt__$1" ANSWER "$DOCUMENT_FOR_CALL" ;;
    get | string | has | pluck) transcript__capture "silt__$1" ANSWER "$DOCUMENT_FOR_CALL" "$2" ;;
    string-or) transcript__capture silt__string ANSWER "$DOCUMENT_FOR_CALL" "$(transcript__argument_of "$2")" "$(transcript__unescape "${2%% *}")" ;;
    from_json | from_yaml | from_toml | from_strh) transcript__capture "silt__$1" ANSWER < "$(transcript__file_of "$2")" ;;
    from_strt) transcript__capture silt__from_strt ANSWER "$(transcript__register_of "${2#* }")" < "$(transcript__file_of "${2%% *}")" ;;
    unwrap) transcript__capture silt__unwrap ANSWER "$2" ;;
    wrap) transcript__capture silt__wrap ANSWER "$(transcript__unescape "$2")" ;;
    str) transcript__capture silt__str ANSWER "$(transcript__unescape "$2")" ;;
    time) transcript__capture silt__time ANSWER "$2" ;;
    now) transcript__now ;;
    roundtrip) transcript__roundtrip "$(transcript__unescape "$2")" ;;
    each) transcript__capture silt__each transcript__note "$DOCUMENT_FOR_CALL" "$2" ;;
    each-until) transcript__capture silt__each transcript__until_key "$DOCUMENT_FOR_CALL" "$2" ;;
    each-string) transcript__capture silt__each transcript__note_string "$DOCUMENT_FOR_CALL" "$2" ;;
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

# Runs silt__now. If the result is a correctly formatted time, replaces
# every digit with 9 so the transcript is the same on every run. Any other
# result is left unchanged, so a badly formatted time shows up as a failure.
transcript__now() {
  transcript__capture silt__now ANSWER
  case "$ANSWER" in
    0.:time-rfc3339-utc=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]Z)
      ANSWER='0.:time-rfc3339-utc=9999-99-99T99:99:99.999999999Z'
      ;;
  esac
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

# each's callback that notes the key and the text at the path in the member.
transcript__note_string() {
  silt__string TEXT "$2" "$3" || return 1
  ANSWER="$ANSWER${ANSWER:+$__silt__NL}$1: $TEXT"
}

# Assigns an answer to the variable a callback was told to answer in.
transcript__answer() {
  eval "$1=\$2"
}

# A callback for map: the member's key as a str document.
transcript__str_of_key() {
  silt__str "$1" "$2"
}

# A callback for map: the value at the path in the member, nothing when the
# member holds none there.
transcript__value_at() {
  silt__get "$1" "$3" "$4"
}

# A callback for map: the member's length as an int document.
transcript__len_as_int() {
  silt__len LENGTH "$3" || return 1
  transcript__answer "$1" "0.:int=$LENGTH"
}

# A predicate: whether the member holds a value at the path.
transcript__has_at() {
  silt__has "$1" "$3" "$4"
}

# Answers true in the variable named when two texts are the same, false otherwise.
transcript__answer_whether() {
  if [ "$2" = "$3" ]; then
    transcript__answer "$1" true
  else
    transcript__answer "$1" false
  fi
}

# A predicate: whether the text at the path in the member is the text given.
transcript__string_is() {
  silt__string TEXT "$3" "$4" || return 1
  transcript__answer_whether "$1" "$TEXT" "$5"
}

# A predicate: whether the member is a list.
transcript__is_list() {
  silt__type KIND "$3" || return 1
  transcript__answer_whether "$1" "$KIND" list
}

# A predicate that answers the word given, whatever the member.
transcript__says() {
  transcript__answer "$1" "$4"
}

# A callback that fails with status 7, whatever the member.
transcript__fails() {
  return 7
}

main "$@"
