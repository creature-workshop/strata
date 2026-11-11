#!/bin/sh

: <<'MODULE'
silt__run: a caller's awk program run over a document, in one process.
MODULE

: <<'PUB_FUN'
Runs an awk program over a document in one process, and answers what the
program prints: a document, or plain text. A caller uses it for a
transformation that loops over the members of a document, where a callback
for each member would cost the caller a verb call for each.

The line library and tree.awk are loaded ahead of the program, so it reads
the document as a tree of nodes and prints its answer as lines
(shell/silt/awk/tree.awk says how). A document given with --with is read
ahead of the main one, with tree_ahead(). A value given with --arg is read
with arg("<name>"). The program runs under LC_ALL=C, so it reads bytes.

Refuses a program that is not a file, no document, and an option it does
not know. The program's own status is the verb's, and what the program
writes on stderr reaches the caller's.

  silt__run names "$dir/names.awk" "$records"
  silt__run diff "$dir/diff.awk" "$desired" --with "$actual" --arg since "$since"

args:
  $1  The name of the variable to answer in
  $2  The awk program, a file
  $3  The document
  --with <document>     A further document, read ahead of the main one
  --arg <name> <value>  A value the program reads by name; the name is
                        letters, digits and underscores
PUB_FUN
silt__run() {
  __silt__out "$1" || return 1
  __silt__run__out="$__silt__OUT"
  __silt__run__program="${2-}"
  __silt__run__document="${3-}"
  __silt__run__check "$__silt__run__program" "$__silt__run__document" || return 1
  shift 3

  __silt__run__ahead=''
  __silt__run__left=$#
  while [ "$__silt__run__left" -gt 0 ]; do
    case "$1" in
      --with)
        __silt__run__needs "$__silt__run__left" 2 --with || return 1
        __silt__run__ahead="$__silt__run__ahead$2$__silt__NL$__silt__RS$__silt__NL"
        __silt__run__left=$((__silt__run__left - 2))
        shift 2
        ;;
      --arg)
        __silt__run__needs "$__silt__run__left" 3 --arg || return 1
        __silt__run__arg_name "$2" || return 1
        # structs-lint: allow -- SILT sits beneath structs, so awk's environment is built in the positionals
        set -- "$@" "SILT_ARG_$2=$3"
        __silt__run__left=$((__silt__run__left - 3))
        shift 3
        ;;
      *)
        __silt__fail "run does not know the option '$1'; it takes --with <document> and --arg <name> <value>"
        return 1
        ;;
    esac
  done

  __silt__ANSWER="$(printf '%s%s\n' "$__silt__run__ahead" "$__silt__run__document" \
    | env "$@" LC_ALL=C awk \
      -f "$__silt__DIR/awk/lines.awk" \
      -f "$__silt__DIR/awk/tree.awk" \
      -f "$__silt__run__program"
  )" || return $?

  __silt__OUT="$__silt__run__out"
  __silt__answer
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
Refuses an option that has fewer arguments left than it takes.

args:
  $1  How many arguments are left, the option among them
  $2  How many the option takes, itself among them
  $3  The option, for the message
FUN
__silt__run__needs() {
  if [ "$1" -lt "$2" ]; then
    __silt__fail "run was given $3 without what follows it"
    return 1
  fi
}

: <<'FUN'
Refuses a name for --arg that an environment variable cannot have.

args:
  $1  The name
FUN
__silt__run__arg_name() {
  case "$1" in
    # structs-lint: allow -- the spelling of a variable name, checked before it joins the environment; SILT sits beneath structs
    '' | *[!A-Za-z0-9_]*)
      __silt__fail "run takes a name of letters, digits and underscores after --arg, not '$1'"
      return 1
      ;;
  esac
}
