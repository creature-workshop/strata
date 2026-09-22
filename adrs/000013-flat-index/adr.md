# ADR.13: The index is flat, one entry per key text wherever the key sits, and an entry may later be scoped under a parent

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/16
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1233
- Implementation: not started

## Context

The index ([ADR.5@opx](../000005-the-header/adr.md)) gives every key a code
and says which types it takes. It does not say whether a key spelled the
same in two places of the tree is one entry or two. A CI job has a `name`,
and so does the runner nested inside it.

One entry per spelling makes `takes` the union of every place, which in an
open store drifts toward a type that describes nothing. One entry per place
lets a closed header type a job's name apart from a runner's, and turns the
index into a description of how keys nest, which
[ADR.8@opx](../000008-strictness-lives-in-the-header/adr.md) leaves to the
interpreter.

## Decision

- An index entry is one per key text. A key gets one code wherever it sits,
  and its `takes` lists every type a node under that key carries anywhere
  in the corpus.
- A code stands for the text and nothing more. A reader maps a code to its
  key and asks no question of place.
- The field name `under` is reserved on an index entry for a later grammar:
  an entry naming a parent key's code there would apply under that parent
  alone, and win over the flat entry. This grammar defines no such field,
  and a writer at this grammar MUST NOT write one.

## Consequences

A search for a key is one code across the whole corpus, and a terse line
under any parent spells it the same way.

What a closed header checks stays what ADR.8 says: the key is known, and the
type is one it takes. A language whose runner's name is typed differently
from its job's names them differently, or waits for `under`.

An omnitype is a property of an open header, which learns every type it
meets, whichever way the index is keyed. Closing the header is the cure.

Adding `under` later is an append to the index entry, so the grammar's
version carries it ([ADR.14@opx](../000014-the-version/adr.md)), and reserving
the name now keeps it from being taken by anything else. It is left for the
first interpreter language that needs it, on purpose.
