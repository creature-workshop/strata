#!/bin/sh
# Writes the transcript of one golden fileset for test/silt-goldens.bats
# through the driver of shell-goldens, shell/.golden: every call in the calls
# file under a "## " line, its answer below it, and "!! <status> <message>"
# when the verb refuses. This script supplies the hook that runs one call,
# the SILT verbs it dispatches to, and the callbacks they take. POSIX sh, so
# the same goldens are checked under every shell the bats file names. Its
# functions carry the transcript__ prefix because it sources the library
# into its own shell.
#
# Usage: <shell> test/silt-transcript.sh <api.sh> <calls> [<document>]
#
# A call is a verb and one argument; a blank line or a # line is skipped.
# type takes the document and, when given, a path; defined, empty and not
# take the document, and defined-word, empty-word and not-word take the
# rest of the line as the value, which can be nothing; bool takes a word
# and null takes nothing; option and option_is take the map of options, a
# key and a text, and option-bare the map and a key; succeeds and fails
# take a command, and succeeds-reading and fails-reading take one word for
# the command to read on stdin and then the command.
# scalar, len, keys, canon, unique, is_true, is_false, is_zero, references,
# to_json, to_yaml, to_toml, dump, dump-<format>, which sets SILT_DUMP, first, last, sum, values, entries and
# from_entries take the document; sort_by, group_by, min and max take it and
# then paths, or none; run takes an awk program, a file beside the calls
# file, and then the words of its options, a library after --load beside
# the calls file too, and run-bare takes the program and no document; pop and shift take it and answer the element and the rest, and
# pop-rest and shift-rest answer the rest alone, and pop-element and
# shift-element call the verb without a variable for the rest;
# take and take_last take it and a count; slice takes it and two indices; line takes it and answers
# whether to_line wrote it on one line and from_line read it back; to_line
# and from_line take the document; read takes text read through printf %b,
# and read-register the text a register holds; get, string, has and pluck
# take the document and a path; load takes a JSON file and a schema file, each beside the calls
# file unless absolute; pick and without take the document and keys; string-or takes a default word, then the path;
# get-first and string-first take the document and then words: paths, and
# --default with its value;
# from_json, from_yaml, from_toml and from_strh take a file, beside the calls
# file unless absolute, and read it on stdin, and from_strt such a file and
# then the register holding the corpus's keys; unwrap takes the literal; wrap
# and transcript__roundtrip take text read through printf %b, so a line can
# spell a newline or a control character; each takes an extra argument for
# its callback, each-until the key at which the callback returns 3,
# each-string a path its callback reads, and each-nested nothing: its
# callback runs each again on every member that is a map or a list. map, filter, find, any and all take
# the name of one of the callbacks below, without its prefix, or one of the
# library's predicates by its full name, silt__text_is among them, and the extras
# after it, and reduce takes the same, with --from and a document among the
# extras; apply takes the list and the words of a command; project takes its keys. A call written "as <name> <call>" keeps
# its answer in a register, "@<name>" in place of the document makes a call
# read that register, and a writer's words may name one as "$<name>": obj,
# arr and split take their words alone; bind takes keys, and with takes
# keys, then --, then a command; push, set, patch, concat, join, equals,
# merge, deepmerge, flatten, difference, intersect, validate, to_strh and to_strt take the
# document first;
# str and time take the rest of the line as their text. now takes no
# argument, and its result is printed with every digit replaced by 9,
# because the current time is different on every run.

set -u

. "$(dirname "$0")/../shell/.golden/shell/golden/api.sh"

