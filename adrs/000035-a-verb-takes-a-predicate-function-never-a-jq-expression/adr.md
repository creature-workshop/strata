# ADR.35: A verb takes a predicate function, never a jq expression, and SILT provides the common predicates

- Status: approved
- Date: 2026-11-10
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/104
- Implementation: STRATA-249, OPS-1819

## Context

[ADR.34@strata](../000034-the-at-verbs-are-silts-porcelain/adr.md) says
that a verb which takes a jq expression is not part of SILT's porcelain.
shellops is removing jq altogether, so its callers need another way to say
what a jq expression said.

The largest case is `@filter`: 45 call sites in shellops pass it a jq
expression. About 38 compare the text of one member with one value. About
7 combine two comparisons, or compute a value first.

`silt__filter`, `silt__find`, `silt__any` and `silt__all` already take a
predicate function.

Two other forms were considered and rejected:

- The comparison as separate arguments, as in `.archived eq false`. This
  covers the simple call sites, but every call site it cannot express
  needs a second form.
- A small expression language that SILT parses. This would be a second jq
  to maintain.

## Decision

No verb accepts a jq expression. A caller that selects members passes a
predicate function.

SILT provides the common predicates. Each one compares the text that
`silt__string` answers for a path of the member. The path `.` is the
member itself.

| Predicate | Answers true when |
|---|---|
| `silt__text_is <path> <text>` | the text at the path is the text given |
| `silt__text_is_not <path> <text>` | the text at the path differs from the text given |
| `silt__text_starts_with <path> <prefix>` | the text at the path starts with the prefix |

```sh
silt__filter merged "$reviews" silt__text_is .state merged
silt__filter named "$names" silt__text_is_not . ''
silt__filter areas "$labels" silt__text_starts_with . area/
```

A predicate answers the way a verb does. Its first argument is the name of
the variable to answer in, and it assigns `true` or `false` to that
variable. It prints nothing and starts no process. A predicate a caller
writes MUST answer the same way.

A verb that takes a predicate starts no process for a document under the
threshold. Past the threshold it starts one awk for its walk, however many
members the document has.

A call site that one of these predicates cannot express gets a named
predicate in its own module.

## Consequences

- One predicate works with `silt__filter`, `silt__find`, `silt__any` and
  `silt__all`.
- The predicates compare text. `silt__text_is .archived false` matches the
  bool `false` and the str `"false"`. A path that holds nothing has the
  empty text, not the text `null`. A caller that must tell these apart
  writes its own predicate with `silt__type` or `silt__has`.
- The porcelain's `@filter` takes the array and then the predicate, so a
  call site in shellops changes only the argument that was a jq expression.
