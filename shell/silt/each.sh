#!/bin/sh

: <<'MODULE'
silt__each: a callback per member, with its key and its value.
MODULE

: <<'PUB_FUN'
Calls a callback once for each member of a map or a list. The callback
receives the member's key as text (a map's key unquoted, a list's index),
the member's value as a document of its own, and then the extra arguments.
Stops at the first call that returns non-zero, and returns that status.

The callback can run any verb, including silt__each and the verbs built on
it, so loops can be nested.

  count_reads() { silt__len n "$2"; total=$((total + n)); }
  total=0
  silt__each "$tests" count_reads

registers:
  __silt__LOOPS         How many loops are running, this one included
  __silt__CALLBACK_<n>  The callback of the loop at nesting level <n>
  __silt__EXTRAS_<n>    The end of that callback's argument list, which
                        reads the extra arguments by name
  __silt__MEMBER_KEY    The key of the member being read
  __silt__MEMBER        The value of the member being read
  __silt__OPEN          Whether a member is being read

args:
  $1  The document
  $2  The callback
  $@  Extra arguments the callback receives after the key and the value
PUB_FUN
silt__each() {
  __silt__LOOPS=$((${__silt__LOOPS:-0} + 1))

  __silt__run_each "$@"
  set -- "$?"

  __silt__LOOPS=$((__silt__LOOPS - 1))
  return "$1"
}

: <<'FUN'
Runs one loop at the current nesting level. silt__each counts the level up
before it calls this function and down after it, whatever this function
returns.

args:
  $1  The document
  $2  The callback
  $@  Extra arguments for the callback
FUN
__silt__run_each() {
  __silt__run_each__doc="$1"
  eval "__silt__CALLBACK_$__silt__LOOPS=\$2"
  shift 2

  __silt__run_each__kind=''
  silt__type __silt__run_each__kind "$__silt__run_each__doc" || return 1
  __silt__has_members "$__silt__run_each__kind" members || return 1
  __silt__hold_extras "$@"

  __silt__MEMBER_KEY=''
  __silt__MEMBER=''
  __silt__OPEN=false
  __silt__AWK='each'
  __silt__walk "$__silt__run_each__doc" __silt__each__line || return $?

  if [ "$__silt__HANDED" = true ]; then
    __silt__walk "$__silt__HANDED_OUT" __silt__each__block_line || return $?
    return
  fi

  __silt__deliver_last_member
}

: <<'FUN'
Calls the callback for the last member, which is still being read when the
lines run out. The walk has ended by then, so a callback that sets
__silt__STOP would stop the loop around this one. The flag is therefore
saved before the call and put back after it.
FUN
__silt__deliver_last_member() {
  eval "__silt__deliver_last_member__stop_$__silt__LOOPS=\${__silt__STOP-}"

  __silt__deliver_member
  set -- "$?"

  eval "__silt__STOP=\$__silt__deliver_last_member__stop_$__silt__LOOPS"
  return "$1"
}

: <<'FUN'
Handles one line of the blocks the awk tier writes for each: a member's key
as the line writes it opens a member, its value's lines fill it, and the
line holding the record separator alone delivers it. Returns the callback's
status when it stops the walk.

args:
  $1  The line
FUN
__silt__each__block_line() {
  if [ "$1" = "$__silt__RS" ]; then
    __silt__deliver_member
    return
  fi

  if [ "$__silt__OPEN" = false ]; then
    __silt__open_block_member "$1" || return 1
    return
  fi

  __silt__MEMBER="$__silt__MEMBER${__silt__MEMBER:+$__silt__NL}$1"
}

: <<'FUN'
Opens a member of a block from its key line: a map's key literal unwrapped
to text, a list's index as it is.

args:
  $1  The key, as the line writes it
FUN
__silt__open_block_member() {
  case "$1" in
    "$__silt__QUOTE"*) silt__unwrap __silt__MEMBER_KEY "$1" || return 1 ;;
    *) __silt__MEMBER_KEY="$1" ;;
  esac

  __silt__MEMBER=''
  __silt__OPEN=true
}

