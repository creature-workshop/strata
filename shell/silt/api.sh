#!/bin/sh

: <<'MODULE'
SILT, structured inline live text: a Strata document carried between shell
functions without its id column (ADR.32@strata), read without a process.

A document is lines, one node each: "<depth>.<key>:<type>" for a collection
or a null, "<depth>.<key>:<type>=<value>" for a leaf (ADR.2@strata). It is
held in a variable without its final newline. The lines at depth 0 are the
document's members, string keys making it a map and indices a list
(ADR.4@strata), and one keyless line makes it a scalar (ADR.12@strata). A
str's value is its JSON literal, quotes and escapes included (ADR.3@strata).

Every verb answers in the variable the caller names first, and none starts a
process: a verb splits the document into its own positional parameters once,
in C, with IFS a newline and globbing off, and reads a line at a time from
there; SILT has no empty line, which a split would drop. A predicate answers
in a register rather than printing, since printing would cost the subshell
the library exists to avoid. A document past __silt__THRESHOLD lines belongs
to the awk tier, which answers the same call the same way.

  silt__type      the kind of value a document is
  silt__get       the value at a path, as a document of its own
  silt__scalar    the value text of a scalar document
  silt__string    the text at a path, a str unquoted
  silt__has       whether a path holds a value
  silt__len       the number of members
  silt__keys      the members' keys, as a list document
  silt__each      a callback per member, with its key and its value
  silt__map       every member's value replaced by what a callback answers
  silt__filter    the members a predicate keeps
  silt__find      the first member's value a predicate takes
  silt__any       whether a predicate takes any member
  silt__all       whether a predicate takes every member
  silt__pluck     the value at a path in each member, as a list
  silt__project   the members named of each member, as a list of maps
  silt__unwrap    a JSON string literal to text
  silt__wrap      text to a JSON string literal
  silt__str       a str document from text
  silt__obj       a map from key and document pairs
  silt__arr       a list from documents
  silt__push      documents appended to a list
  silt__set       a document placed at a path
  silt__concat    two lists, one after the other
  silt__join      a list's scalars as one text
  silt__split     text cut on a separator, as a list of str
  silt__canon     the document with every map in canonical order
  silt__equals    whether two documents are the same value
  silt__is_true   whether a document is the bool true
  silt__is_false  whether a document is the bool false
  silt__is_zero   whether a document is the int 0
  silt__from_json the JSON on stdin as a document
  silt__to_json   a document as one line of JSON
  silt__from_yaml the YAML on stdin as a document
  silt__to_yaml   a document as YAML in block style
  silt__from_toml the TOML on stdin as a document
  silt__to_toml   a document as TOML, its tables under headers

A verb with a callback calls it as a verb is called: the answer variable's
name, the member's key as text, its value as a document, then the caller's
extras. It may run any verb but each and the verbs over it: no recursion.

A path names members from the top: ".a.b" the member b of the member a,
".a[2]" the third element of the list a, ".[0]" the first element of a list
document, and a key holding "." or "[" is quoted the way JSON spells it,
`."test/a.bats"` or `["test/a.bats"]`, and is matched by that spelling.

A caller sources api.sh alone; SILT_DIR names this directory where the shell
cannot tell (dash).
MODULE

: <<'FUN'
Sets __silt__DIR to the directory api.sh sits in, and __silt__LOGS to the
shell-logs library beside it. Refuses when parse.sh is not there, or when
the shell-logs submodule is not checked out.
FUN
__silt__home() {
  __silt__guess_home

  if [ ! -f "$__silt__DIR/parse.sh" ]; then
    printf 'silt: %s holds no parse.sh; set SILT_DIR to the directory of api.sh\n' "$__silt__DIR" >&2
    return 1
  fi

  __silt__LOGS="$__silt__DIR/../.logs/shell/log/api.sh"
  if [ ! -f "$__silt__LOGS" ]; then
    printf 'silt: shell-logs is not checked out at %s; run git submodule update --init\n' "$__silt__DIR/../.logs" >&2
    return 1
  fi
}

: <<'FUN'
Sets __silt__DIR to the best guess at api.sh's directory: SILT_DIR when set;
otherwise the directory of the file being sourced, which bash names in
BASH_SOURCE and other shells only as $0, and "." when that has no directory.
FUN
__silt__guess_home() {
  if [ -n "${SILT_DIR:-}" ]; then
    __silt__DIR="$SILT_DIR"
    return
  fi

  # shellcheck disable=SC3028  # read only where bash set it, empty elsewhere
  __silt__DIR="${BASH_SOURCE:-$0}"

  case "$__silt__DIR" in
    */*) __silt__DIR="${__silt__DIR%/*}" ;;
    *) __silt__DIR=. ;;
  esac
}

__silt__home || return 1
. "$__silt__LOGS"
. "$__silt__DIR/constants.sh"
. "$__silt__DIR/answer.sh"
. "$__silt__DIR/parse.sh"
. "$__silt__DIR/text.sh"
. "$__silt__DIR/path.sh"
. "$__silt__DIR/type.sh"
. "$__silt__DIR/get.sh"
. "$__silt__DIR/scalar.sh"
. "$__silt__DIR/string.sh"
. "$__silt__DIR/has.sh"
. "$__silt__DIR/len.sh"
. "$__silt__DIR/keys.sh"
. "$__silt__DIR/each.sh"
. "$__silt__DIR/walk.sh"
. "$__silt__DIR/nest.sh"
. "$__silt__DIR/str.sh"
. "$__silt__DIR/obj.sh"
. "$__silt__DIR/arr.sh"
. "$__silt__DIR/push.sh"
. "$__silt__DIR/set.sh"
. "$__silt__DIR/concat.sh"
. "$__silt__DIR/join.sh"
. "$__silt__DIR/split.sh"
. "$__silt__DIR/canon.sh"
. "$__silt__DIR/translate.sh"
. "$__silt__DIR/callback.sh"
. "$__silt__DIR/gather.sh"
. "$__silt__DIR/map.sh"
. "$__silt__DIR/filter.sh"
. "$__silt__DIR/find.sh"
. "$__silt__DIR/any.sh"
. "$__silt__DIR/all.sh"
. "$__silt__DIR/pluck.sh"
. "$__silt__DIR/project.sh"
. "$__silt__DIR/truth.sh"
