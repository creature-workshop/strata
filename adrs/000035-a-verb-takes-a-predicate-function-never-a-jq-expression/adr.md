# ADR.35: A verb takes a predicate function, never a jq expression, and SILT provides the common predicates

- Status: proposed
- Date: 2026-11-10
- Implementation: STRATA-249, OPS-1819

## Context

[ADR.34@strata](../000034-the-at-verbs-are-silts-porcelain/adr.md) says
that a verb which takes a jq expression is not part of SILT's porcelain,
and that a caller who needs jq calls jq. shellops is removing jq
altogether, so its callers need another way to say what a jq expression
said.

The largest case is `@filter`. shellops has 45 call sites that pass it a
jq expression. About 38 of them compare the text of one member with one
value, for example `.state == "merged"`, `. != ""` or
`startswith("area/")`. About 7 combine two comparisons with `and` or
`or`, or compute a value before they compare it.

`silt__filter`, `silt__find`, `silt__any` and `silt__all` already take a
predicate function. The verb calls the predicate with the name of the
variable to answer in, the member's key, the member's value and the
caller's extra arguments. The predicate answers `true` or `false` in that
variable.

Two other forms were considered and rejected:

- The comparison as separate arguments, as in
  `@filter open "$issues" .archived eq false`. This covers the simple call
  sites, but every call site it cannot express needs a second form.
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

    silt__filter merged "$reviews" silt__text_is .state merged
    silt__filter named "$names" silt__text_is_not . ''
    silt__filter areas "$labels" silt__text_starts_with . area/

A call site that needs more than one of these can express gets a named
predicate in its own module. That predicate can call the ones SILT
provides.

A caller that computed a value inside a jq expression calls `silt__map`
with a function.

## Consequences

- One predicate works with `silt__filter`, `silt__find`, `silt__any` and
  `silt__all`.
- The predicates compare text. `silt__text_is .archived false` matches the
  bool `false` and the str `"false"`, and a path that holds nothing has the
  empty text, not the text `null`. A caller that must tell these apart
  writes its own predicate with `silt__type` or `silt__has`.
- The porcelain's `@filter` takes the array and then the predicate, so a
  call site in shellops changes only the argument that was a jq expression.
- A new comparison that many callers need is added here as a predicate. It
  is not written again in each consumer.
