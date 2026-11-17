#!/bin/sh

: <<'MODULE'
Calling a caller's callback on a member, for the verbs built on silt__each.
The callback receives the name of the variable to answer in, the member's
value, and then the caller's extra arguments (ADR.36@strata). A verb with
the suffix i passes the member's position after the value, and a verb with
the suffix k passes its key. A reducing verb passes what it has built so
far before the value.

A callback can run a loop of its own. Each verb built on silt__each keeps
its result in shared variables while it runs, so those variables are saved
before the callback is called and put back after it returns.
MODULE

: <<'CONST'
The variables in which the verbs built on silt__each keep their results
while a loop runs.
CONST
__silt__LOOP_RESULTS='__silt__COLLECTED __silt__KEPT __silt__HIT __silt__ANY __silt__ALL __silt__reduce__REDUCED'

: <<'FUN'
Says what the callbacks of the loop about to start receive, and starts its
count of members at 0. A verb calls this before it walks the members.

args:
  $1  The shape: empty for the value alone, i for the value and the
      position, k for the value and the key; r, ri and rk for a reducing
      verb, which passes what it has built so far before the value
FUN
__silt__shape() {
  eval "__silt__SHAPE_$((${__silt__LOOPS:-0} + 1))=\$1"
  eval "__silt__INDEX_$((${__silt__LOOPS:-0} + 1))=0"
}

: <<'FUN'
Calls the callback on a member and copies its answer to the variable named.
What the callback receives after the answer variable follows the shape that
__silt__shape set for the loop that is running.

  __silt__ask __silt__MAPPED runner '0.:str="bats"' key_of tag
    ->  key_of <answer variable> '0.:str="bats"' tag           the shape empty
    ->  key_of <answer variable> '0.:str="bats"' 0 tag         the shape i
    ->  key_of <answer variable> '0.:str="bats"' runner tag    the shape k

args:
  $1  The name of the variable that receives the callback's answer
  $2  The key, as text
  $3  The value, a document
  $4  The callback
  $@  The extra arguments; for a reducing shape, what the verb has built
      so far comes first
FUN
__silt__ask() {
  __silt__ask__out="$1"
  __silt__ask__key="$2"
  __silt__ask__value="$3"
  __silt__ask__callback="$4"
  shift 4
  eval "__silt__ask__shape=\${__silt__SHAPE_$__silt__LOOPS:-}"
  eval "__silt__ask__index=\${__silt__INDEX_$__silt__LOOPS:-0}"
  eval "__silt__INDEX_$__silt__LOOPS=\$((__silt__ask__index + 1))"

  case "$__silt__ask__shape" in
    r*) __silt__ask__reducing "$@" ;;
    i) __silt__ask__call "$__silt__ask__out" "$__silt__ask__callback" "$__silt__ask__value" "$__silt__ask__index" "$@" ;;
    k) __silt__ask__call "$__silt__ask__out" "$__silt__ask__callback" "$__silt__ask__value" "$__silt__ask__key" "$@" ;;
    *) __silt__ask__call "$__silt__ask__out" "$__silt__ask__callback" "$__silt__ask__value" "$@" ;;
  esac
}

: <<'FUN'
Calls the callback of a reducing verb, which receives what the verb has
built so far before the value. It reads what __silt__ask set.

args:
  $1  What the verb has built so far, a document
  $@  The extra arguments
FUN
__silt__ask__reducing() {
  __silt__ask__reducing__so_far="$1"
  shift

  case "$__silt__ask__shape" in
    ri) __silt__ask__call "$__silt__ask__out" "$__silt__ask__callback" "$__silt__ask__reducing__so_far" "$__silt__ask__value" "$__silt__ask__index" "$@" ;;
    rk) __silt__ask__call "$__silt__ask__out" "$__silt__ask__callback" "$__silt__ask__reducing__so_far" "$__silt__ask__value" "$__silt__ask__key" "$@" ;;
    *) __silt__ask__call "$__silt__ask__out" "$__silt__ask__callback" "$__silt__ask__reducing__so_far" "$__silt__ask__value" "$@" ;;
  esac
}

: <<'FUN'
Calls the callback with an answer variable of its own and then the
arguments given, and copies the answer to the variable named. The results
of the loop that is running are saved before the call and put back after
it, so the callback can run loops of its own.

args:
  $1  The name of the variable that receives the callback's answer
  $2  The callback
  $@  What the callback receives after its answer variable
FUN
__silt__ask__call() {
  __silt__ask__call__out="$1"
  __silt__ask__call__callback="$2"
  shift 2
  # structs-lint: allow -- SILT sits beneath structs, and a nested loop must not reach this call's names
  set -- "$__silt__ask__call__out" "$__silt__LOOPS" "$__silt__ask__call__callback" "__silt__ask__answer_$__silt__LOOPS" "$@"

  eval "$4=''"
  __silt__save_results "$2"
  __silt__call_callback "$@"
  __silt__ask__call__status=$?
  __silt__restore_results "$2"
  eval "$1=\$$4"
  return "$__silt__ask__call__status"
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
