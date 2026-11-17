# ADR.36: A callback receives the value first, and a verb's suffix says whether the index or the key follows

- Status: approved
- Date: 2026-11-16
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/109
- Implementation: STRATA-261

## Context

A verb that takes a callback calls it with the answer variable, the
member's key, the member's value, and then the caller's extra arguments.
Most callbacks read only the value, and each one still has to step over
the key. shellops' `@map` and `@reduce` pass the value alone, and its
`@mapi` adds the index, so the two libraries disagree about the shape.

An `@` name is exactly its `silt__` verb
([ADR.34@strata](../000034-the-at-verbs-are-silts-porcelain/adr.md)), so
the shape SILT chooses is the one every repository's shell writes.

The key a callback receives is plain text. It does not always read the
member back: `.key` fails for a key that holds a dot, such as
`test/a.bats`, and a list's index needs `.[0]`.

## Decision

A callback receives the answer variable, then the value, then the
caller's extra arguments. A suffix on the verb adds one argument after the
value:

| Suffix | The callback also receives | Verbs |
|---|---|---|
| none | nothing | `silt__map`, `silt__reduce`, `silt__filter`, `silt__find`, `silt__each`, `silt__any`, `silt__all` |
| `i` | the member's position, from 0 | `silt__mapi`, `silt__reducei`, `silt__filteri`, `silt__findi`, `silt__eachi` |
| `k` | the member's key, as plain text | `silt__mapk`, `silt__reducek`, `silt__filterk`, `silt__findk`, `silt__eachk` |

```sh
callback <answer> <value> [extras...]                  # silt__map
callback <answer> <value> <index> [extras...]          # silt__mapi
callback <answer> <value> <key> [extras...]            # silt__mapk
callback <answer> <so far> <value> [extras...]         # silt__reduce
callback <answer> <so far> <value> <key> [extras...]   # silt__reducek
```

- The `i` form gives the position for a list and for a map. The `k` form
  gives a map's key unquoted, and for a list it gives the index.
- `silt__each` has no answer, so its callback receives the value first.
- A predicate answers true or false in the answer variable, as
  [ADR.35@strata](../000035-a-verb-takes-a-predicate-function-never-a-jq-expression/adr.md)
  says. This decision replaces that ADR's predicate signature and nothing
  else in it. `silt__text_is`, `silt__text_is_not` and
  `silt__text_starts_with` take `<answer> <value> <path> <text>`, and they
  are for the verbs without a suffix.
- `silt__any` and `silt__all` gain an `i` or a `k` form when a caller
  needs one. No verb passes both the index and the key.
- `silt__member <answer> <document> <key>` answers the member that a key
  or an index names, given as the `k` form passes it. A callback uses it
  to read the member back without writing a path.
- A callback that fails stops the verb, which returns the callback's
  status.

## Consequences

- A callback that reads only the value takes it as its first argument
  after the answer variable, and a caller reads the suffix to know what
  else arrives.
- A caller that walks a map by key uses the `k` form. It no longer turns
  the map into a list of entries and reads `.key` and `.value` back.
- Every callback and predicate in strata and in the repositories that use
  SILT changes once.
