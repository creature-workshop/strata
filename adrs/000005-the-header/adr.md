# ADR.5: A corpus shares one header: a fingerprint, and an append-only index that gives every key its code

- Status: approved
- Date: 2026-09-20
- Merge request: https://gitlab.creature-workshop.com/ksoft/strata/-/merge_requests/5
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1179
- Implementation: not started

## Context

A **corpus** is a set of Strata documents kept together. Three things about it
belong to none of its documents. The seeds their LIDs are drawn from cover the
whole corpus. A document that writes a key as a number needs the key's text
kept somewhere. And an interpreter has to know which keys it may meet before
it meets them.

Protobuf and Avro keep names in a schema outside the data and let the data
carry numbers, under one rule: a number, once given, is never given again, so
old data stays readable. This is that rule.

## Decision

- A corpus shares one **header**. It is a document of its own, kept with the
  corpus where the corpus's tool finds it, and no document points at it. It is
  written in the human-readable form, in a file ending `.strh.head`
  ([ADR.6@strata](../000006-three-forms/adr.md)).

  ```
  3c3064613c9a4244 0."fingerprint":map
  540218b978365309 1."seeds":list
  5fd653d71b97e59c 2.0:int=104729
  4e8b6ad50c9e74d4 2.1:int=1299709
  63b4314353316f63 1."rng":str="ecuyer1988-state"
  2f14432a4e41c033 1."closed":bool=false
  312d254d2ba9305a 0."index":list
  7e903972094e5e40 1.0:map
  732649383ce8921e 2."key":str="duration"
  6a771edc18235a23 2."takes":list
  0744a1b25370aa8d 3.0:str="float"
  0974ae9c110a5d12 3.1:str="null"
  ```

- Every header extends the **default header**, which the language defines and
  every implementation carries: the grammar's version and the natural
  primitives ([ADR.3@strata](../000003-natural-primitives/adr.md)). A corpus's
  header never restates it.
- The **fingerprint** is what makes the corpus this one and no other. `seeds`
  and `rng` are what its LIDs are drawn from
  ([ADR.7@strata](../000007-ids-are-generator-state/adr.md)), and `closed` is
  [ADR.8@strata](../000008-strictness-lives-in-the-header/adr.md)'s.
- The **index** is the list of the corpus's keys, and a key's place in it is
  its **code**. An element holds the `key` and what it `takes`: the names of
  the types a node under that key may carry.
- The index is append-only. An element MUST NOT be removed or moved, and its
  key MUST NOT change. A later header therefore reads every document an
  earlier one wrote.
- A header MUST NOT say whether a key is required, give a default, or bound a
  value. Checking a document's content belongs to whatever consumes it.

## Consequences

The seeds are the corpus's identity: every LID in it comes from them, and the
header needs no second name. They stay with the corpus for that reason. Under
seeds everyone shared, two corpora with a unit of the same name would draw
the same LIDs.

A seed can be lost and a document still reads. Without its header a terse
document is numbers.

The LIDs above are the header's own, so its seeds are minted first.

Two writers that meet a new key at once must not give it two codes. A corpus
has one writer, or its writers take a lock; the tool decides which.

How a key is renamed, retired or allowed a new type waits on a comparison of
how Protobuf, Avro and Cap'n Proto answer it. How a header defines a derived
primitive waits for the first translator that needs one.
