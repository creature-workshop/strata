# ADR.4: A key is a JSON string under a map, and an index under a list

- Status: approved
- Date: 2026-09-20
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/4
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1178
- Implementation: not started

## Context

A node's key says what it is to its parent. The first form of OPX called it a
role and held it to a lowercase word, `[a-z][a-z0-9-]*`. A key that was no
such word, and `created_at` is none, was written as three lines: an entry, its
name and its value. On real CI records that doubled the line count, and it
turned a number or a boolean into a collection because of how its key was
spelled.

The fix that shipped first wrote such a key quoted and left a lowercase word
bare. That is two spellings of one thing, and a bare `item` still had to be
kept apart from a key spelled `item`.

## Decision

- Under a map, a node's key is written as a JSON string literal: double
  quotes, and JSON's escapes. A key is any JSON string, the empty one
  included.

  ```
  5e71b83c0a2d9f46 1."allow_failure":bool=true
  2d8c15f07a3e9b64 1."a \"quoted\" key: with.dots":int=1
  ```

- Under a list, a node's key is its index: a decimal number, bare, from 0,
  rising by one.

  ```
  0b6d4f92e1a7c358 1."tags":list
  7f2a90c4b5e8d163 2.0:str="landing"
  ```

- The same holds at a document's top level
  ([ADR.2@opx](../000002-one-node-per-line/adr.md)): string keys there make the
  document a map, and indices a list.
- A map MUST NOT hold a key twice. Two keys are the same when they are the
  same text once their escapes are read, so `"a"` and `"a"` are one key.
- A reader MUST refuse a repeated key, and an index that is not the one it
  expected.
- A list MAY hold elements that are alike. No key is reserved.

A terse document writes a string key as a code
([ADR.6@opx](../000006-three-forms/adr.md)). What this ADR says of a key holds
for the key the code stands for.

## Consequences

A key's first character says which kind it is: a quote opens a string, a digit
an index. One pattern finds where a quoted key ends, with no loop over its
characters, so a line still splits in a single pass in `awk`.

A translator from JSON copies a key's text as the source wrote it, and one to
JSON copies it back. A translator from YAML or TOML escapes it once, on the
way in.

A quoted key sits inside single quotes in a shell, so a search for a field is
`grep '\."created_at":'` with nothing to escape.

An index costs bytes a position would not, and it buys a check: a line dropped
or repeated inside a list is caught where it happens. It restarts at 0 in
every list, so it repeats from record to record and compresses to nearly
nothing, unlike a counter that runs through the whole document.

A key that is not a string has no spelling here. YAML allows one, and its
translator refuses it.
