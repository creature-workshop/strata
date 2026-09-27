#!/bin/sh

: <<'MODULE'
Calling a caller's callback on a member, for the verbs built on silt__each.
The callback receives the name of the variable to answer in, the member's
key, the member's value, and then the caller's extra arguments.

A callback can run a loop of its own. Each verb built on silt__each keeps
its result in shared variables while it runs, so those variables are saved
before the callback is called and put back after it returns.
MODULE

: <<'CONST'
The variables in which the verbs built on silt__each keep their results
while a loop runs.
CONST
__silt__LOOP_RESULTS='__silt__COLLECTED __silt__KEPT __silt__HIT __silt__ANY __silt__ALL'

: <<'FUN'
Calls the callback on a member and copies its answer to the variable named.
The results of the loop that is running are saved before the call and put
back after it, so the callback can run loops of its own.

  __silt__ask __silt__MAPPED runner '0.:str="bats"' key_of tag
    ->  key_of <answer variable> runner '0.:str="bats"' tag

args:
  $1  The name of the variable that receives the callback's answer
  $2  The key, as text
  $3  The value, a document
  $4  The callback
  $@  The extra arguments
FUN
__silt__ask() {
  __silt__ask__out="$1"
  __silt__ask__key="$2"
  __silt__ask__value="$3"
  __silt__ask__callback="$4"
  shift 4

  set -- "$__silt__ask__out" "$__silt__LOOPS" "$__silt__ask__callback" "__silt__ask__answer_$__silt__LOOPS" "$__silt__ask__key" "$__silt__ask__value" "$@"
  eval "$4=''"
  __silt__save_results "$2"

  __silt__call_callback "$@"
  __silt__ask__status=$?

  __silt__restore_results "$2"
  eval "$1=\$$4"
  return "$__silt__ask__status"
}

: <<'FUN'
Calls the callback with the arguments that follow it.

args:
  $1  Unused: the name of the variable that receives the answer
  $2  Unused: the nesting level
  $3  The callback
  $@  The callback's arguments
FUN
__silt__call_callback() {
  shift 2
  "$@"
}

: <<'FUN'
Copies each variable in __silt__LOOP_RESULTS to a variable named for the
nesting level.

args:
  $1  The nesting level
FUN
__silt__save_results() {
  for __silt__save_results__name in $__silt__LOOP_RESULTS; do
    eval "__silt__save_results__saved_${1}_$__silt__save_results__name=\${$__silt__save_results__name-}"
  done
}

: <<'FUN'
Copies the values that __silt__save_results saved for the nesting level
back to the variables in __silt__LOOP_RESULTS.

args:
  $1  The nesting level
FUN
__silt__restore_results() {
  for __silt__restore_results__name in $__silt__LOOP_RESULTS; do
    eval "$__silt__restore_results__name=\$__silt__save_results__saved_${1}_$__silt__restore_results__name"
  done
}

: <<'FUN'
Calls a predicate on a member and stores its answer, true or false, in
__silt__VERDICT. Fails if the predicate answers anything else.

args:
  $1  The key, as text
  $2  The value, a document
  $3  The predicate
  $@  The extras
FUN
__silt__verdict() {
  __silt__VERDICT=''
  __silt__ask __silt__VERDICT "$@" || return $?

  case "$__silt__VERDICT" in
    true | false) ;;
    *)
      __silt__fail "a predicate answers true or false, not '$__silt__VERDICT'"
      return 1
      ;;
  esac
}
