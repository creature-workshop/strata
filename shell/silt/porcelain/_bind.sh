#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/bind.sh: @bind, @unbind, @with.
FRAGMENT

: <<'PUB_FUN'
Assigns a field of a SILT document to a variable, for each key given.
Refuses a prefix or a key that cannot be part of a variable name, and two
keys that give the same variable. When it refuses, it assigns nothing.

  issue="$(cat <<'SILT'
  0."id":int=42
  0."state":map
  1."type":str="started"
  SILT
  )"
  @bind __close__ "$issue" id state.type   ->  __close__id=42  __close__state_type=started

  The same, with each SILT document written as JSON:

    @bind __close__ {"id":42,"state":{"type":"started"}} id state.type   ->  __close__id=42  __close__state_type=started

args:
  $1  The prefix of the variables' names
  $2  The SILT document
  $@  The keys
PUB_FUN
@bind() {
  silt__bind "$@"
}

: <<'PUB_FUN'
Unsets the variable that each key gives. It is the pair of @bind, and
takes the same prefix and keys.

  @unbind __close__ id state.type   ->  __close__id and __close__state_type are unset

args:
  $1  The prefix of the variables' names
  $@  The keys
PUB_FUN
@unbind() {
  silt__unbind "$@"
}

: <<'PUB_FUN'
Assigns a field of a SILT document to a variable for each key, runs a command,
and then puts every variable back as it was: a variable that had a value
gets it back, and any other is unset. Returns the command's status.

The command can call @with itself, with the same prefix and keys.

  issue="$(cat <<'SILT'
  0."id":int=42
  0."state":map
  1."type":str="started"
  SILT
  )"
  close_issue() { closed="$__close__id is $__close__state_type, closed as $1"; }
  @with __close__ "$issue" id state.type -- close_issue done   ->  closed='42 is started, closed as done'

  The same, with each SILT document written as JSON:

    @with __close__ {"id":42,"state":{"type":"started"}} id state.type -- close_issue done   ->  closed='42 is started, closed as done'

args:
  $1  The prefix of the variables' names
  $2  The SILT document
  $@  The keys, then --, then the command and its arguments
PUB_FUN
@with() {
  silt__with "$@"
}
