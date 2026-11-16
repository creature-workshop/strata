#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/split.sh: @split.
FRAGMENT

: <<'PUB_FUN'
Cuts text on a separator and builds a list of str from the parts. Empty
parts are dropped. Without a separator the text is cut on newlines.

  @split doc 'a,b' ','

  doc is:
    0.0:str="a"
    0.1:str="b"

  The same, with each SILT document written as JSON:

    @split doc 'a,b' ','   ->  doc=["a","b"]

A one-character separator, a newline included, is cut in one field split. A
longer separator is cut part by part from the front.

args:
  $1  The name of the variable to answer in
  $2  The text; empty when omitted
  $3  The separator; a newline when omitted or empty
PUB_FUN
@split() {
  silt__split "$@"
}