main() {
  transcript__require_usage "$@"
  transcript__load_library "$1"
  DOCUMENT="$(transcript__read_document "${3:-}")"

  golden__transcribe transcript__run_call "$2"
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

# Runs one call: its verb, with -s or --sort when the call gives a
# translator that flag as its first word, on the document it names, "@<register>" first or
# the fileset's, with the rest of the line as its argument. A writer's
# arguments are words, and a word "$<register>" is that register's document.
transcript__run_call() {
  DOCUMENT_FOR_CALL="$DOCUMENT"
  FLAG=''
  __transcript__run_call__rest="$(golden__argument_of "$1")"

  case "$__transcript__run_call__rest" in
    -s | '-s '* | --sort | '--sort '*)
      FLAG="${__transcript__run_call__rest%% *}"
      __transcript__run_call__rest="$(golden__argument_of "$__transcript__run_call__rest")"
      ;;
  esac

  case "$__transcript__run_call__rest" in
    @*)
      DOCUMENT_FOR_CALL="$(transcript__register_of "${__transcript__run_call__rest%% *}")"
      __transcript__run_call__rest="$(golden__argument_of "$__transcript__run_call__rest")"
      ;;
  esac

  # shellcheck disable=SC2086  # a writer's words are split on purpose
  case "${1%% *}" in
    obj | arr | bind | with | apply | push | set | patch | get-first | string-first | concat | join | split | equals | pick | without | merge | deepmerge | flatten | difference | intersect | validate | to_strh | to_strt | sort_by | group_by | min | max | run | run-bare) transcript__run_writer "${1%% *}" $__transcript__run_call__rest ;;
    map | filter | find | any | all | reduce | project) transcript__run_collection "${1%% *}" $__transcript__run_call__rest ;;
    *) transcript__run_verb "${1%% *}" "$__transcript__run_call__rest" ;;
  esac
}

# The document a register holds, named with or without its @ or $.
transcript__register_of() {
  golden__register_of "${1#[@\$]}"
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
      *) set -- "$@" "$(golden__unescape "$__transcript__run_writer__word")" ;;
    esac
    __transcript__run_writer__count=$((__transcript__run_writer__count - 1))
  done

  case "$__transcript__run_writer__verb" in
    obj | arr | split) golden__capture "silt__$__transcript__run_writer__verb" GOLDEN_ANSWER "$@" ;;
    bind) transcript__bind "$@" ;;
    with) transcript__with "$@" ;;
    apply) golden__capture silt__apply "$DOCUMENT_FOR_CALL" "$@" ;;
    get-first | string-first) golden__capture "silt__${__transcript__run_writer__verb%-first}" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "$@" ;;
    to_strh | to_strt) transcript__translate "$__transcript__run_writer__verb" "$DOCUMENT_FOR_CALL" "$@" ;;
    run) transcript__run_program "$DOCUMENT_FOR_CALL" "$@" ;;
    run-bare) transcript__run_program '' "$@" ;;
    *) golden__capture "silt__$__transcript__run_writer__verb" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "$@" ;;
  esac
}

# Runs run on a document, the awk program its first word names beside the
# calls file, and the words after it, which are run's options. A word that
# ends in .awk names a library beside the calls file.
transcript__run_program() {
  __transcript__run_program__document="$1"
  __transcript__run_program__program="$(golden__file_of "$2")"
  shift 2

  __transcript__run_program__count=$#
  while [ "$__transcript__run_program__count" -gt 0 ]; do
    case "$1" in
      *.awk) set -- "$@" "$(golden__file_of "$1")" ;;
      *) set -- "$@" "$1" ;;
    esac
    shift
    __transcript__run_program__count=$((__transcript__run_program__count - 1))
  done

  golden__capture silt__run GOLDEN_ANSWER "$__transcript__run_program__program" "$__transcript__run_program__document" "$@"
  transcript__name_files_from_calls
}

# Runs a verb over each on its words: project on its keys, the others on the
# callback named by its first word, one of this script's, and the extras after it.
transcript__run_collection() {
  __transcript__run_collection__verb="$1"
  shift

  case "$__transcript__run_collection__verb" in
    project) golden__capture silt__project GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "$@" ;;
    *) transcript__run_with_callback "$__transcript__run_collection__verb" "$@" ;;
  esac
}

# Runs a verb over each with the callback a call names and the extras given.
transcript__run_with_callback() {
  __transcript__run_with_callback__verb="$1"
  transcript__name_callback "$2"
  shift 2

  golden__capture "silt__$__transcript__run_with_callback__verb" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "$CALLBACK" "$@"
}

