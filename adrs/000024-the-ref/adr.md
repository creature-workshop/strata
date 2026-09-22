# ADR.24: A `ref` names bytes kept outside the document, by their digest

- Status: approved
- Date: 2026-09-22
- Merge request: https://gitlab.creature-workshop.com/ksoft/opx/-/merge_requests/27
- Argued from: https://linear.app/grand-cluster-city/issue/OPS-1247
- Implementation: not started

## Context

[ADR.22@opx](../000022-line-length/adr.md) bounds a line at 16 MiB, and a
value larger than that is not a value but a file beside the corpus. Naming
that file in a `str` promises nothing: no type says the string is a name, no
digest pins the bytes it names, no tool knows to carry the file with the
corpus, and a path breaks the moment the file moves.

Git names a blob by its digest and keeps it in a store addressed the same
way, and OCI does the same for image layers. A digest survives a move, a
copy and a merge, and it is what [ADR.17@opx](../000017-the-digest/adr.md)
already writes.

## Decision

- `ref` is the ninth natural primitive, code -8
  ([ADR.3@opx](../000003-natural-primitives/adr.md)). Its value is a digest
  as ADR.17 writes one, naming a **blob**: bytes kept outside every
  document.

  ```
  2."source":ref=sha256:9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
  ```

- A corpus keeps its blobs in a store addressed by digest. Unpacked, a blob
  is the file `<root>/blobs/<algorithm>/<hex>`.
- A writer that stores bytes as a blob MUST compute the digest from the
  bytes it stored, and MUST NOT write those bytes into a document.
- A reader that verifies MUST refuse a blob whose bytes do not match the
  digest that named it, as it refuses a document.
- A translator to a format without references writes a `ref` as the map
  `{"ref": "<digest>"}`, and one from such a format reads that map back.
- How a pack carries blobs is a later append to
  [ADR.15@opx](../000015-the-pack/adr.md). Until then a pack names the blobs
  its store holds and carries none.

## Consequences

No value is too large for a document. A compiled unit's source, a build
artifact or a dataset's raw dump is a blob, and the line that names it is
under a hundred bytes.

A blob is stored once however many refs name it, in one corpus or across
many, since the name is the content.

A ref survives extraction, joining and merging unchanged, for the same
reason.

A corpus's digest covers its blobs: a blob's digest is in a document, the
document's is in the toc, and the toc is in the header
([ADR.17@opx](../000017-the-digest/adr.md)). A history entry that pins a
corpus pins its blobs too.

The awk fallback reads a ref as text, as it reads a digest, and verifies a
blob with a `sha256sum` beside it.
