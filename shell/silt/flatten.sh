#!/bin/sh

: <<'MODULE'
silt__flatten: a tree of named nodes as one map, each node under the path
to it.

The verb keeps a list of the nodes that are still to be written, and works
through it one node at a time. No function calls itself.
MODULE

: <<'PUB_FUN'
Answers one map for a tree of named nodes. The tree is a map from a name
to a node, and a node can hold more nodes under the child key. Each key of
the answer is the names on the way to a node, joined by the separator.
Each value is the node without its child key. A node comes before the
nodes under it.

  silt__flatten flat "$tree" areas
    {"lib":{"owner":"a","areas":{"log":{"owner":"b"}}}}
      ->  {"lib":{"owner":"a"},"lib.log":{"owner":"b"}}

registers:
  __silt__flatten__FLAT       The map as built so far
  __silt__flatten__TREE       The tree
  __silt__flatten__CHILD_KEY  The child key
  __silt__SEPARATOR           The separator
  __silt__flatten__PENDING    The nodes still to be written, one on each line: the
                              key of the answer as a JSON literal, a tab, and the
                              path of the node in the tree
  __silt__flatten__CHILDREN   The nodes under the node being written, in the same
                              form
  __silt__NODE                The node being written, without its child key

args:
  $1  The name of the variable to answer in
  $2  The tree, a map
  $3  The child key
  $4  The separator; a dot when not given
PUB_FUN
silt__flatten() {
  __silt__out "$1" || return 1
  __silt__flatten__out="$__silt__OUT"

  __silt__require_map "${2:-}" flatten || return 1
  __silt__flatten__TREE="$2"
  __silt__flatten__CHILD_KEY="${3:-}"
  __silt__SEPARATOR="${4-.}"
  __silt__flatten__FLAT='0.:map'

  __silt__flatten__PENDING=''
  __silt__flatten__list_nodes "$__silt__flatten__TREE" '' . || return 1
  __silt__flatten__PENDING="$__silt__flatten__CHILDREN"
  while [ -n "$__silt__flatten__PENDING" ]; do
    __silt__flatten__write_next_node || return 1
  done

  __silt__ANSWER="$__silt__flatten__FLAT"
  __silt__answer_in "$__silt__flatten__out"
}

: <<'FUN'
Sets __silt__flatten__CHILDREN to the nodes of a map of nodes, in their order, in
the form that __silt__flatten__PENDING uses. A value that is not a map, or is the
empty map, gives no nodes.

args:
  $1  The map of nodes, a document or nothing
  $2  The key of the answer for the node that holds them, as text; empty
      at the top of the tree
  $3  The path of the map of nodes in the tree
FUN
__silt__flatten__list_nodes() {
  __silt__flatten__CHILDREN=''

  case "$1" in
    # structs-lint: allow -- a first line with a quoted key opens a map that has members; SILT sits beneath structs
    0."$__silt__QUOTE"*) silt__each "$1" __silt__flatten__list_node "$2" "$3" ;;
  esac
}

: <<'FUN'
Adds one node to __silt__flatten__CHILDREN. It is the callback of silt__each.

args:
  $1  The node's name, as text
  $2  The node, unread here
  $3  The key of the answer for the node above it, as text; empty at the
      top of the tree
  $4  The path in the tree of the map that holds the node
FUN
__silt__flatten__list_node() {
  __silt__wrap_literal "$1"
  __silt__flatten__list_node__path="${4%.}.$__silt__LITERAL"

  __silt__wrap_literal "$3${3:+$__silt__SEPARATOR}$1"
  __silt__flatten__CHILDREN="$__silt__flatten__CHILDREN${__silt__flatten__CHILDREN:+$__silt__NL}$__silt__LITERAL$__silt__TAB$__silt__flatten__list_node__path"
}