# Sets CALLBACK to the function a call names: one of the library's
# predicates by its full name, or one of this script's callbacks by its name
# without the prefix.
transcript__name_callback() {
  case "$1" in
    silt__*) CALLBACK="$1" ;;
    *) CALLBACK="transcript__$1" ;;
  esac
}

# Dispatches a reader verb, with the document where the verb takes one.
transcript__run_verb() {
  case "$1" in
    type) transcript__type "$2" ;;
    scalar | len | keys | canon | unique | is_true | is_false | is_zero | references) golden__capture "silt__$1" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" ;;
    defined | empty | not) golden__capture "silt__$1" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" ;;
    defined-word | empty-word | not-word) golden__capture "silt__${1%-word}" GOLDEN_ANSWER "$2" ;;
    bool) golden__capture silt__bool GOLDEN_ANSWER "$2" ;;
    null) golden__capture silt__null GOLDEN_ANSWER ;;
    option) golden__capture silt__option GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "${2%% *}" "$(golden__argument_of "$2")" ;;
    option-bare) golden__capture silt__option GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "$2" ;;
    option_is) golden__capture silt__option_is GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "${2%% *}" "$(golden__argument_of "$2")" ;;
    succeeds | fails) transcript__run_command "$1" "$2" ;;
    succeeds-reading | fails-reading) transcript__run_command_reading "${1%-reading}" "${2%% *}" "$(golden__argument_of "$2")" ;;
    to_json | to_yaml | to_toml | dump) transcript__translate "$1" "$DOCUMENT_FOR_CALL" ;;
    dump-*) transcript__dump_as "${1#dump-}" "$DOCUMENT_FOR_CALL" ;;
    load) transcript__load "${2%% *}" "${2#* }" ;;
    first | last | sum | values | entries | from_entries) golden__capture "silt__$1" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" ;;
    take | take_last) golden__capture "silt__$1" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "$2" ;;
    pop | shift) transcript__take_end "$1" ;;
    pop-element | shift-element) golden__capture "silt__${1%-element}" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" ;;
    pop-rest | shift-rest) golden__capture "silt__${1%-rest}" ELEMENT GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" ;;
    slice) golden__capture silt__slice GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "${2%% *}" "${2#* }" ;;
    read) golden__capture silt__read GOLDEN_ANSWER "$(golden__unescape "$2")" ;;
    read-register) golden__capture silt__read GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" ;;
    to_line | from_line) golden__capture "silt__$1" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" ;;
    line) transcript__line ;;
    get | string | has | pluck) golden__capture "silt__$1" GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "$2" ;;
    string-or) golden__capture silt__string GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "$(golden__argument_of "$2")" --default "$(golden__unescape "${2%% *}")" ;;
    from_json | from_yaml | from_toml | from_strh) transcript__translate "$1" < "$(golden__file_of "$2")" ;;
    from_strt) transcript__translate from_strt "$(transcript__register_of "${2#* }")" < "$(golden__file_of "${2%% *}")" ;;
    unwrap) golden__capture silt__unwrap GOLDEN_ANSWER "$2" ;;
    wrap) golden__capture silt__wrap GOLDEN_ANSWER "$(golden__unescape "$2")" ;;
    str) golden__capture silt__str GOLDEN_ANSWER "$(golden__unescape "$2")" ;;
    time) golden__capture silt__time GOLDEN_ANSWER "$2" ;;
    now) transcript__now ;;
    roundtrip) transcript__roundtrip "$(golden__unescape "$2")" ;;
    each) golden__capture silt__each "$DOCUMENT_FOR_CALL" transcript__note "$2" ;;
    each-until) golden__capture silt__each "$DOCUMENT_FOR_CALL" transcript__until_key "$2" ;;
    each-string) golden__capture silt__each "$DOCUMENT_FOR_CALL" transcript__note_string "$2" ;;
    each-nested) golden__capture silt__each "$DOCUMENT_FOR_CALL" transcript__note_nested '' ;;
    *) GOLDEN_STATUS=127 ;;
  esac
}