: <<'FUN'
Stores each extra argument in a variable of its own, named for the nesting
level and the argument's position. Writes to __silt__EXTRAS_<level> the end
of the callback's argument list, which reads those variables. The shell
therefore never parses a value as code, and a nested loop does not
overwrite the arguments of the loop around it.

args:
  $@  The extra arguments
FUN
__silt__hold_extras() {
  __silt__hold_extras__list=''
  __silt__hold_extras__count=0

  for __silt__hold_extras__extra do
    __silt__hold_extras__count=$((__silt__hold_extras__count + 1))
    __silt__hold_extras__name="__silt__hold_extras__extra_${__silt__LOOPS}_$__silt__hold_extras__count"
    eval "$__silt__hold_extras__name=\$__silt__hold_extras__extra"
    __silt__hold_extras__list="$__silt__hold_extras__list \"\$$__silt__hold_extras__name\""
  done

  eval "__silt__EXTRAS_$__silt__LOOPS=\$__silt__hold_extras__list"
}

: <<'FUN'
Handles one line of the walk: a depth-0 line is the next member, a deeper
one belongs to the member open. Returns the callback's status when it stops
the walk.

args:
  $1  The line
FUN
__silt__each__line() {
  case "$1" in
    0.*) __silt__next_member "$1" ;;
    *) __silt__extend_member "$1" ;;
  esac
}

: <<'FUN'
Delivers the member open, if one is, then opens the line as the next, unless
the delivery ended the walk. The delivery comes first because the callback
may parse lines of its own, so the line is read only once it has returned.
Returns the callback's status when it stops the walk.

args:
  $1  The member's own line
FUN
__silt__next_member() {
  __silt__deliver_member || return $?

  if [ "$__silt__STOP" = true ]; then
    return 0
  fi

  __silt__parse "$1" || return 1
  __silt__open_member
}

: <<'FUN'
Opens the parsed line as the next member: its key as text, its value as a
keyless root. A keyless line is an empty collection, which ends the walk
with no member at all.
FUN
__silt__open_member() {
  case "$__silt__KEY" in
    '')
      __silt__STOP=true
      return 0
      ;;
    "$__silt__QUOTE"*) silt__unwrap __silt__MEMBER_KEY "$__silt__KEY" || return 1 ;;
    *) __silt__MEMBER_KEY="$__silt__KEY" ;;
  esac

  if [ "$__silt__LEAF" = true ]; then
    __silt__MEMBER="0.:$__silt__TYPE=$__silt__VALUE"
  else
    __silt__MEMBER="0.:$__silt__TYPE"
  fi

  __silt__OPEN=true
}

: <<'FUN'
Adds a deeper line to the member open, moved up so the member's own members
sit at depth 0; the first one replaces the placeholder root.

args:
  $1  The line
FUN
__silt__extend_member() {
  __silt__parse "$1" || return 1

  case "$__silt__MEMBER" in
    0.:map | 0.:list) __silt__MEMBER="$((__silt__DEPTH - 1)).${1#*.}" ;;
    *) __silt__MEMBER="$__silt__MEMBER$__silt__NL$((__silt__DEPTH - 1)).${1#*.}" ;;
  esac
}

: <<'FUN'
If a member is being read, calls the callback of the loop at the current
nesting level with the member's key, its value and the extra arguments, and
returns the callback's status.
FUN
__silt__deliver_member() {
  if [ "$__silt__OPEN" = false ]; then
    return 0
  fi

  __silt__OPEN=false
  eval "__silt__deliver_member__extras=\$__silt__EXTRAS_$__silt__LOOPS"
  eval "\"\$__silt__CALLBACK_$__silt__LOOPS\" \"\$__silt__MEMBER_KEY\" \"\$__silt__MEMBER\"$__silt__deliver_member__extras"
}
