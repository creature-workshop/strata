#!/bin/sh

: <<'MODULE'
Walking a document line by line. Every verb that reads lines goes through
here, and a callback the walk runs may walk another document: what a walk
needs afterwards rides in its own positional parameters, and what it reports
is set once the lines are done.
MODULE

: <<'FUN'
Calls <callback> once per line of a document, in order, with the line as its
argument. The walk ends early when the callback sets __silt__STOP to true,
and returns the callback's status when it fails. A document past
__silt__THRESHOLD lines goes to the awk program named in __silt__AWK
instead, when the verb named one: its output lands in __silt__HANDED_OUT,
__silt__HANDED is true, and no line is walked. Walking clears __silt__AWK.

registers:
  __silt__LINE_CALLBACK  The callback of the walk running; a callback may
                         walk another document, so the outer walk's callback
                         rides last but one in this walk's positional
                         parameters and is given back when this walk ends
  __silt__STOP           Set true by a callback to end the walk early; the
                         outer walk's rides last in the positional parameters
                         and is given back the same way
  __silt__HANDED         Whether this walk went to awk, set once it is over,
                         whatever the walks its callbacks ran
  __silt__HANDED_OUT     What the awk program printed, when it did
  __silt__IFS            The field separator held aside during a split
  __silt__IFS_WAS_SET    "true" when the caller had IFS set before the split
  __silt__WALK_DOCUMENT  The document, kept for the hand-off once the split
                         has taken the positional parameters
  __silt__WALK_PROGRAM   The awk program the verb named, if any
  __silt__WALK_STATUS    The status the walk ends with

args:
  $1  The document
  $2  The callback, a function taking the line
FUN
__silt__walk() {
  set -- "$1" "$2" "${__silt__LINE_CALLBACK-}" "${__silt__STOP-}"
  __silt__start_walk "$1"
  __silt__LINE_CALLBACK="$2"

  __silt__split_lines
  # shellcheck disable=SC2086
  set -- $1 "$3" "$4"
  __silt__split_over

  if [ "$#" -gt "$((__silt__THRESHOLD + 2))" ] && [ -n "$__silt__WALK_PROGRAM" ]; then
    __silt__hand_off "$__silt__WALK_DOCUMENT" "$__silt__WALK_PROGRAM"
  else
    __silt__walk__in_shell "$@"
  fi
  __silt__WALK_STATUS=$?

  __silt__walk__done "$#" "$@"
  return "$__silt__WALK_STATUS"
}

: <<'FUN'
Sets the shell up to split a document into lines: IFS a newline alone and
globbing off, so a value's * stays as it is. The caller does the split with
its own set --, since positional parameters are a frame's own, and calls
__silt__split_over after it.
FUN
__silt__split_lines() {
  __silt__IFS_WAS_SET="${IFS+true}"
  __silt__IFS="${IFS-}"
  IFS="$__silt__NL"
  set -f
}

: <<'FUN'
Gives the shell back its field splitting and globbing after a split.
FUN
__silt__split_over() {
  set +f
  __silt__give_back_ifs "$__silt__IFS_WAS_SET" "$__silt__IFS"
}

: <<'FUN'
Puts the caller's IFS back the way it was before a split. A caller that had
IFS unset gets it unset again, which is how a shell splits on its default
characters. Setting it to the empty string there would turn splitting off.

args:
  $1  "true" when IFS was set before the split, empty when it was unset
  $2  What IFS held, when it was set
FUN
__silt__give_back_ifs() {
  if [ "$1" = true ]; then
    IFS="$2"
  else
    unset IFS
  fi
}

: <<'FUN'
Opens a walk: takes the awk program the verb named, if any, and clears the
registers a walk reports through.

args:
  $1  The document
FUN
__silt__start_walk() {
  __silt__WALK_DOCUMENT="$1"
  __silt__WALK_PROGRAM="${__silt__AWK-}"
  __silt__WALK_STATUS=0
  __silt__AWK=''
  __silt__STOP=false
  __silt__HANDED=false
  __silt__HANDED_OUT=''
}

: <<'FUN'
Walks the lines in this shell, then reports that nothing was handed to awk,
whatever the walks the callback ran meanwhile reported.

args:
  $@  The lines, then the outer walk's callback and its stop flag
FUN
__silt__walk__in_shell() {
  __silt__walk__lines "$@"
  __silt__walk__in_shell__status=$?

  __silt__HANDED=false
  __silt__HANDED_OUT=''
  return "$__silt__walk__in_shell__status"
}

: <<'FUN'
Calls __silt__LINE_CALLBACK on each line in turn, the outer walk's callback
and stop flag riding last and never called, until the lines run out, the
callback sets __silt__STOP, or it fails, whose status is returned.

args:
  $@  The lines, then the outer walk's callback and its stop flag
FUN
__silt__walk__lines() {
  while [ "$#" -gt 2 ]; do
    "$__silt__LINE_CALLBACK" "$1" || return $?
    shift

    if [ "$__silt__STOP" = true ]; then
      return 0
    fi
  done
}

: <<'FUN'
Ends a walk: gives __silt__LINE_CALLBACK and __silt__STOP back to the walk
this one ran inside, whose callback and stop flag ride last in the
positional parameters.