# Runs type on the document, and at the path when the call gives one.
transcript__type() {
  if [ -n "$1" ]; then
    golden__capture silt__type GOLDEN_ANSWER "$DOCUMENT_FOR_CALL" "$1"
  else
    golden__capture silt__type GOLDEN_ANSWER "$DOCUMENT_FOR_CALL"
  fi
}

# Runs succeeds or fails on a command, which is the words of the call. The
# command reads nothing, so that it cannot read the calls file.
transcript__run_command() {
  # shellcheck disable=SC2086  # the command's words are split on purpose
  golden__capture "silt__$1" GOLDEN_ANSWER $2 < /dev/null
}

# Runs succeeds or fails on a command that reads one line of text on stdin.
transcript__run_command_reading() {
  printf '%s\n' "$2" > "$GOLDEN_STDERR.stdin"
  # shellcheck disable=SC2086  # the command's words are split on purpose
  golden__capture "silt__$1" GOLDEN_ANSWER $3 < "$GOLDEN_STDERR.stdin"
  rm -f "$GOLDEN_STDERR.stdin"
}

# A command for succeeds and fails that runs a verb of its own: it exits
# with 0 when the document of the call is a list.
transcript__document_is_list() {
  silt__type DOCUMENT_KIND "$DOCUMENT_FOR_CALL"
  [ "$DOCUMENT_KIND" = list ]
}

# Runs a translator with the flag the call gave, if it gave one, in front
# of the variable's name.
transcript__translate() {
  __transcript__translate__verb="$1"
  shift

  if [ -n "$FLAG" ]; then
    golden__capture "silt__$__transcript__translate__verb" "$FLAG" GOLDEN_ANSWER "$@"
  else
    golden__capture "silt__$__transcript__translate__verb" GOLDEN_ANSWER "$@"
  fi
}

# Runs dump with SILT_DUMP set to a format, and unsets it afterwards, so
# that the next call has the default.
transcript__dump_as() {
  SILT_DUMP="$1"
  export SILT_DUMP
  shift

  __transcript__dump_as__status=0
  transcript__translate dump "$@" || __transcript__dump_as__status=$?
  unset SILT_DUMP

  return "$__transcript__dump_as__status"
}

# Runs pop or shift, and answers both values: the element under "element:"
# and the rest of the list under "rest:".
transcript__take_end() {
  ELEMENT=''
  REST=''
  golden__capture "silt__$1" ELEMENT REST "$DOCUMENT_FOR_CALL"
  if [ "$GOLDEN_STATUS" -eq 0 ]; then
    GOLDEN_ANSWER="element:$__silt__NL$ELEMENT${__silt__NL}rest:$__silt__NL$REST"
  fi
}

# Runs load on a JSON file and a schema file.
transcript__load() {
  golden__capture silt__load GOLDEN_ANSWER "$(golden__file_of "$1")" "$(golden__file_of "$2")"
  transcript__name_files_from_calls
}

# Takes the directory of the calls file out of the messages of the call
# just run. A message names a file by its whole path, which is different in
# every checkout.
transcript__name_files_from_calls() {
  MESSAGES="$(cat "$GOLDEN_STDERR")"
  while [ "$MESSAGES" != "${MESSAGES#*"$GOLDEN_CALLS_DIR/"}" ]; do
    MESSAGES="${MESSAGES%%"$GOLDEN_CALLS_DIR/"*}${MESSAGES#*"$GOLDEN_CALLS_DIR/"}"
  done
  printf '%s\n' "$MESSAGES" > "$GOLDEN_STDERR"
}

# Runs silt__now. If the result is a correctly formatted time, replaces
# every digit with 9 so the transcript is the same on every run. Any other
# result is left unchanged, so a badly formatted time shows up as a failure.
transcript__now() {
  golden__capture silt__now GOLDEN_ANSWER
  case "$GOLDEN_ANSWER" in
    0.:time-rfc3339-utc=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]Z)
      GOLDEN_ANSWER='0.:time-rfc3339-utc=9999-99-99T99:99:99.999999999Z'
      ;;
  esac
}

