#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/translate.sh: @from_json, @to_json, @from_yaml,
@to_yaml, @from_toml, @to_toml, @from_strh, @from_strt, @to_strt, @to_strh.
FRAGMENT

: <<'PUB_FUN'
Answers the JSON document on stdin as a SILT document. A str's literal and a
number's text are copied as written, and the members of a map stay in the
order the JSON wrote them. Refuses text that is not one JSON value, a map
that holds a key twice, and a number outside 64 bits or binary64, naming the
line.

  {"b":[1],"a":null}
  @from_json doc < map.json

  doc is:
    0."b":list
    1.0:int=1
    0."a":null

  The same, with each SILT document written as JSON:

    @from_json doc < map.json   ->  doc={"b":[1],"a":null}

  @from_json --sort doc < map.json

  doc is:
    0."a":null
    0."b":list
    1.0:int=1

  The same, with each SILT document written as JSON:

    @from_json --sort doc < map.json   ->  doc={"a":null,"b":[1]}

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
PUB_FUN
@from_json() {
  silt__from_json "$@"
}

: <<'PUB_FUN'
Answers the SILT document as one line of JSON, a str's literal, a number's
text and a key copied as written, a time as a string, and a float JSON
cannot spell, inf, -inf or nan, as the map ADR.20 gives it. Refuses a
document that is not well formed, naming the line.

  map="$(cat <<'SILT'
  0."a":null
  0."b":list
  1.0:int=1
  SILT
  )"
  @to_json text "$map"   ->  text='{"a":null,"b":[1]}'

  The same, with each SILT document written as JSON:

    @to_json text {"a":null,"b":[1]}   ->  text='{"a":null,"b":[1]}'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The SILT document
PUB_FUN
@to_json() {
  silt__to_json "$@"
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

  @from_yaml doc < pipeline.yml

  doc is:
    0."stages":list
    1.0:str="test"

  The same, with each SILT document written as JSON:

    @from_yaml doc < pipeline.yml   ->  doc={"stages":["test"]}

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
PUB_FUN
@from_yaml() {
  silt__from_yaml "$@"
}

: <<'PUB_FUN'
Answers the SILT document as YAML in block style, a string plain only where a
reader would read it back as the same string, as a literal block when it
runs over lines, and in double quotes, as JSON spells it, everywhere else.
The value survives a trip back through @from_yaml.

  map="$(cat <<'SILT'
  0."stages":list
  1.0:str="test"
  SILT
  )"
  @to_yaml text "$map"

  text is:
    stages:
      - test

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The SILT document
PUB_FUN
@to_yaml() {
  silt__to_yaml "$@"
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

  @from_toml doc < Cargo.toml

  doc is:
    0."package":map
    1."name":str="tool"
    1."version":str="1.2.3"

  The same, with each SILT document written as JSON:

    @from_toml doc < Cargo.toml   ->  doc={"package":{"name":"tool","version":"1.2.3"}}

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
PUB_FUN
@from_toml() {
  silt__from_toml "$@"
}

: <<'PUB_FUN'
Answers the SILT document as TOML, a map document being a table: a table's
pairs first, "key = value" with an array or an inline table on one line,
then each map under its header and each list of maps as an array of
tables. A str is a basic string, a number and a bool are as written, a time
is an offset date-time, and a null, which TOML has no spelling for, is the
map ADR.20 gives a value the target cannot carry. The empty map is the
empty document. Refuses a document whose root is a list or a scalar, and
one that is not well formed, naming the line. The value survives a trip
back through @from_toml.

  map="$(cat <<'SILT'
  0."package":map
  1."name":str="tool"
  SILT
  )"
  @to_toml text "$map"

  text is:
    [package]
    name = "tool"

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The SILT document
PUB_FUN
@to_toml() {
  silt__to_toml "$@"
}

: <<'PUB_FUN'
Answers the .strh document on stdin as a SILT document: every line with its
LID and the space after it removed, nothing else changed (ADR.32@strata).
Refuses a line that does not open with a LID, sixteen lowercase hex
characters, and an empty document, naming the line.

  @from_strh doc < jobs.strh   ->  doc='0."runner":str="bats"'

  The same, with each SILT document written as JSON:

    @from_strh doc < jobs.strh   ->  doc={"runner":"bats"}

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
PUB_FUN
@from_strh() {
  silt__from_strh "$@"
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

  codes="$(cat <<'SILT'
  0.0:str="clean"
  0.1:str="ready"
  SILT
  )"
  @from_strt doc "$codes" < flags.strt   ->  doc='0."ready":bool=true', from 0.@1:-4=1

  The same, with each SILT document written as JSON:

    @from_strt doc ["clean","ready"] < flags.strt   ->  doc={"ready":true}, from 0.@1:-4=1

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The corpus's keys, a list of str in code order
PUB_FUN
@from_strt() {
  silt__from_strt "$@"
}

: <<'PUB_FUN'
Answers the SILT document as .strt text (ADR.16@strata): a map's key as @
and its code in the corpus's index, a type as its code, a bool as 1 or 0,
and the depth, an index and every other value as written. The index is the
corpus's keys as a list of str in code order, read as it is: a key it lacks
is refused, naming the line, as a closed header refuses one (ADR.8@strata);
appending a key to an open header is the corpus writer's. Refuses too a type
no natural primitive names, and an empty document.

  list="$(cat <<'SILT'
  0.0:str="clean"
  0.1:str="ready"
  SILT
  )"
  @to_strt terse '0."ready":bool=true' "$list"   ->  terse='0.@1:-4=1'

  The same, with each SILT document written as JSON:

    @to_strt terse {"ready":true} ["clean","ready"]   ->  terse='0.@1:-4=1'

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The SILT document
  $3          The corpus's keys, a list of str in code order
PUB_FUN
@to_strt() {
  silt__to_strt "$@"
}

: <<'PUB_FUN'
Answers the SILT document as the .strh text a corpus keeps: every line with
its LID and one space in front, the LID drawn from the corpus's two seeds,
the document's number and the line's place, from 1 (ADR.11@strata,
ADR.9@strata). Nothing else changes, so a document written back to its
number draws the LIDs it had. The text has no final newline; a file gets one
(ADR.19@strata).

  @to_strh stored '0."runner":str="bats"' 1299709 104729 1

  The same, with each SILT document written as JSON:

    @to_strh stored {"runner":"bats"} 1299709 104729 1

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The SILT document
  $3          The doc-seed, 1 to 2147483398
  $4          The line-seed, 1 to 2147483562
  $5          The SILT document's number in the corpus, 0 for the header
PUB_FUN
@to_strh() {
  silt__to_strh "$@"
}