args:
  $1  The count of positional parameters that follow
  $@  The rest of the walk's positional parameters, the outer callback and
      its stop flag last
FUN
__silt__walk__done() {
  __silt__walk__done__count="$1"
  shift
  eval "__silt__STOP=\${$__silt__walk__done__count}"
  eval "__silt__LINE_CALLBACK=\${$((__silt__walk__done__count - 1))}"
}

: <<'FUN'
Runs awk programs of the tier over the document on stdin, the line library
loaded ahead of them, and appends what they printed to __silt__ANSWER,
where the walk's callback would have put it, keeping a copy in
__silt__HANDED_OUT with __silt__HANDED true. Keys, paths and numbers reach
the programs through SILT_* in the environment; the document goes on
stdin, and a document the verb sent ahead with __silt__send_ahead goes on
the same stdin in front of it, so no value ever meets the argument cap or
a file.
The programs' status is the walk's, and a refusal reaches stderr the way
the shell's does.

args:
  $1  The document
  $2  The programs' names under shell/silt/awk, without .awk, separated by
      spaces
FUN
__silt__hand_off() {
  __silt__HANDED=true
  __silt__HANDED_OUT="$(__silt__feed "$1" | __silt__tier "$2")" || return $?
  __silt__absorb_handed
}

: <<'FUN'
Prints what the awk tier reads on stdin: every document sent ahead, each
followed by the line that ends it, then the document itself. The builtin
printf prints them, so no document meets an argument.

args:
  $1  The document
FUN
__silt__feed() {
  printf '%s' "${__silt__AHEAD-}"
  printf '%s\n' "$1"
}

: <<'FUN'
Runs awk programs of the tier over stdin, the line library loaded ahead of
them and each in the order named, with the registers they read in their
environment.

args:
  $@  The programs' names under shell/silt/awk, without .awk; one argument
      may name several, separated by spaces
FUN
__silt__tier() {
  # shellcheck disable=SC2048,SC2086  # the names are split on purpose
  set -- $*

  __silt__tier__count=$#
  while [ "$__silt__tier__count" -gt 0 ]; do
    # structs-lint: allow -- SILT sits beneath structs, so the -f list is built in the positionals
    set -- "$@" -f "$__silt__DIR/awk/$1.awk"
    shift
    __silt__tier__count=$((__silt__tier__count - 1))
  done

  SILT_SEGMENTS="${__silt__SEGMENTS-}" \
    SILT_SEPARATOR="${__silt__SEPARATOR-}" \
    SILT_DEPTH="${__silt__NEST_DEPTH-}" \
    SILT_INDEX="${__silt__INDEX-}" \
    SILT_FROM="${__silt__FROM-}" \
    SILT_TO="${__silt__TO-}" \
    SILT_KIND="${__silt__PARENT_KIND-}" \
    SILT_INDEX_FILE="${__silt__INDEX_FILE-}" \
    SILT_DOCUMENTS="${__silt__DOCUMENTS-}" \
    SILT_BASE="${__silt__BASE-}" \
    SILT_INDENT="${__silt__dump__INDENT-}" \
    awk -f "$__silt__DIR/awk/lines.awk" "$@"
}

: <<'FUN'
Appends the awk tier's output to the answer as lines, when it printed any.
FUN
__silt__absorb_handed() {
  if [ "$__silt__HANDED" = false ] || [ -z "$__silt__HANDED_OUT" ]; then
    return 0
  fi

  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER="$__silt__HANDED_OUT"
  else
    __silt__ANSWER="$__silt__ANSWER$__silt__NL$__silt__HANDED_OUT"
  fi
}

: <<'FUN'
Sends a document ahead of the next hand-off's document, on the same stdin.
The awk tier reads it first, up to the line that holds the record separator
alone. No line of a document is that line, because a str writes the byte
as \u001e. A verb may send several documents, which awk reads in the order
sent, and the verb forgets them with __silt__clear_ahead once its hand-off
is over, whether the walk stayed in the shell, handed off or refused.
Nothing is written to a file, so two subshells of one process never read
each other's document.

args:
  $1  The document
FUN
__silt__send_ahead() {
  __silt__AHEAD="${__silt__AHEAD-}$1$__silt__NL$__silt__RS$__silt__NL"
}

: <<'FUN'
Forgets what was sent ahead, so the next hand-off sends nothing in front of
its document.
FUN
__silt__clear_ahead() {
  __silt__AHEAD=''
}

: <<'FUN'
Runs awk programs over one document on stdin with a second sent ahead of
it, and takes what they print as the answer. The second is forgotten
whether or not the programs refuse.

args:
  $1  The document for stdin
  $2  The document sent ahead of it
  $3  The programs' names under shell/silt/awk, separated by spaces
FUN
__silt__hand_off_with() {
  __silt__hand_off_with__status=0
  __silt__ANSWER=''
  __silt__send_ahead "$2"
  __silt__hand_off "$1" "$3" || __silt__hand_off_with__status=$?
  __silt__clear_ahead

  return "$__silt__hand_off_with__status"
}
