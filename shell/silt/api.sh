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

Every verb answers in the variable the caller names first, and none but
silt__now starts a process: a verb splits the document into its positional
parameters once, in C, with IFS a newline and globbing off, and reads a line
at a time from there; SILT has no empty line, which a split would drop. A
predicate answers in a register rather than printing, which would cost the
subshell the library exists to avoid. A document past __silt__THRESHOLD
lines belongs to the awk tier, which answers the same call the same way.

  silt__type      the kind of value a document is, or of the value at a path
  silt__get       the value at a path, or at the first of several paths
  silt__scalar    the value text of a scalar document
  silt__string    the text at a path, or at the first of several paths
  silt__has       whether a path holds a value
  silt__bind      fields of a document assigned to variables
  silt__unbind    the variables of silt__bind unset
  silt__with      a command run with fields assigned to variables
  silt__len       the number of members
  silt__keys      the members' keys, as a list document
  silt__each      a callback per member, with its key and its value
  silt__map       every member's value replaced by what a callback answers
  silt__reduce    one value built from the members by a callback
  silt__apply     a command run with a list's elements as its arguments
  silt__filter    the members a predicate keeps
  silt__find      the first member's value a predicate takes
  silt__any       whether a predicate takes any member
  silt__all       whether a predicate takes every member
  silt__text_is   a predicate: whether the text at a path is the text given
  silt__text_is_not a predicate: whether the text at a path differs from the text given
  silt__text_starts_with a predicate: whether the text at a path starts with a prefix
  silt__pluck     the value at a path in each member, as a list
  silt__project   the members named of each member, as a list of maps
  silt__unwrap    a JSON string literal to text
  silt__wrap      text to a JSON string literal
  silt__str       a str document from text
  silt__time      a time document from a date-time string with a UTC offset
  silt__now       a time document for the current time
  silt__obj       a map from key and document pairs
  silt__arr       a list from documents
  silt__push      documents appended to a list, or to the list at a path
  silt__set       a document placed at a path, or several at their paths
  silt__patch     as silt__set, leaving out every value that is empty
  silt__concat    two lists, one after the other
  silt__join      a list's scalars as one text
  silt__split     text cut on a separator, as a list of str
  silt__canon     the document with every map in canonical order
  silt__equals    whether two documents are the same value
  silt__is_true   whether a document is the bool true
  silt__is_false  whether a document is the bool false
  silt__is_zero   whether a document is the int 0
  silt__not       the opposite of a bool
  silt__defined   whether a value is a document and is not a null
  silt__empty     whether a map or a list has no members
  silt__bool      a bool document from the word true or false
  silt__null      the null document
  silt__option    the text of one option in a map of options, or a default
  silt__option_is whether one option has the text given
  silt__succeeds  whether a command exits with status 0
  silt__fails     whether a command exits with another status
  silt__first     the first element of a list
  silt__last      the last element of a list
  silt__slice     the elements of a list from one index up to another
  silt__pop       the last element of a list, and the list without it
  silt__shift     the first element of a list, and the list without it
  silt__take      the first elements of a list, as many as asked
  silt__take_last the last elements of a list, as many as asked
  silt__sum       the sum of a list of numbers
  silt__values    a map's values as a list
  silt__entries   a map as a list of its keys and values
  silt__unique    a list with its repeated values dropped
  silt__difference the elements of a list another does not hold
  silt__intersect the elements of a list another holds too
  silt__merge     one map laid over another, one level deep
  silt__deepmerge one map laid over another, at every depth
  silt__flatten   a tree of named nodes as one map, keyed by the path to each
  silt__references the other schema documents a schema refers to
  silt__validate  the validation errors of a document against a JSON Schema
  silt__read      the document a text spells, written as SILT or as JSON
  silt__to_line   a document written on one line
  silt__from_line a document read back from one line
  silt__from_json the JSON on stdin as a document
  silt__to_json   a document as one line of JSON
  silt__dump      a document as text for a person to read, YAML by default
  silt__load      a JSON file as a document, checked against a schema file
  silt__pick      a map with only the keys given
  silt__without   a map without the keys given
  silt__from_yaml the YAML on stdin as a document
  silt__to_yaml   a document as YAML in block style
  silt__from_toml the TOML on stdin as a document
  silt__to_toml   a document as TOML, its tables under headers
  silt__from_strh the .strh on stdin as a document, its id column dropped
  silt__from_strt the .strt on stdin as a document, its codes spelled out
  silt__to_strh   a document as .strh text, a LID drawn for every line
  silt__to_strt   a document as .strt text, its keys and types as codes

A verb with a callback calls it as a verb is called: the answer variable's
name, the member's key as text, its value as a document, then the caller's
extras. A callback can run any verb, a loop of its own included.

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
. "$__silt__DIR/bind.sh"
. "$__silt__DIR/len.sh"
. "$__silt__DIR/keys.sh"
. "$__silt__DIR/each.sh"
. "$__silt__DIR/walk.sh"
. "$__silt__DIR/nest.sh"
. "$__silt__DIR/str.sh"
. "$__silt__DIR/time.sh"
. "$__silt__DIR/obj.sh"
. "$__silt__DIR/arr.sh"
. "$__silt__DIR/push.sh"
. "$__silt__DIR/set.sh"
. "$__silt__DIR/paths.sh"
. "$__silt__DIR/concat.sh"
. "$__silt__DIR/join.sh"
. "$__silt__DIR/split.sh"
. "$__silt__DIR/canon.sh"
. "$__silt__DIR/first.sh"
. "$__silt__DIR/slice.sh"
. "$__silt__DIR/ends.sh"
. "$__silt__DIR/sum.sh"
. "$__silt__DIR/values.sh"
. "$__silt__DIR/entries.sh"
. "$__silt__DIR/unique.sh"
. "$__silt__DIR/difference.sh"
. "$__silt__DIR/intersect.sh"
. "$__silt__DIR/merge.sh"
. "$__silt__DIR/deepmerge.sh"
. "$__silt__DIR/flatten.sh"
. "$__silt__DIR/validate.sh"
. "$__silt__DIR/translate.sh"
. "$__silt__DIR/read.sh"
. "$__silt__DIR/dump.sh"
. "$__silt__DIR/load.sh"
. "$__silt__DIR/pick.sh"
. "$__silt__DIR/callback.sh"
. "$__silt__DIR/gather.sh"
. "$__silt__DIR/map.sh"
. "$__silt__DIR/reduce.sh"
. "$__silt__DIR/apply.sh"
. "$__silt__DIR/filter.sh"
. "$__silt__DIR/find.sh"
. "$__silt__DIR/any.sh"
. "$__silt__DIR/all.sh"
. "$__silt__DIR/text_is.sh"
. "$__silt__DIR/text_is_not.sh"
. "$__silt__DIR/text_starts_with.sh"
. "$__silt__DIR/pluck.sh"
. "$__silt__DIR/project.sh"
. "$__silt__DIR/truth.sh"
. "$__silt__DIR/defined.sh"
. "$__silt__DIR/bool.sh"
. "$__silt__DIR/option.sh"
. "$__silt__DIR/command.sh"
