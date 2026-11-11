#!/bin/sh

: <<'MODULE'
silt__run: a caller's awk program run over a document, in one process.

The line library and tree.awk are loaded ahead of the program, so it reads
the document as a tree of nodes and prints its answer as lines
(shell/silt/awk/tree.awk says how). The program runs under LC_ALL=C, so it
reads bytes. Its own status is the verb's, and what it writes on stderr
reaches the caller's.
MODULE

: <<'PUB_FUN'
Runs an awk program over a document in one process, and answers what the
program prints: a document, or plain text. A caller uses it for a
transformation that loops over the members of a document.

A document given with --with is read ahead of the main one, with
tree_ahead(). A value given with --arg is read with arg("<name>"). A file
given with --load is an awk library, loaded ahead of the program, so two
programs can share the functions they must agree on.

Refuses a program or a library that is not a file, no document, and an
option it does not know.

  silt__run names "$dir/names.awk" "$records"
  silt__run diff "$dir/diff.awk" "$desired" --with "$actual" --arg since "$since"
  silt__run order "$dir/fifo.awk" "$entries" --load "$dir/order.awk"

args:
  $1  The name of the variable to answer in
  $2  The awk program, a file
  $3  The document
  --with <document>     A further document, read ahead of the main one
  --arg <name> <value>  A value the program reads by name; the name is
                        letters, digits and underscores
  --load <file>         An awk library, loaded ahead of the program; its
                        path holds no newline

registers:
  __silt__run__AHEAD       The documents given with --with, each followed
                           by the line that ends it
  __silt__run__LIBRARIES   The libraries given with --load, one on each line
  __silt__run__LEFT        How many of the caller's arguments are still to
                           be read
  __silt__run__TAKEN       How many arguments the option last read took
  __silt__run__ASSIGNMENT  The environment assignment the option last read
                           gives awk, empty when it gives none
PUB_FUN
silt__run() {
  __silt__out "$1" || return 1
  __silt__run__out="$__silt__OUT"
  __silt__run__program="${2-}"
  __silt__run__document="${3-}"
  __silt__run__check "$__silt__run__program" "$__silt__run__document" || return 1
  shift 3

  __silt__run__AHEAD=''
  __silt__run__LIBRARIES=''
  __silt__run__LEFT=$#
  while [ "$__silt__run__LEFT" -gt 0 ]; do
    __silt__run__option "$@" || return 1
    # structs-lint: allow -- SILT sits beneath structs, so awk's environment is built in the positionals
    set -- "$@" ${__silt__run__ASSIGNMENT:+"$__silt__run__ASSIGNMENT"}
    shift "$__silt__run__TAKEN"
    __silt__run__LEFT=$((__silt__run__LEFT - __silt__run__TAKEN))
  done

  # structs-lint: allow -- SILT sits beneath structs, so awk's command line is built in the positionals
  set -- "$@" LC_ALL=C awk -f "$__silt__DIR/awk/lines.awk" -f "$__silt__DIR/awk/tree.awk"
  __silt__split_lines
  for __silt__run__file in $__silt__run__LIBRARIES; do
    # structs-lint: allow -- SILT sits beneath structs, so awk's command line is built in the positionals
    set -- "$@" -f "$__silt__run__file"
  done
  __silt__split_over

  __silt__ANSWER="$(__silt__run__feed | env "$@" -f "$__silt__run__program")" || return $?
  __silt__OUT="$__silt__run__out"
  __silt__answer
}

: <<'FUN'
Prints what the program reads on stdin: every document given with --with,
each followed by the line that ends it, and then the main document.
FUN
__silt__run__feed() {
  printf '%s%s\n' "$__silt__run__AHEAD" "$__silt__run__document"
}

: <<'FUN'
Refuses a program that is not a file, and a call with no document.

args:
  $1  The program
  $2  The document
FUN
__silt__run__check() {
  if [ ! -f "$1" ]; then
    __silt__fail "run takes an awk program in a file, and '$1' is not a file"
    return 1
  fi
  if [ -z "$2" ]; then
    __silt__fail "run takes a document after its program, and none was given"
    return 1
  fi
}

: <<'FUN'
Reads the option that the caller's arguments open with. Sets
__silt__run__TAKEN to how many arguments it took, and
__silt__run__ASSIGNMENT to the environment assignment it gives awk, or to
nothing. Refuses an option it does not know.

args:
  $@  The caller's arguments from the option on
FUN
__silt__run__option() {
  __silt__run__ASSIGNMENT=''

  case "$1" in
    --with) __silt__run__with "$@" ;;
    --arg) __silt__run__arg "$@" ;;
    --load) __silt__run__load "$@" ;;
    *) __silt__fail "run does not know the option '$1'; it takes --with <document>, --arg <name> <value> and --load <file>" ;;
  esac
}

: <<'FUN'
Reads --with <document>: adds the document to __silt__run__AHEAD.

args:
  $@  The caller's arguments from --with on
FUN
__silt__run__with() {
  __silt__run__needs 2 --with || return 1

  __silt__run__AHEAD="$__silt__run__AHEAD$2$__silt__NL$__silt__RS$__silt__NL"
  __silt__run__TAKEN=2
}

: <<'FUN'
Reads --arg <name> <value>: sets __silt__run__ASSIGNMENT to the assignment
that gives awk the value. Refuses a name that no variable can have.

args:
  $@  The caller's arguments from --arg on
FUN
__silt__run__arg() {
  __silt__run__needs 3 --arg || return 1

  case "$2" in
    # structs-lint: allow -- the spelling of a variable name, checked before it joins the environment; SILT sits beneath structs
    '' | *[!A-Za-z0-9_]*)
      __silt__fail "run takes a name of letters, digits and underscores after --arg, not '$2'"
      return 1
      ;;
  esac

  __silt__run__ASSIGNMENT="SILT_ARG_$2=$3"
  __silt__run__TAKEN=3
}

: <<'FUN'
Reads --load <file>: adds the library to __silt__run__LIBRARIES. Refuses
one that is not a file.

args:
  $@  The caller's arguments from --load on
FUN
__silt__run__load() {
  __silt__run__needs 2 --load || return 1
  if [ ! -f "$2" ]; then
    __silt__fail "run takes an awk library in a file after --load, and '$2' is not a file"
    return 1
  fi

  __silt__run__LIBRARIES="$__silt__run__LIBRARIES${__silt__run__LIBRARIES:+$__silt__NL}$2"
  __silt__run__TAKEN=2
}

: <<'FUN'
Refuses an option that has fewer arguments left than it takes.

args:
  $1  How many arguments the option takes, itself among them
  $2  The option, for the message
FUN
__silt__run__needs() {
  if [ "$__silt__run__LEFT" -lt "$1" ]; then
    __silt__fail "run was given $2 without what follows it"
    return 1
  fi
}
