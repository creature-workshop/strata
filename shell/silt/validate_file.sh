#!/bin/sh

: <<'FRAGMENT'
silt__validate_file: validate a document against a JSON Schema in a file,
with the other schema documents it refers to read from the files beside it.
FRAGMENT

: <<'PUB_FUN'
Validates a document against the JSON Schema in a file and returns the
validation errors as a list of strings, as silt__validate does. A valid
document returns an empty list.

When the schema refers to another schema document, the verb reads that
document from the file its key names, relative to the directory of the
schema file. It does the same for every document those refer to, and reads
each file once. A file that does not exist or is not JSON is left out, and
the errors then name the reference to it.

Fails, and says why, when the schema file does not exist or is not JSON,
and when the schema itself is invalid.

  silt__validate_file errors "$manifest" schema/manifest.schema.json
    ->  errors='0.0:str="$.name: expected string, got number"'

args:
  $1  Name of the variable that receives the result
  $2  The document
  $3  The JSON Schema file
PUB_FUN
silt__validate_file() {
  __silt__out "$1" || return 1
  __silt__validate_file__out="$__silt__OUT"
  __silt__validate_file__doc="${2:-}"

  __silt__validate_file__schema=''
  __silt__validate_file__read_schema __silt__validate_file__schema "${3:-}" || return 1
  __silt__validate_file__directory_of "${3:-}"

  __silt__validate_file__check "$__silt__validate_file__doc" "$__silt__validate_file__schema" "$__silt__validate_file__DIRECTORY" || return 1
  __silt__answer__in "$__silt__validate_file__out"
}

: <<'FUN'
Reads the schema file as a document. Fails, and says which file, when the
file does not exist or is not JSON.

args:
  $1  The name of the variable to answer in
  $2  The file
FUN
__silt__validate_file__read_schema() {
  if [ ! -f "$2" ]; then
    __silt__fail "validate_file found no schema at '$2'"
    return 1
  fi

  silt__from_json "$1" < "$2" && return 0
  __silt__fail "validate_file could not read '$2' as JSON"
}

: <<'FUN'
Sets __silt__validate_file__DIRECTORY to the directory of a file, and to
"." for a file named without one.

  __silt__validate_file__directory_of schema/a.json   ->  schema
  __silt__validate_file__directory_of a.json          ->  .

args:
  $1  The file
FUN
__silt__validate_file__directory_of() {
  case "$1" in
    */*) __silt__validate_file__DIRECTORY="${1%/*}" ;;
    *) __silt__validate_file__DIRECTORY=. ;;
  esac
}

: <<'FUN'
Sets __silt__ANSWER to the validation errors of a document against a schema
and every schema document that the schema refers to, directly or through
another. Each one is read from the file its key names under the directory.

registers:
  __silt__validate_file__SEEN  The keys read so far, a newline around each

args:
  $1  The document
  $2  The schema
  $3  The directory of the schema file
FUN
__silt__validate_file__check() {
  __silt__validate_file__check__directory="$3"
  __silt__validate_file__SEEN="$__silt__NL"
  __silt__validate_file__check__pending=''
  silt__references __silt__validate_file__check__pending "$2" || return 1
  set -- "$1" "$2"

  while [ "$__silt__validate_file__check__pending" != 0.:list ]; do
    __silt__validate_file__check__key=''
    __silt__validate_file__next_key __silt__validate_file__check__key || return 1
    __silt__validate_file__read_once "$__silt__validate_file__check__directory" "$__silt__validate_file__check__key"
    if [ -z "$__silt__validate_file__DOCUMENT" ]; then
      continue
    fi

    # structs-lint: allow -- SILT sits beneath structs, so silt__validate's documents are built in the positionals
    set -- "$@" "$__silt__validate_file__check__key" "$__silt__validate_file__DOCUMENT"
    __silt__validate_file__add_references "$__silt__validate_file__DOCUMENT" "$__silt__validate_file__check__key" || return 1
  done

  __silt__validate_file__check__errors=''
  silt__validate __silt__validate_file__check__errors "$@" || return 1
  __silt__ANSWER="$__silt__validate_file__check__errors"
}

: <<'FUN'
Takes the first key off the keys still to be read, and answers it as text.

args:
  $1  The name of the variable to answer in
FUN
__silt__validate_file__next_key() {
  __silt__validate_file__next_key__element=''
  silt__shift __silt__validate_file__next_key__element __silt__validate_file__check__pending "$__silt__validate_file__check__pending" || return 1
  silt__string "$1" "$__silt__validate_file__next_key__element" .
}

: <<'FUN'
Adds the keys that a schema document refers to after the keys still to be
read.

args:
  $1  The schema document
  $2  Its key
FUN
__silt__validate_file__add_references() {
  __silt__validate_file__add_references__keys=''
  silt__references __silt__validate_file__add_references__keys "$1" "$2" || return 1
  silt__concat __silt__validate_file__check__pending "$__silt__validate_file__check__pending" "$__silt__validate_file__add_references__keys"
}

: <<'FUN'
Sets __silt__validate_file__DOCUMENT to the schema document in the file
that a key names under a directory. Sets it to nothing when the key has
been read before, when the file does not exist, and when the file is not
JSON.

args:
  $1  The directory
  $2  The key
FUN
__silt__validate_file__read_once() {
  __silt__validate_file__DOCUMENT=''
  case "$__silt__validate_file__SEEN" in
    *"$__silt__NL$2$__silt__NL"*) return 0 ;;
  esac
  __silt__validate_file__SEEN="$__silt__validate_file__SEEN$2$__silt__NL"

  if [ -f "$1/$2" ]; then
    silt__from_json __silt__validate_file__DOCUMENT < "$1/$2" 2>/dev/null || __silt__validate_file__DOCUMENT=''
  fi
}
