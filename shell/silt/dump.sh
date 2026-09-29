#!/bin/sh

: <<'MODULE'
Text for people to read: silt__dump writes a document as JSON on several
lines, silt__to_codeblock writes that JSON inside a Markdown code fence,
and silt__from_codeblock reads a document from text that may be inside
one.
MODULE

: <<'PUB_FUN'
Answers the document as JSON on several lines: each member on its own
line, indented by two spaces for each level, with a space after the colon
of a key. An empty map is {} and an empty list is []. It is what jq prints
for a value by default.

  silt__dump text '0."a":null
  0."b":list
  1.0:int=1'   ->  text='{
                     "a": null,
                     "b": [
                       1
                     ]
                   }'

registers:
  __silt__dump__INDENT  The number of spaces for each level while the JSON is
                  written, and empty at any other time

args:
  -s, --sort  Put the members of every map in canonical order
  $1          The name of the variable to answer in
  $2          The document
PUB_FUN
silt__dump() {
  __silt__write_as __silt__dump__json "$@"
}

: <<'FUN'
Sets __silt__ANSWER to the document as JSON on several lines.

args:
  $1  The document
FUN
__silt__dump__json() {
  __silt__dump__INDENT=2
  __silt__dump__json__status=0
  __silt__hand_off "$1" translators/json/to || __silt__dump__json__status=$?
  __silt__dump__INDENT=''

  return "$__silt__dump__json__status"
}

: <<'PUB_FUN'
Answers the document as JSON on several lines inside a Markdown code
fence. The fence has the language tag json, or the tag given. An empty tag
gives a fence with no tag.

  silt__to_codeblock text '0.:int=1'        ->  text='```json
                                                       1
                                                       ```'
  silt__to_codeblock text '0.:int=1' ''     ->  the same, opening with ``` alone

args:
  $1  The name of the variable to answer in
  $2  The document
  $3  The language tag; json when not given
PUB_FUN
silt__to_codeblock() {
  __silt__out "$1" || return 1
  __silt__to_codeblock__out="$__silt__OUT"
  __silt__to_codeblock__tag="${3-json}"

  __silt__to_codeblock__json=''
  silt__dump __silt__to_codeblock__json "${2:-}" || return 1

  __silt__ANSWER="$__silt__FENCE$__silt__to_codeblock__tag$__silt__NL$__silt__to_codeblock__json$__silt__NL$__silt__FENCE"
  __silt__answer_in "$__silt__to_codeblock__out"
}

: <<'PUB_FUN'
Answers the document that a text spells, when the text may be inside a
Markdown code fence. Space around the text is ignored. The text is read as
silt__read reads it. When that fails and the text opens with a fence, the
text inside the fence is read. Refuses text that is not a document either
way.

  silt__from_codeblock doc '```json
  {"a":1}
  ```'   ->  doc='0."a":int=1'

args:
  $1  The name of the variable to answer in
  $2  The text
PUB_FUN
silt__from_codeblock() {
  __silt__out "$1" || return 1
  __silt__from_codeblock__out="$__silt__OUT"

  __silt__dump__trim "${2:-}"
  __silt__from_codeblock__text="$__silt__dump__TRIMMED"
  __silt__from_codeblock__doc=''

  if ! silt__read __silt__from_codeblock__doc "$__silt__from_codeblock__text"; then
    __silt__dump__read_fenced "$__silt__from_codeblock__text" || return 1
    __silt__from_codeblock__doc="$__silt__ANSWER"
  fi

  __silt__ANSWER="$__silt__from_codeblock__doc"
  __silt__answer_in "$__silt__from_codeblock__out"
}

: <<'FUN'
Sets __silt__dump__TRIMMED to the text without the spaces, tabs and newlines at
its start and at its end.

  __silt__dump__trim '  {"a":1}
  '   ->  '{"a":1}'

args:
  $1  The text
FUN
__silt__dump__trim() {
  __silt__dump__TRIMMED="${1#"${1%%[![:space:]]*}"}"
  __silt__dump__TRIMMED="${__silt__dump__TRIMMED%"${__silt__dump__TRIMMED##*[![:space:]]}"}"
}

: <<'FUN'
Sets __silt__ANSWER to the document that the text inside a code fence
spells. The text opens with a fence, which can have a language tag of
letters and digits, and ends with a fence. Refuses any other text, and text
inside the fence that is not a document.

args:
  $1  The text, with no space around it
FUN
__silt__dump__read_fenced() {
  case "$1" in
    # structs-lint: allow -- the shape of a code fence, read by hand; SILT sits beneath structs
    "$__silt__FENCE"*"$__silt__NL"*"$__silt__FENCE") ;;
    *)
      __silt__fail 'the text is not a document, and not a document inside a code fence'
      return 1
      ;;
  esac

  __silt__dump__read_fenced__first="${1%%"$__silt__NL"*}"
  __silt__dump__require_tag "${__silt__dump__read_fenced__first#"$__silt__FENCE"}" || return 1

  __silt__dump__read_fenced__body="${1#*"$__silt__NL"}"
  __silt__dump__trim "${__silt__dump__read_fenced__body%"$__silt__FENCE"}"
  silt__read __silt__ANSWER "$__silt__dump__TRIMMED" && return 0

  __silt__fail 'the text inside the code fence is not a document'
}

: <<'FUN'
Refuses what follows an opening fence on its line when it is not a
language tag: letters and digits, with spaces after them or none.

args:
  $1  The text after the opening fence, to the end of its line
FUN
__silt__dump__require_tag() {
  __silt__dump__trim "$1"

  case "$__silt__dump__TRIMMED" in
    # structs-lint: allow -- the spelling of a language tag, read by hand; SILT sits beneath structs
    *[!A-Za-z0-9]*)
      __silt__fail "a code fence opens with a language tag or nothing, not '$__silt__dump__TRIMMED'"
      return 1
      ;;
  esac
}
