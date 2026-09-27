#!/bin/sh

: <<'MODULE'
silt__bind, silt__unbind and silt__with: fields of a document assigned to
shell variables.

silt__bind assigns the variables and the caller releases them with
silt__unbind. silt__with assigns them for one command and releases them
when the command returns, so the caller has nothing to remember.

Each key is a name, or several names joined by dots to read a path. The
variable is the prefix and then the names joined by underscores:

  prefix __close__ and key state.type   ->  the variable __close__state_type

A str is assigned as its text, a number or a bool as written, and a map or
a list as a SILT document. A null, and a field the document does not hold,
are assigned as the empty string.
MODULE

: <<'PUB_FUN'
Assigns a field of a document to a variable, for each key given. Refuses a
prefix or a key that cannot be part of a variable name, and two keys that
give the same variable. When it refuses, it assigns nothing.

  silt__bind __close__ "$issue" id state.type
    ->  __close__id=42  __close__state_type=started

args:
  $1  The prefix of the variables' names
  $2  The document
  $@  The keys
PUB_FUN
silt__bind() {
  __silt__bind__prefix="${1:-}"
  __silt__bind__doc="${2:-}"
  shift "$(($# < 2 ? $# : 2))"

  __silt__name_keys "$__silt__bind__prefix" "$@" || return 1

  for __silt__bind__key in "$@"; do
    __silt__bind_key "$__silt__bind__prefix" "$__silt__bind__doc" "$__silt__bind__key" || return 1
  done
}

: <<'PUB_FUN'
Unsets the variable that each key gives. It is the pair of silt__bind, and
takes the same prefix and keys.

  silt__unbind __close__ id state.type

args:
  $1  The prefix of the variables' names
  $@  The keys
PUB_FUN
silt__unbind() {
  __silt__unbind__prefix="${1:-}"
  shift "$(($# < 1 ? $# : 1))"

  __silt__name_keys "$__silt__unbind__prefix" "$@" || return 1
  __silt__release "$__silt__NAMES"
}

: <<'PUB_FUN'
Assigns a field of a document to a variable for each key, runs a command,
and then puts every variable back as it was: a variable that had a value
gets it back, and any other is unset. Returns the command's status.

The command can call silt__with itself, with the same prefix and keys.

  silt__with __close__ "$issue" id state.type -- close_issue "$reason"

registers:
  __silt__WITHS  How many calls of silt__with are running, this one
                 included

args:
  $1  The prefix of the variables' names
  $2  The document
  $@  The keys, then --, then the command and its arguments
PUB_FUN
silt__with() {
  __silt__WITHS=$((${__silt__WITHS:-0} + 1))
  eval "__silt__with__names_$__silt__WITHS=''"

  __silt__run_with "$@"
  set -- "$?"

  eval "__silt__restore \"\$__silt__with__names_$__silt__WITHS\""
  __silt__WITHS=$((__silt__WITHS - 1))
  return "$1"
}

: <<'FUN'
Assigns the variables of one call of silt__with and runs its command.

args:
  $1  The prefix of the variables' names
  $2  The document
  $@  The keys, then --, then the command and its arguments
FUN
__silt__run_with() {
  __silt__run_with__prefix="${1:-}"
  __silt__run_with__doc="${2:-}"
  shift "$(($# < 2 ? $# : 2))"

  __silt__count_keys "$@" || return 1
  __silt__name_first_keys "$__silt__run_with__prefix" "$__silt__KEYS" "$@" || return 1
  __silt__save "$__silt__NAMES"
  eval "__silt__with__names_$__silt__WITHS=\$__silt__NAMES"

  while [ "$__silt__KEYS" -gt 0 ]; do
    __silt__bind_key "$__silt__run_with__prefix" "$__silt__run_with__doc" "$1" || return 1
    __silt__KEYS=$((__silt__KEYS - 1))
    shift
  done
  shift

  "$@"
}

: <<'FUN'
Sets __silt__KEYS to the number of arguments in front of --. Refuses
arguments that have no --, and a -- with no command after it.

args:
  $@  The keys, then --, then the command and its arguments
FUN
__silt__count_keys() {
  __silt__KEYS=0

  for __silt__count_keys__word in "$@"; do
    if [ "$__silt__count_keys__word" = -- ]; then
      break
    fi
    __silt__KEYS=$((__silt__KEYS + 1))
  done

  if [ "$__silt__KEYS" -ge "$(($# - 1))" ]; then
    __silt__fail 'with takes its keys, then --, then a command'
    return 1
  fi
}

: <<'FUN'
Sets __silt__NAMES to the variables that the first <count> keys give, as
__silt__name_keys does for every key.

args:
  $1  The prefix
  $2  The number of keys
  $@  The keys, and what follows them
FUN
__silt__name_first_keys() {
  __silt__name_first_keys__prefix="$1"
  __silt__name_first_keys__count="$2"
  shift 2

  __silt__require_prefix "$__silt__name_first_keys__prefix" || return 1
  __silt__NAMES=''

  while [ "$__silt__name_first_keys__count" -gt 0 ]; do
    __silt__name_key "$__silt__name_first_keys__prefix" "$1" || return 1
    __silt__name_first_keys__count=$((__silt__name_first_keys__count - 1))
    shift
  done
}

: <<'FUN'
Sets __silt__NAMES to the variables that the keys give, each followed by
one space. Refuses a prefix or a key that cannot be part of a variable
name, and two keys that give the same variable.

  __silt__name_keys __close__ id state.type   ->  '__close__id __close__state_type '