# to_line then from_line over the document: whether the line holds no
# newline, and whether the document came back unchanged.
transcript__line() {
  golden__capture silt__to_line LINE "$DOCUMENT_FOR_CALL"
  golden__capture silt__from_line BACK "$LINE"

  case "$LINE" in
    *"$__silt__NL"*) GOLDEN_ANSWER='one line: false' ;;
    *) GOLDEN_ANSWER='one line: true' ;;
  esac
  GOLDEN_ANSWER="$GOLDEN_ANSWER$__silt__NL$(transcript__identity_of "$DOCUMENT_FOR_CALL" "$BACK")"
}

# wrap then unwrap: the literal, then whether the text came back unchanged.
transcript__roundtrip() {
  golden__capture silt__wrap LITERAL "$1"
  golden__capture silt__unwrap BACK "$LITERAL"
  GOLDEN_ANSWER="$LITERAL$__silt__NL$(transcript__identity_of "$1" "$BACK")"
}

# Whether two texts are the same, as a line of the transcript.
transcript__identity_of() {
  if [ "$1" = "$2" ]; then
    printf 'identity: true'
  else
    printf 'identity: false'
  fi
}

# each's callback: the key, the extra argument when one came, and the value.
transcript__note() {
  GOLDEN_ANSWER="$GOLDEN_ANSWER${GOLDEN_ANSWER:+$__silt__NL}$1${3:+ $3}: $2"
}

# each's callback that stops the walk with status 3 at the key given.
transcript__until_key() {
  GOLDEN_ANSWER="$GOLDEN_ANSWER${GOLDEN_ANSWER:+$__silt__NL}$1"
  [ "$1" != "$3" ] || return 3
}

# each's callback that notes the key and the text at the path in the member.
transcript__note_string() {
  silt__string TEXT "$2" "$3" || return 1
  GOLDEN_ANSWER="$GOLDEN_ANSWER${GOLDEN_ANSWER:+$__silt__NL}$1: $TEXT"
}

# A callback for each: notes the path to the member, then runs each again
# on the member if it is a map or a list.
transcript__note_nested() {
  GOLDEN_ANSWER="$GOLDEN_ANSWER${GOLDEN_ANSWER:+$__silt__NL}$3$1"

  silt__type KIND "$2" || return 1
  case "$KIND" in
    map | list) silt__each "$2" transcript__note_nested "$3$1/" ;;
  esac
}

# A callback for each: adds one to the count in the variable named.
transcript__count_up() {
  eval "$3=\$(($3 + 1))"
}

# A callback for map: the number of members, counted by running each.
transcript__count_members() {
  COUNTED=0
  silt__each "$3" transcript__count_up COUNTED || return 1
  transcript__answer "$1" "0.:int=$COUNTED"
}

# A callback for map: the length of each member of the member.
transcript__lengths_of() {
  silt__map "$1" "$3" transcript__len_as_int
}

# A callback for map: transcript__lengths_of, one level further down.
transcript__lengths_two_deep() {
  silt__map "$1" "$3" transcript__lengths_of
}

# A callback for map: the members of the member that are lists.
transcript__lists_of() {
  silt__filter "$1" "$3" transcript__is_list
}

# A predicate: whether any member of the member is a list.
transcript__has_list() {
  silt__any "$1" "$3" transcript__is_list
}

# A predicate: whether every member of the member is a list.
transcript__all_are_lists() {
  silt__all "$1" "$3" transcript__is_list
}

# A predicate: whether the member is a list that holds more elements than
# the number given.
transcript__longer_than() {
  silt__type KIND "$3" || return 1
  LENGTH=0
  if [ "$KIND" = list ]; then
    silt__len LENGTH "$3" || return 1
  fi

  if [ "$LENGTH" -gt "$4" ]; then
    transcript__answer "$1" true
  else
    transcript__answer "$1" false
  fi
}

