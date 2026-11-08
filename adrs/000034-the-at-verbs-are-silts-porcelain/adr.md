# ADR.34: The `@` verbs are SILT's porcelain, defined beside the `silt__` verbs, and the names every repository's shell writes

- Status: approved
- Date: 2026-11-08
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/
- Argued from: https://gitlab.creature-workshop.com/ksoft/shellops/-/merge_requests/677
- Implementation: SHOP-71

## Context

SILT's verbs answer in the variable the caller names first and start no
process ([ADR.32@strata](../000032-silt/adr.md)). Every repository's shell
calls them through shellops' `@` verbs, which answer on stdout and cost a
subshell at every call; shellops runs them on SILT behind an adapter of
eighty functions that compute into variables and print at the end.
[ADR.23@global](https://gitlab.creature-workshop.com/ksoft/global-adrs/-/blob/main/adrs/000023-a-verb-writes-the-variable-named-first/adr.md)
makes the result variable the first argument of every data verb. The `@`
names are the vocabulary two years of shell is written in, and SILT is the
engine under it; the adapter between them is the part that is left.

## Decision

- strata defines the `@` verbs beside the `silt__` verbs, under
  `shell/silt`, as SILT's porcelain: the same names shellops' structs
  library gives them, each taking the result variable first and then the
  arguments structs takes today, in the same order.
- A porcelain verb accepts what structs accepts: a path spelled `.a.b`,
  `."a key"` or `a`, a default and several paths for `@get`, and a value
  given as SILT, as SILT on one line or as JSON in any argument, read
  through `silt__read`.
- The porcelain carries only verbs SILT has. A verb that takes a jq
  expression is not one of them; a caller that needs jq calls jq, with
  `silt__to_json` on the way in.
- The porcelain's suite lives here, beside SILT's; a consumer MUST NOT
  define an `@` verb of its own over the same names.

## Consequences

- One library owns the format, the verbs and the names; shellops' structs
  library retires, and the collision between a consumer's `__silt__` names
  and strata's own never arises.
- A consumer that moves to the porcelain changes only the variable in front
  of each call, by the script shellops provides.
- A verb strata does not have is a request to strata, not an adapter in the
  consumer.
