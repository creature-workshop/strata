#!/bin/sh

: <<'MODULE'
The translators: a JSON or a YAML document read into SILT, and a SILT
document written out as either. Each is one awk start, the document in on
stdin, and each answers with every map in canonical order.
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
  __silt__translate_stdin 'order translators/write translators/yaml/lines translators/yaml/scalars translators/yaml/values translators/yaml/flow translators/yaml/blocks translators/yaml/tree translators/yaml/from' || return 1

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
  __silt__hand_off "$2" 'translators/yaml/lines translators/yaml/scalars translators/yaml/to' || return 1

  __silt__OUT="$__silt__to_yaml__out"
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