args:
  $1  The prefix
  $@  The keys
FUN
__silt__name_keys() {
  __silt__name_keys__prefix="$1"
  shift

  __silt__name_first_keys "$__silt__name_keys__prefix" "$#" "$@"
}

: <<'FUN'
Refuses a prefix that cannot start a variable name.

args:
  $1  The prefix
FUN
__silt__require_prefix() {
  case "$1" in
    # structs-lint: allow -- the spelling of a variable name, checked before an eval; SILT sits beneath structs
    '' | [0-9]* | *[!A-Za-z0-9_]*)
      __silt__fail "a prefix starts a variable name, and '$1' cannot"
      return 1
      ;;
  esac
}

: <<'FUN'
Sets __silt__NAME to the variable that a key gives, and adds it to
__silt__NAMES. Refuses a key that cannot be part of a variable name, and a
variable that an earlier key gave.

  __silt__name_key __close__ state.type   ->  __close__state_type

args:
  $1  The prefix
  $2  The key
FUN
__silt__name_key() {
  case "$2" in
    # structs-lint: allow -- the spelling of a variable name, checked before an eval; SILT sits beneath structs
    '' | .* | *. | *..* | *[!A-Za-z0-9_.]*)
      __silt__fail "a key is names joined by dots, and '$2' is not; read that field with silt__get"
      return 1
      ;;
  esac

  __silt__underscored "$2"
  __silt__NAME="$1$__silt__UNDERSCORED"

  case " $__silt__NAMES" in
    *" $__silt__NAME "*)
      __silt__fail "two keys give the variable $__silt__NAME"
      return 1
      ;;
  esac
  __silt__NAMES="$__silt__NAMES$__silt__NAME "
}

: <<'FUN'
Sets __silt__UNDERSCORED to the text with every dot replaced by an
underscore.

  __silt__underscored state.type   ->  state_type

args:
  $1  The text
FUN
__silt__underscored() {
  __silt__UNDERSCORED=''
  __silt__underscored__rest="$1"

  while [ "$__silt__underscored__rest" != "${__silt__underscored__rest#*.}" ]; do
    __silt__UNDERSCORED="$__silt__UNDERSCORED${__silt__underscored__rest%%.*}_"
    __silt__underscored__rest="${__silt__underscored__rest#*.}"
  done

  __silt__UNDERSCORED="$__silt__UNDERSCORED$__silt__underscored__rest"
}

: <<'FUN'
Assigns the field at a key to the variable the key gives.

args:
  $1  The prefix
  $2  The document
  $3  The key
FUN
__silt__bind_key() {
  __silt__underscored "$3"
  __silt__bind_key__name="$1$__silt__UNDERSCORED"

  __silt__bind_key__value=''
  silt__get __silt__bind_key__value "$2" ".$3" || return 1
  __silt__bound_text "$__silt__bind_key__value" || return 1

  eval "$__silt__bind_key__name=\$__silt__ANSWER"
}

: <<'FUN'
Sets __silt__ANSWER to what a variable receives for a value: the empty
string for a null or no value, the document for a map or a list, and the
text for any other value.

args:
  $1  The value silt__get answered, a document or nothing
FUN
__silt__bound_text() {
  case "$1" in
    # structs-lint: allow -- a first line with a key opens a collection; SILT sits beneath structs
    '' | 0.:null) __silt__ANSWER='' ;;
    0.:map | 0.:list | 0.[!:]*) __silt__ANSWER="$1" ;;
    *) __silt__string_of_scalar "$1" || return 1 ;;
  esac
}

: <<'FUN'
Keeps what each variable holds now, for the call of silt__with that is
running: its value, and whether it is set at all.

args:
  $1  The variables' names, each followed by one space
FUN
__silt__save() {
  __silt__save__rest="$1"

  while [ -n "$__silt__save__rest" ]; do
    __silt__save__name="${__silt__save__rest%% *}"
    __silt__save__rest="${__silt__save__rest#* }"
    eval "__silt__saved_${__silt__WITHS}_$__silt__save__name=\${$__silt__save__name-}"
    eval "__silt__was_set_${__silt__WITHS}_$__silt__save__name=\${$__silt__save__name+true}"
  done
}

: <<'FUN'
Puts each variable back as __silt__save found it, for the call of
silt__with that is running.

args:
  $1  The variables' names, each followed by one space
FUN
__silt__restore() {
  __silt__restore__rest="$1"

  while [ -n "$__silt__restore__rest" ]; do
    __silt__restore__name="${__silt__restore__rest%% *}"
    __silt__restore__rest="${__silt__restore__rest#* }"
    __silt__restore_one "$__silt__restore__name"
  done
}

: <<'FUN'
Puts one variable back as __silt__save found it: its value when it was
set, and unset when it was not.

args:
  $1  The variable's name
FUN
__silt__restore_one() {
  if eval "[ \"\$__silt__was_set_${__silt__WITHS}_$1\" = true ]"; then
    eval "$1=\$__silt__saved_${__silt__WITHS}_$1"
  else
    unset "$1"
  fi
  unset "__silt__saved_${__silt__WITHS}_$1" "__silt__was_set_${__silt__WITHS}_$1"
}

: <<'FUN'
Unsets each variable.

args:
  $1  The variables' names, each followed by one space
FUN
__silt__release() {
  __silt__release__rest="$1"

  while [ -n "$__silt__release__rest" ]; do
    unset "${__silt__release__rest%% *}"
    __silt__release__rest="${__silt__release__rest#* }"
  done
}
