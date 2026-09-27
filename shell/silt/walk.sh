#!/bin/sh

: <<'MODULE'
Walking a document line by line. Every verb that reads lines goes through
here.
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
                         rides last in this walk's positional parameters and
                         is given back when this walk ends
  __silt__STOP           Set true by a callback to end the walk early
  __silt__WALK_DOCUMENT  The document, kept for the hand-off once the split
                         has taken the positional parameters
  __silt__WALK_PROGRAM   The awk program the verb named, if any
  __silt__WALK_STATUS    The status the walk ends with

args:
  $1  The document
  $2  The callback, a function taking the line
FUN
__silt__walk() {
  __silt__start_walk "$1"
  set -- "$1" "$2" "${__silt__LINE_CALLBACK-}"
  __silt__LINE_CALLBACK="$2"

  __silt__walk__ifs="$IFS"
  IFS="$__silt__NL"
  set -f
  # shellcheck disable=SC2086
  set -- $1 "$3"
  set +f
  IFS="$__silt__walk__ifs"

  if [ "$#" -gt "$((__silt__THRESHOLD + 1))" ] && [ -n "$__silt__WALK_PROGRAM" ]; then
    __silt__hand_off "$__silt__WALK_DOCUMENT" "$__silt__WALK_PROGRAM" || __silt__WALK_STATUS=$?
  else
    __silt__walk_lines "$@" || __silt__WALK_STATUS=$?
  fi

  __silt__walk_done "$#" "$@"
  return "$__silt__WALK_STATUS"
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
Calls __silt__LINE_CALLBACK on each line in turn, the outer walk's callback
riding last and never called, until the lines run out, the callback sets
__silt__STOP, or it fails, whose status is returned.

args:
  $@  The lines, then the outer walk's callback
FUN
__silt__walk_lines() {
  while [ "$#" -gt 1 ]; do
    "$__silt__LINE_CALLBACK" "$1" || return $?
    shift

    if [ "$__silt__STOP" = true ]; then
      return 0
    fi
  done
}

: <<'FUN'
Ends a walk: gives __silt__LINE_CALLBACK back to the walk this one ran
inside, whose callback rides last in the positional parameters.

args:
  $1  The count of positional parameters that follow
  $@  The rest of the walk's positional parameters, the outer callback last
FUN
__silt__walk_done() {
  __silt__walk_done__count="$1"
  shift
  eval "__silt__LINE_CALLBACK=\${$__silt__walk_done__count}"
}

: <<'FUN'
Runs one awk program of the tier over the document on stdin, the line
library loaded ahead of it, and leaves what it printed in
__silt__HANDED_OUT with __silt__HANDED true. Keys, paths and numbers reach
the program through SILT_* in the environment, a second document through
the spill file SILT_SPILL names; the document itself rides stdin, so no
value ever meets the argument cap. The program's status is the walk's, and
its refusal reaches stderr the way the shell's does.

args:
  $1  The document
  $2  The program's name under shell/silt/awk, without .awk
FUN
__silt__hand_off() {
  __silt__HANDED=true
  __silt__HANDED_OUT="$(printf '%s\n' "$1" | __silt__tier "$2")"
}

: <<'FUN'
Runs one awk program of the tier over stdin, the line library loaded ahead
of it, with the registers it reads in its environment.

args:
  $1  The program's name under shell/silt/awk, without .awk
FUN
__silt__tier() {
  SILT_SEGMENTS="${__silt__SEGMENTS-}" \
    SILT_SEPARATOR="${__silt__SEPARATOR-}" \
    SILT_DEPTH="${__silt__NEST_DEPTH-}" \
    SILT_INDEX="${__silt__INDEX-}" \
    SILT_KIND="${__silt__PARENT_KIND-}" \
    SILT_SPILL="${__silt__SPILL-}" \
    awk -f "$__silt__DIR/awk/lines.awk" -f "$__silt__DIR/awk/$1.awk"
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
Writes a second document to a file of this process's own under TMPDIR, for
an awk program to read beside its stdin, and names it in __silt__SPILL. The
builtin printf writes it, so the document meets no argument.

args:
  $1  The document
FUN
__silt__spill() {
  __silt__SPILL="${TMPDIR:-/tmp}/silt.$$.spill"
  printf '%s\n' "$1" > "$__silt__SPILL"
}

: <<'FUN'
Removes the spill file, if one was written.
FUN
__silt__unspill() {
  if [ -n "$__silt__SPILL" ]; then
    rm -f "$__silt__SPILL"
    __silt__SPILL=''
  fi
}
