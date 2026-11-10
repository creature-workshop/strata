#!/bin/sh

: <<'MODULE'
silt__from_entries: a map from a list of its keys and values.
MODULE

: <<'PUB_FUN'
Answers a map with one member for each element of a list, the reverse of
silt__entries. Each element is a map that holds the member's key under
"key" and the member's value under "value". The key is a scalar, and its
text becomes the member's key. An element with no "value" gives a null. The
members are in the order of the elements. When two elements have the same
key, the member stays where the first put it and has the value of the last.
The empty list answers the empty map.

Refuses a document that is not a list, an element that is not a map, and an
element whose "key" is missing, a null, a map or a list.

  silt__from_entries doc '0.0:map
  1."key":str="a"
  1."value":int=1
  0.1:map
  1."key":str="b"
  1."value":list
  2.0:int=2'   ->  doc='0."a":int=1
                        0."b":list
                        1.0:int=2'

registers:
  __silt__ENTRY_INDEX  The index of the element being read, empty before
                       the first
  __silt__ENTRY_KEY    That element's key as a line writes it, empty until
                       the walk reads it
  __silt__ENTRY_NODE   What that element's value writes after its key
  __silt__ENTRY_REST   The lines under that element's value, each one level
                       up and with a newline in front of it
  __silt__ENTRY_PART   Which member of the element the walk is inside: key,
                       value, or empty for any other
  __silt__ENTRY_KEYS   The keys read so far, one on each line
  __silt__REPEATED     Whether the walk met a key for the second time

args:
  $1  The name of the variable to answer in
  $2  The list
PUB_FUN
silt__from_entries() {
  __silt__out "$1" || return 1
  __silt__from_entries__out="$__silt__OUT"

  __silt__require_list "$2" from_entries || return 1
  __silt__ANSWER=''
  __silt__ENTRY_INDEX=''
  __silt__ENTRY_KEYS=''
  __silt__REPEATED=false
  __silt__AWK='order elements from_entries'
  __silt__walk "$2" __silt__from_entries__line || return 1
  __silt__from_entries__answer "$2" || return 1

  __silt__OUT="$__silt__from_entries__out"
  __silt__answer
}

: <<'FUN'
Turns what the walk left into the answer. A walk that went to awk left the
answer itself. Any other walk still holds the last element, which is added
now. A walk that met a key for the second time hands the list to awk, which
puts the later value in the earlier member's place. A walk that added no
member answers the empty map.

args:
  $1  The list
FUN
__silt__from_entries__answer() {
  if [ "$__silt__HANDED" = true ]; then
    return 0
  fi
  if [ "$__silt__REPEATED" = false ]; then
    __silt__close_entry || return 1
  fi
  if [ "$__silt__REPEATED" = true ]; then
    __silt__ANSWER=''
    __silt__hand_off "$1" 'order elements from_entries'
    return
  fi
  if [ -z "$__silt__ANSWER" ]; then
    __silt__ANSWER='0.:map'
  fi
}

: <<'FUN'
Handles one line of the walk: an element's own line opens an entry, a line
at depth 1 is a member of the entry, a deeper line is under a member, and
the empty list's one line is passed over.

args:
  $1  The line
FUN
__silt__from_entries__line() {
  case "$1" in
    0.:*) ;;
    0.*) __silt__open_entry "$1" ;;
    1.*) __silt__read_entry_member "$1" ;;
    *) __silt__read_under_entry "$1" ;;
  esac
}

: <<'FUN'
Adds the entry before this one to the answer, and starts reading the
element on this line. Refuses an element that is not a map.

args:
  $1  The element's depth-0 line
FUN
__silt__open_entry() {
  __silt__close_entry || return 1
  if [ "$__silt__REPEATED" = true ]; then
    return 0
  fi

  __silt__parse "$1" || return 1
  if [ "$__silt__TYPE" != map ]; then
    __silt__fail "from_entries takes a map in every element, not a $__silt__TYPE at index $__silt__KEY"
    return 1
  fi

  __silt__ENTRY_INDEX="$__silt__KEY"
  __silt__ENTRY_KEY=''
  __silt__ENTRY_NODE=''
  __silt__ENTRY_REST=''
  __silt__ENTRY_PART=''
}

: <<'FUN'
Reads one member of the element: its "key", its "value", or a member the
verb does not read.

args:
  $1  The member's depth-1 line
FUN
__silt__read_entry_member() {
  __silt__parse "$1" || return 1

  if [ "$__silt__KEY" = '"key"' ]; then
    __silt__read_entry_key
  elif [ "$__silt__KEY" = '"value"' ]; then
    __silt__read_entry_value
  else
    __silt__ENTRY_PART=''
  fi
}

: <<'FUN'
Keeps the key of the element from the line last parsed, as a line writes a
key: a str as it is, and any other scalar as the str that spells its value.
A null, a map and a list leave the element without a key.
FUN
__silt__read_entry_key() {
  __silt__ENTRY_PART=key
  if [ "$__silt__LEAF" = false ]; then
    return 0
  fi

  if [ "$__silt__TYPE" = str ]; then
    __silt__ENTRY_KEY="$__silt__VALUE"
  else
    __silt__wrap_literal "$__silt__VALUE"
    __silt__ENTRY_KEY="$__silt__LITERAL"
  fi
}

: <<'FUN'
Keeps what the value of the element writes after its key, from the line
last parsed, and starts collecting the lines under it.
FUN
__silt__read_entry_value() {
  __silt__ENTRY_PART=value
  __silt__node_text
  __silt__ENTRY_NODE="$__silt__NODE"
  __silt__ENTRY_REST=''
}

: <<'FUN'
Keeps a line that is under the element's value, one level up, and passes
over a line under any other member.

args:
  $1  The line
FUN
__silt__read_under_entry() {
  if [ "$__silt__ENTRY_PART" != value ]; then
    return 0
  fi

  __silt__ENTRY_REST="$__silt__ENTRY_REST$__silt__NL$((${1%%.*} - 1)).${1#*.}"
}

: <<'FUN'
Adds the entry being read to the answer as a member, when one is being
read. Refuses an entry without a key. An entry whose key was read before
ends the walk with __silt__REPEATED true, and is not added.
FUN
__silt__close_entry() {
  if [ -z "$__silt__ENTRY_INDEX" ]; then
    return 0
  fi
  if [ -z "$__silt__ENTRY_KEY" ]; then
    __silt__fail "from_entries takes a scalar under \"key\" in every element, and the element at index $__silt__ENTRY_INDEX has none"
    return 1
  fi

  case "$__silt__NL$__silt__ENTRY_KEYS$__silt__NL" in
    # structs-lint: allow -- whether a key is among the keys read so far, kept one on each line; SILT sits beneath structs
    *"$__silt__NL$__silt__ENTRY_KEY$__silt__NL"*)
      __silt__REPEATED=true
      __silt__STOP=true
      return 0
      ;;
  esac

  __silt__ENTRY_KEYS="$__silt__ENTRY_KEYS$__silt__NL$__silt__ENTRY_KEY"
  __silt__emit "0.$__silt__ENTRY_KEY:${__silt__ENTRY_NODE:-null}$__silt__ENTRY_REST"
  __silt__ENTRY_INDEX=''
}