# A predicate: whether any member of the member holds more members than the
# number given, found by running find.
transcript__holds_more_than() {
  silt__find FOUND "$3" transcript__longer_than "$4" || return 1
  if [ -n "$FOUND" ]; then
    transcript__answer "$1" true
  else
    transcript__answer "$1" false
  fi
}

# Runs bind with the prefix BOUND_ on the keys given, and notes each
# variable. Then runs unbind on the same keys, and notes each variable again.
transcript__bind() {
  golden__capture silt__bind BOUND_ "$DOCUMENT_FOR_CALL" "$@"
  if [ "$GOLDEN_STATUS" -ne 0 ]; then
    return
  fi

  transcript__note_bound "$@"
  golden__capture silt__unbind BOUND_ "$@"
  GOLDEN_ANSWER="$GOLDEN_ANSWER${__silt__NL}after unbind:"
  transcript__note_bound "$@"
}

# Runs with, with the prefix BOUND_, on the words given: keys, then --, then
# a command. BOUND_id has a value before the call, so the transcript shows
# that with puts it back. Notes BOUND_id and BOUND_name after the call.
transcript__with() {
  # shellcheck disable=SC2034  # read by name in transcript__note_bound
  BOUND_id='the value before'
  unset BOUND_name
  golden__capture silt__with BOUND_ "$DOCUMENT_FOR_CALL" "$@"

  GOLDEN_ANSWER="$GOLDEN_ANSWER${GOLDEN_ANSWER:+$__silt__NL}after with:"
  transcript__note_bound id name
  unset BOUND_id
}

# Notes the variable that each key gives with the prefix BOUND_: its name
# and its value, or that it is unset.
transcript__note_bound() {
  for KEY in "$@"; do
    __silt__bind__underscored "$KEY"
    eval "GOLDEN_ANSWER=\"\$GOLDEN_ANSWER\${GOLDEN_ANSWER:+\$__silt__NL}BOUND_$__silt__bind__UNDERSCORED=\${BOUND_$__silt__bind__UNDERSCORED-unset}\""
  done
}

# A command for with: notes the variables of the keys given, and returns
# the status 4.
transcript__show_bound() {
  transcript__note_bound "$@"
  return 4
}

# A command for with that runs with itself on another document, with the
# same prefix and the key id, and notes BOUND_id before, inside and after.
transcript__with_again() {
  transcript__note_bound id
  silt__with BOUND_ '0."id":str="inner"' id -- transcript__note_bound id
  transcript__note_bound id
}

# A callback for reduce: the list built so far with the member's key added
# to it as a str.
transcript__keys_so_far() {
  silt__str KEY_DOCUMENT "$2" || return 1
  silt__push "$1" "$4" "$KEY_DOCUMENT"
}

# A callback for reduce: the int built so far with the number given added
# to it, or with 1 when no number is given.
transcript__add() {
  silt__scalar SO_FAR "$4" || return 1
  transcript__answer "$1" "0.:int=$((SO_FAR + ${5:-1}))"
}

# A callback for reduce that runs reduce on the member: the int built so
# far with the number of the member's own members added to it.
transcript__add_members() {
  silt__reduce MEMBERS "$3" transcript__add --from 0.:int=0 || return 1
  silt__scalar SO_FAR "$4" || return 1
  silt__scalar MEMBERS "$MEMBERS" || return 1
  transcript__answer "$1" "0.:int=$((SO_FAR + MEMBERS))"
}

# A callback for reduce that answers nothing.
transcript__answers_nothing() {
  :
}

# A command for apply: notes its arguments, one on each line.
transcript__arguments() {
  for ARGUMENT in "$@"; do
    GOLDEN_ANSWER="$GOLDEN_ANSWER${GOLDEN_ANSWER:+$__silt__NL}[$ARGUMENT]"
  done
}

# A predicate: whether the member's key is the text given.
transcript__key_is() {
  transcript__answer_whether "$1" "$2" "$4"
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
