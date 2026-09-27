#!/bin/sh

: <<'MODULE'
The translators: a JSON, a YAML or a TOML document read into SILT, and a
SILT document written out as any of the three. Each is one awk start, the
document in on stdin, and each reader answers with every map in canonical
order.
MODULE

: <<'PUB_FUN'
Answers the JSON document on stdin as a SILT document. A str's literal and a
number's text are copied as written, and every map comes out in canonical
order. Refuses text that is not one JSON value, a map that holds a key
twice, and a number outside 64 bits or binary64, naming the line.

  silt__from_json doc < map.json   ->  doc='0."a":null
  0."b":list
  1.0:int=1'

args:
  $1  The name of the variable to answer in
PUB_FUN
silt__from_json() {
  __silt__out "$1" || return 1
  __silt__from_json__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__translate_stdin 'order translators/write translators/json/from' || return 1

  __silt__OUT="$__silt__from_json__out"
  __silt__answer
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
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__to_json() {
  __silt__out "$1" || return 1
  __silt__to_json__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__hand_off "$2" translators/json/to || return 1

  __silt__OUT="$__silt__to_json__out"
  __silt__answer
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
  $1  The name of the variable to answer in
PUB_FUN
silt__from_yaml() {
  __silt__out "$1" || return 1
  __silt__from_yaml__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__translate_stdin 'order translators/write translators/numbers translators/yaml/lines translators/yaml/scalars translators/yaml/values translators/yaml/flow translators/yaml/blocks translators/yaml/tree translators/yaml/from' || return 1

  __silt__OUT="$__silt__from_yaml__out"
  __silt__answer
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
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__to_yaml() {
  __silt__out "$1" || return 1
  __silt__to_yaml__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__hand_off "$2" 'translators/numbers translators/yaml/lines translators/yaml/scalars translators/yaml/to' || return 1

  __silt__OUT="$__silt__to_yaml__out"
  __silt__answer
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
  $1  The name of the variable to answer in
PUB_FUN
silt__from_toml() {
  __silt__out "$1" || return 1
  __silt__from_toml__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__translate_stdin 'order translators/write translators/numbers translators/toml/text translators/toml/strings translators/toml/tree translators/toml/times translators/toml/scalars translators/toml/values translators/toml/from' || return 1

  __silt__OUT="$__silt__from_toml__out"
  __silt__answer
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
  $1  The name of the variable to answer in
  $2  The document
PUB_FUN
silt__to_toml() {
  __silt__out "$1" || return 1
  __silt__to_toml__out="$__silt__OUT"

  __silt__ANSWER=''
  __silt__hand_off "$2" 'translators/toml/spell translators/toml/to' || return 1

  __silt__OUT="$__silt__to_toml__out"
  __silt__answer
}

: <<'FUN'
Runs awk programs of the tier over the caller's stdin, and takes what they
print as the answer.

args:
  $1  The programs' names under shell/silt/awk, without .awk, separated by
      spaces
FUN
__silt__translate_stdin() {
  __silt__HANDED=true
  __silt__HANDED_OUT="$(__silt__tier "$1")" || return $?
  __silt__absorb_handed
}
