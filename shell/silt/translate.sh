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
Answers the JSON document on stdin as a SILT document. A str's literal and a
number's text are copied as written, and the members of a map stay in the
order the JSON wrote them. Refuses text that is not one JSON value, a map that holds a key
twice, and a number outside 64 bits or binary64, naming the line.

  {"b":[1],"a":null}
  silt__from_json doc < map.json   ->  doc='0."b":list
  1.0:int=1
  0."a":null'

  silt__from_json --sort doc < map.json   ->  doc='0."a":null
  0."b":list
  1.0:int=1'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
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
Answers the document as one line of JSON, a str's literal, a number's text
and a key copied as written, a time as a string, and a float JSON cannot
spell, inf, -inf or nan, as the map ADR.20 gives it. Refuses a document that
is not well formed, naming the line.

  silt__to_json text '0."a":null
  0."b":list
  1.0:int=1'   ->  text='{"a":null,"b":[1]}'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The document
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
Answers the YAML document on stdin as a SILT document, the YAML a config or
a pipeline file is written in: block mappings and sequences, plain and
quoted scalars, literal and folded blocks, flow collections on one line, and
comments. A plain scalar is a null, a bool or a number only when YAML's core
schema reads it as one; a number spelled outside ADR.20's patterns becomes
the map ADR.20 gives it. Refuses, naming the line, what it does not read:
an anchor, an alias, a tag, a merge key, a complex key, a directive, a
second document, and a scalar or a flow collection that runs over lines.

  silt__from_yaml doc < pipeline.yml   ->  doc='0."stages":list
  1.0:str="test"'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
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
Answers the document as YAML in block style, a string plain only where a
reader would read it back as the same string, as a literal block when it
runs over lines, and in double quotes, as JSON spells it, everywhere else.
The value survives a trip back through silt__from_yaml.

  silt__to_yaml text '0."stages":list
  1.0:str="test"'   ->  text='stages:
    - test'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The document
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
Answers the TOML document on stdin as a SILT document: every construct of
TOML 1.0, the four string forms, integers in four bases, floats, booleans,
date-times, arrays, inline tables, tables and arrays of tables. An offset
date-time is a time in UTC with nine fraction digits; a number spelled
outside ADR.20's patterns, and a local date-time, which names no instant,
become the map ADR.20 gives a spelling Strata cannot carry. Refuses what
TOML forbids, naming the line: a key or a table defined twice, a table a
dotted key defined given a header, an inline table that runs over lines,
text after a value, a string that never closes, an escape TOML has no name
for, a control character, a date with a day its month has not, a fraction
past nine digits, and an int outside 64 bits.

  silt__from_toml doc < Cargo.toml   ->  doc='0."package":map
  1."name":str="tool"
  1."version":str="1.2.3"'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
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
Answers the document as TOML, a map document being a table: a table's
pairs first, "key = value" with an array or an inline table on one line,
then each map under its header and each list of maps as an array of
tables. A str is a basic string, a number and a bool are as written, a time
is an offset date-time, and a null, which TOML has no spelling for, is the
map ADR.20 gives a value the target cannot carry. The empty map is the
empty document. Refuses a document whose root is a list or a scalar, and
one that is not well formed, naming the line. The value survives a trip
back through silt__from_toml.

  silt__to_toml text '0."package":map
  1."name":str="tool"'   ->  text='[package]
  name = "tool"'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The document
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
Answers the .strh document on stdin as a SILT document: every line with its
LID and the space after it removed, nothing else changed (ADR.32@strata).
Refuses a line that does not open with a LID, sixteen lowercase hex
characters, and an empty document, naming the line.

  silt__from_strh doc < jobs.strh   ->  doc='0."runner":str="bats"'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
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
Answers the .strt document on stdin as a SILT document, its codes spelled out
(ADR.16@strata): a key written as @ and a code becomes the key with that code
in the corpus's index, a type written as a code becomes its name, and a
bool's 1 or 0 becomes true or false. The index is the corpus's keys as a
list of str in code order, from 0: the header's index plucked of its key.
Refuses a code the list lacks, a type code no natural primitive has, a key
or a type not written as a code, a bool spelled otherwise, and an empty
document, naming the line.

  silt__from_strt doc '0.0:str="clean"
  0.1:str="ready"' < flags.strt   ->  doc='0."ready":bool=true', from 0.@1:-4=1

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The corpus's keys, a list of str in code order
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
Answers the document as .strt text (ADR.16@strata): a map's key as @ and its
code in the corpus's index, a type as its code, a bool as 1 or 0, and the
depth, an index and every other value as written. The index is the corpus's
keys as a list of str in code order, read as it is: a key it lacks is
refused, naming the line, as a closed header refuses one (ADR.8@strata);
appending a key to an open header is the corpus writer's. Refuses too a type
no natural primitive names, and an empty document.

  silt__to_strt terse '0."ready":bool=true' '0.0:str="clean"
  0.1:str="ready"'   ->  terse='0.@1:-4=1'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The document
  $3          The corpus's keys, a list of str in code order
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
Answers the document as the .strh text a corpus keeps: every line with its
LID and one space in front, the LID drawn from the corpus's two seeds, the
document's number and the line's place, from 1 (ADR.11@strata,
ADR.9@strata). Nothing else changes, so a document written back to its
number draws the LIDs it had. The text has no final newline; a file gets one
(ADR.19@strata).

  silt__to_strh stored '0."runner":str="bats"' 1299709 104729 1
    ->  stored='67e924b179c7e1f3 0."runner":str="bats"'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The document
  $3          The doc-seed, 1 to 2147483398
  $4          The line-seed, 1 to 2147483562
  $5          The document's number in the corpus, 0 for the header
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