: <<'FUN'
Takes the first node off __silt__flatten__PENDING, writes it to the answer without
its child key, and puts the nodes under it at the front of
__silt__flatten__PENDING.
FUN
__silt__flatten__write_next_node() {
  __silt__flatten__write_next_node__node="${__silt__flatten__PENDING%%"$__silt__NL"*}"
  case "$__silt__flatten__PENDING" in
    *"$__silt__NL"*) __silt__flatten__PENDING="${__silt__flatten__PENDING#*"$__silt__NL"}" ;;
    *) __silt__flatten__PENDING='' ;;
  esac
  __silt__flatten__write_next_node__key="${__silt__flatten__write_next_node__node%%"$__silt__TAB"*}"
  __silt__flatten__write_next_node__path="${__silt__flatten__write_next_node__node#*"$__silt__TAB"}"

  __silt__flatten__write_next_node__value=''
  silt__get __silt__flatten__write_next_node__value "$__silt__flatten__TREE" "$__silt__flatten__write_next_node__path" || return 1
  __silt__flatten__write_node "$__silt__flatten__write_next_node__key" "$__silt__flatten__write_next_node__path" "$__silt__flatten__write_next_node__value" || return 1

  __silt__flatten__PENDING="$__silt__flatten__CHILDREN${__silt__flatten__CHILDREN:+${__silt__flatten__PENDING:+$__silt__NL}}$__silt__flatten__PENDING"
}

: <<'FUN'
Writes one node to the answer without its child key, and sets
__silt__flatten__CHILDREN to the nodes under it.

args:
  $1  The key of the answer, a JSON literal
  $2  The path of the node in the tree
  $3  The node, a document
FUN
__silt__flatten__write_node() {
  __silt__flatten__write_node__key="$1"
  __silt__flatten__write_node__path="$2"
  __silt__NODE="$3"
  __silt__flatten__write_node__kind=''
  silt__type __silt__flatten__write_node__kind "$3" || return 1

  __silt__flatten__CHILDREN=''
  if [ "$__silt__flatten__write_node__kind" = map ] && [ "$3" != 0.:map ]; then
    __silt__flatten__split_node "$__silt__flatten__write_node__key" "$__silt__flatten__write_node__path" "$3" || return 1
  fi

  silt__set __silt__flatten__FLAT "$__silt__flatten__FLAT" ".$__silt__flatten__write_node__key" "$__silt__NODE"
}

: <<'FUN'
Takes the child key out of a node that is a map with members: sets
__silt__NODE to the node without it, and __silt__flatten__CHILDREN to the nodes
under it.

args:
  $1  The key of the answer, a JSON literal
  $2  The path of the node in the tree
  $3  The node, a map with members
FUN
__silt__flatten__split_node() {
  __silt__flatten__split_node__key=''
  silt__unwrap __silt__flatten__split_node__key "$1" || return 1
  __silt__wrap_literal "$__silt__flatten__CHILD_KEY"
  __silt__flatten__split_node__path="$2.$__silt__LITERAL"
  __silt__flatten__split_node__node="$3"

  __silt__flatten__split_node__under=''
  silt__get __silt__flatten__split_node__under "$__silt__flatten__split_node__node" ".$__silt__LITERAL" || return 1
  silt__filter __silt__NODE "$__silt__flatten__split_node__node" __silt__flatten__is_another_key "$__silt__flatten__CHILD_KEY" || return 1

  __silt__flatten__list_nodes "$__silt__flatten__split_node__under" "$__silt__flatten__split_node__key" "$__silt__flatten__split_node__path"
}

: <<'FUN'
Answers true when a member's key is not the key given. It is a predicate
for silt__filter.

args:
  $1  The name of the variable to answer in
  $2  The member's key, as text
  $3  The member's value, unread here
  $4  The key to leave out
FUN
__silt__flatten__is_another_key() {
  if [ "$2" = "$4" ]; then
    eval "$1=false"
  else
    eval "$1=true"
  fi
}
