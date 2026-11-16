#!/bin/sh

: <<'MODULE'
The translators: a JSON, a YAML, a TOML, a .strh or a .strt document read
into SILT, and a SILT document written out as any of the five. Each is one
awk start, the document in on stdin or handed over. The JSON, YAML and TOML
readers keep the members of a map in the order the document wrote them, so
a document that is read and written back has the same order.

Every translator takes -s or --sort before its first argument. A reader
then returns the SILT document in canonical order, and a writer writes the
document in canonical order, as silt__canon orders it. __silt__read_as and
__silt__write_as handle the flag for every translator, so a translator only
defines how it reads or writes.

  silt__from_json --sort doc < map.json
  silt__to_yaml -s text "$doc"
MODULE

: <<'PUB_FUN'
The plumbing of @from_json: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__from_json() {
  __silt__read_as __silt__translate__from_json "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the JSON document on stdin as a SILT document.
FUN
__silt__translate__from_json() {
  __silt__translate__stdin 'translators/write translators/json/from'
}

: <<'PUB_FUN'
The plumbing of @to_json: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__to_json() {
  __silt__write_as __silt__translate__to_json "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the document as JSON.

args:
  $1  The document
FUN
__silt__translate__to_json() {
  __silt__hand_off "$1" translators/json/to
}

: <<'PUB_FUN'
The plumbing of @from_yaml: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__from_yaml() {
  __silt__read_as __silt__translate__from_yaml "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the YAML document on stdin as a SILT document.
FUN
__silt__translate__from_yaml() {
  __silt__translate__stdin 'translators/write translators/numbers translators/yaml/lines translators/yaml/scalars translators/yaml/values translators/yaml/flow translators/yaml/blocks translators/yaml/tree translators/yaml/from'
}

: <<'PUB_FUN'
The plumbing of @to_yaml: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__to_yaml() {
  __silt__write_as __silt__translate__to_yaml "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the document as YAML.

args:
  $1  The document
FUN
__silt__translate__to_yaml() {
  __silt__hand_off "$1" 'translators/numbers translators/yaml/lines translators/yaml/scalars translators/yaml/to'
}

: <<'PUB_FUN'
The plumbing of @from_toml: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__from_toml() {
  __silt__read_as __silt__translate__from_toml "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the TOML document on stdin as a SILT document.
FUN
__silt__translate__from_toml() {
  __silt__translate__stdin 'translators/write translators/numbers translators/toml/text translators/toml/strings translators/toml/tree translators/toml/times translators/toml/scalars translators/toml/values translators/toml/from'
}

: <<'PUB_FUN'
The plumbing of @to_toml: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__to_toml() {
  __silt__write_as __silt__translate__to_toml "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the document as TOML.

args:
  $1  The document
FUN
__silt__translate__to_toml() {
  __silt__hand_off "$1" 'translators/toml/spell translators/toml/to'
}

: <<'PUB_FUN'
The plumbing of @from_strh: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__from_strh() {
  __silt__read_as __silt__translate__from_strh "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the .strh document on stdin as a SILT document.
FUN
__silt__translate__from_strh() {
  __silt__translate__stdin 'translators/strh/from'
}

: <<'PUB_FUN'
The plumbing of @from_strt: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__from_strt() {
  __silt__read_as __silt__translate__from_strt "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the .strt document on stdin as a SILT document.

args:
  $1  The corpus's keys, a list of str in code order
FUN
__silt__translate__from_strt() {
  __silt__require_list "${1:-}" from_strt || return 1

  __silt__ANSWER=''
  __silt__keep_index "$1" || return 1
  __silt__translate__from_strt__status=0
  __silt__translate__stdin 'translators/strt/index translators/strt/from' || __silt__translate__from_strt__status=$?
  __silt__drop_index
  return "$__silt__translate__from_strt__status"
}

: <<'FUN'
Writes the corpus's index to a file of this call's own, and names the file
in __silt__INDEX_FILE. The .strt reader loads the index from the file,
because the document is on the caller's stdin, so there is no stdin to send
the index ahead on. mktemp names the file, so no other call or process
writes the same file. mktemp is not in POSIX.1-2017, but the coreutils, the
BSDs, macOS and BusyBox all have it.

args:
  $1  The corpus's keys, a list of str in code order
FUN
__silt__keep_index() {
  __silt__INDEX_FILE="$(mktemp "${TMPDIR:-/tmp}/silt.XXXXXX")" || return 1
  printf '%s\n' "$1" > "$__silt__INDEX_FILE"
}

: <<'FUN'
Removes the index file, if one was written.
FUN
__silt__drop_index() {
  if [ -n "${__silt__INDEX_FILE-}" ]; then
    rm -f "$__silt__INDEX_FILE"
    __silt__INDEX_FILE=''
  fi
}

: <<'PUB_FUN'
The plumbing of @to_strt: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__to_strt() {
  __silt__write_as __silt__translate__to_strt "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the document as .strt text.

args:
  $1  The document
  $2  The corpus's keys, a list of str in code order
FUN
__silt__translate__to_strt() {
  __silt__require_list "${2:-}" to_strt || return 1
  __silt__hand_off_with "$1" "$2" 'translators/strt/index translators/strt/to'
}

: <<'PUB_FUN'
The plumbing of @to_strh: the same arguments in the same order, and the same
answer. shell/silt/porcelain/_translate.sh documents it.
PUB_FUN
silt__to_strh() {
  __silt__write_as __silt__translate__to_strh "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the document as .strh text.

args:
  $1  The document
  $2  The doc-seed, 1 to 2147483398
  $3  The line-seed, 1 to 2147483562
  $4  The document's number in the corpus, 0 for the header
FUN
__silt__translate__to_strh() {
  __silt__require_in_range doc-seed "${2:-}" 1 2147483398 || return 1
  __silt__require_in_range line-seed "${3:-}" 1 2147483562 || return 1
  __silt__require_in_range number "${4:-}" 0 2147483397 || return 1

  __silt__translate__to_strh__seeds=''
  silt__arr __silt__translate__to_strh__seeds "0.:int=$2" "0.:int=$3" "0.:int=$4" || return 1
  __silt__hand_off_with "$1" "$__silt__translate__to_strh__seeds" translators/strh/to
}

: <<'FUN'
Refuses a seed or a number that is not an int in its range.

args:
  $1  What the value is, for the message: doc-seed, line-seed or number
  $2  The value
  $3  The least it may be
  $4  The most it may be
FUN
__silt__require_in_range() {
  case "$2" in
    # structs-lint: allow -- the digits of an int, checked before arithmetic; SILT sits beneath structs
    '' | *[!0-9]*)
      __silt__fail "the $1 is an int from $3 to $4, not $2"
      return 1
      ;;
  esac

  if [ "$2" -lt "$3" ] || [ "$2" -gt "$4" ]; then
    __silt__fail "the $1 is an int from $3 to $4, not $2"
    return 1
  fi
}

: <<'FUN'
Runs awk programs of the tier over the caller's stdin, and takes what they
print as the answer.

args:
  $1  The programs' names under shell/silt/awk, without .awk, separated by
      spaces
FUN
__silt__translate__stdin() {
  __silt__HANDED=true
  __silt__HANDED_OUT="$(__silt__tier "$1")" || return $?
  __silt__absorb_handed
}

: <<'FUN'
Runs a reader and assigns the SILT document it read to the caller's
variable. With -s or --sort in front of the variable's name, the members of
every map are in canonical order. Without it, they are in the order the
reader gave them.

  __silt__read_as __silt__translate__from_json --sort doc

args:
  $1          The function that reads stdin into __silt__ANSWER. It receives
              the arguments after the variable's name.
  -s, --sort  Put the members of every map in canonical order
  $2          The name of the variable to answer in
  $3...       The reader's other arguments
FUN
__silt__read_as() {
  __silt__read_as__reader="$1"
  shift
  __silt__take_sort_flag "${1:-}"
  if [ "$__silt__SORT" = true ]; then
    shift
  fi
  __silt__out "${1:-}" || return 1
  __silt__read_as__out="$__silt__OUT"
  __silt__read_as__sort="$__silt__SORT"
  shift

  __silt__ANSWER=''
  "$__silt__read_as__reader" "$@" || return $?
  __silt__ordered "$__silt__read_as__sort" "$__silt__ANSWER" || return 1

  __silt__OUT="$__silt__read_as__out"
  __silt__ANSWER="$__silt__ORDERED"
  __silt__answer
}

: <<'FUN'
Runs a writer on a document and assigns the text it wrote to the caller's
variable. With -s or --sort in front of the variable's name, the writer
receives the document in canonical order. Without it, the writer receives
the document as given.

  __silt__write_as __silt__translate__to_json --sort text "$doc"

args:
  $1          The function that writes a document into __silt__ANSWER. It
              receives the document and the arguments after it.
  -s, --sort  Put the members of every map in canonical order
  $2          The name of the variable to answer in
  $3          The document
  $4...       The writer's other arguments
FUN
__silt__write_as() {
  __silt__write_as__writer="$1"
  shift
  __silt__take_sort_flag "${1:-}"
  if [ "$__silt__SORT" = true ]; then
    shift
  fi
  __silt__out "${1:-}" || return 1
  __silt__write_as__out="$__silt__OUT"
  shift

  __silt__ordered "$__silt__SORT" "${1:-}" || return 1
  if [ "$#" -gt 0 ]; then
    shift
  fi

  __silt__ANSWER=''
  "$__silt__write_as__writer" "$__silt__ORDERED" "$@" || return $?

  __silt__OUT="$__silt__write_as__out"
  __silt__answer
}

: <<'FUN'
Sets __silt__SORT to true when the argument is -s or --sort, and to false
otherwise.

args:
  $1  The first argument of a translator
FUN
__silt__take_sort_flag() {
  case "$1" in
    -s | --sort) __silt__SORT=true ;;
    *) __silt__SORT=false ;;
  esac
}

: <<'FUN'
Sets __silt__ORDERED to the document in canonical order when the first
argument is true, and to the document unchanged otherwise.

args:
  $1  true to sort the document
  $2  The document
FUN
__silt__ordered() {
  __silt__ORDERED="$2"
  if [ "$1" != true ]; then
    return 0
  fi

  silt__canon __silt__ORDERED "$2"
}
