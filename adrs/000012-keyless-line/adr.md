# ADR.12: A keyless line is a document of one value, and a document has at least one line

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/15
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1223
- Implementation: not started

## Context

[ADR.2@opx](../000002-one-node-per-line/adr.md) dropped the root line: the
lines at depth 0 are a map's members or a list's elements, and a document of
one primitive is one line. That left two things unsaid.

A single line `0."primitive":int=1` is both the scalar `1` and the map
`{"primitive":1}`, and JSON's `1` and `{"primitive":1}` must not read back the
same. And a file of zero lines cannot say whether it is an empty map or an
empty list.

## Decision

A line with nothing between its `.` and its `:` has no key. It is a
**keyless line**, and it is the whole document: the document is that value.

```
<depth>.:<type>
<depth>.:<type>=<value>

0.:int=1        the scalar 1            0.:map     the empty map
0.:null         null                    0.:list    the empty list
0."a":int=1     the map {"a":1}         0.0:int=1  the list [1]
```

- A keyless line MUST be at depth 0 and MUST be the document's only line.
- A keyless `map` or `list` therefore has no children. A non-empty collection
  keeps its one spelling: members at depth 0
  ([ADR.4@opx](../000004-keys/adr.md)).
- Below depth 0 a key is always present, a string under a map and an index
  under a list. A reader MUST refuse a keyless line anywhere else.
- A document MUST have at least one line. A reader MUST refuse an empty
  file.
- The terse form writes a keyless line with nothing before the `:` as well:
  `0.:-5=1` ([ADR.6@opx](../000006-three-forms/adr.md)).

## Consequences

Every value has one spelling. `1`, `{"primitive":1}`, `{}` and `[]` are four
different documents, and a translator from JSON writes the root by its kind:
a scalar or an empty collection as one keyless line, a non-empty one as its
members.

A file cut to nothing is refused rather than read as an empty document, so
the one truncation ADR.2 could not catch is caught.

A key's first character now says one of three things: a quote opens a string,
a digit an index, and a colon says there is no key. A line still splits in
one pass.

The header is a map with keys and is never keyless.
