// A random JSON value drawn from a seed, for test/silt-fuzz.sh. fast-check
// draws the value. This module says what a value may contain, writes it as
// JSON, and gives it to a caller as a value that keeps the order of its
// keys.
//
// A map's keys are in the order they were drawn, not in sorted order, so
// the fuzz checks that SILT keeps the order a document was written in.
//
// The value only contains what jq and yq write in the same way: whole
// numbers within 2^53, decimals with a digit after the point, no exponent,
// no -0, keys inside the Basic Multilingual Plane, and no character that jq
// escapes and JSON.stringify does not.
//
//   render(drawTree(7))  ->  {"k.d":null,"a":[1,"x y"]}

import fc from "fast-check";
import { KEYS, PIECES } from "./vocabulary.mjs";

// Text with the characters taken out that jq escapes and JSON.stringify
// leaves raw, or that no line can carry: NUL, DEL and the C1 controls. It
// also takes out U+FFFE and U+FFFF, which yq does not read.
function withoutUnsafe(text) {
  return text.replace(/[\u0000\u007f-\u009f\ufffe\uffff]/g, "");
}

const pieces = fc.array(fc.constantFrom(...PIECES), { minLength: 1, maxLength: 3 }).map((parts) => parts.join(" "));
const text = fc.oneof(
  { weight: 3, arbitrary: pieces },
  { weight: 1, arbitrary: fc.string({ maxLength: 12 }) },
  { weight: 1, arbitrary: fc.unicodeString({ maxLength: 6 }).map(withoutUnsafe) },
);

const key = fc.oneof(
  { weight: 3, arbitrary: fc.constantFrom(...KEYS) },
  { weight: 1, arbitrary: fc.string({ maxLength: 8 }) },
  { weight: 1, arbitrary: fc.unicodeString({ maxLength: 4 }).map(withoutUnsafe) },
);

const integer = fc.oneof(
  { weight: 19, arbitrary: fc.integer({ min: -1000000, max: 1000000 }) },
  { weight: 1, arbitrary: fc.constantFrom(9007199254740991, -9007199254740991) },
);

// A decimal with one to three digits after the point, the last not zero, so
// JSON.stringify and jq print it as it was drawn.
const decimal = fc.tuple(fc.integer({ min: -9999, max: 9999 }), fc.integer({ min: 1, max: 999 }))
  .map(([whole, fraction]) => Number(`${whole}.${String(fraction).replace(/0+$/, "") || "1"}`));

const scalar = fc.oneof(
  { weight: 1, arbitrary: fc.constant(null) },
  { weight: 1, arbitrary: fc.boolean() },
  { weight: 3, arbitrary: integer },
  { weight: 1, arbitrary: decimal },
  { weight: 4, arbitrary: text },
);

// A map's entries with each key once, in the order they were drawn. A key
// drawn twice keeps its first value.
function distinct(entries) {
  const kept = new Map();
  for (const [name, value] of entries) {
    if (!kept.has(name)) {
      kept.set(name, value);
    }
  }
  return [...kept.entries()];
}

const { value } = fc.letrec((tie) => ({
  value: fc.oneof(
    { maxDepth: 4, depthSize: "small" },
    { weight: 6, arbitrary: scalar },
    { weight: 2, arbitrary: tie("map") },
    { weight: 2, arbitrary: tie("list") },
  ),
  map: fc.array(fc.tuple(key, tie("value")), { maxLength: 4 }).map((entries) => ({ kind: "map", entries: distinct(entries) })),
  list: fc.array(tie("value"), { maxLength: 4 }).map((items) => ({ kind: "list", items })),
}));

const root = fc.oneof(
  { weight: 65, arbitrary: fc.array(fc.tuple(key, value), { maxLength: 5 }).map((entries) => ({ kind: "map", entries: distinct(entries) })) },
  { weight: 25, arbitrary: fc.array(value, { maxLength: 5 }).map((items) => ({ kind: "list", items })) },
  { weight: 10, arbitrary: scalar },
);

// Whether a drawn node is a map or a list rather than a scalar.
function isCollection(node) {
  return node !== null && typeof node === "object";
}

// The members of a collection, as one array either way.
function membersOf(node) {
  return node.kind === "map" ? node.entries : node.items;
}

// The JSON text of a value, written over an explicit stack of the
// collections open: a scalar as JSON.stringify spells it, a map's keys as
// drawn, in the order they were drawn.
export function render(top) {
  let out = "";
  const open = [];
  const start = (node) => {
    if (isCollection(node)) {
      out += node.kind === "map" ? "{" : "[";
      open.push({ node, at: 0 });
    } else {
      out += JSON.stringify(node);
    }
  };

  start(top);
  while (open.length > 0) {
    const frame = open[open.length - 1];
    const members = membersOf(frame.node);
    if (frame.at === members.length) {
      out += frame.node.kind === "map" ? "}" : "]";
      open.pop();
      continue;
    }
    if (frame.at > 0) {
      out += ",";
    }
    const member = members[frame.at];
    frame.at += 1;
    if (frame.node.kind === "map") {
      out += `${JSON.stringify(member[0])}:`;
      start(member[1]);
    } else {
      start(member);
    }
  }
  return out;
}

// The tree drawn from a seed. A map is {kind: "map", entries}, a list is
// {kind: "list", items}, and a scalar is the value itself.
export function drawTree(seed) {
  const [drawn] = fc.sample(root, { seed, numRuns: 1 });
  return drawn;
}

// A drawn tree as a value that keeps the order of every map's keys: a map
// is a Map and a list is an Array. A plain object would move a key that
// looks like a whole number, such as "10", in front of the other keys.
export function toOrderedValue(node) {
  if (!isCollection(node)) {
    return node;
  }
  if (node.kind === "list") {
    return node.items.map(toOrderedValue);
  }
  return new Map(node.entries.map(([name, member]) => [name, toOrderedValue(member)]));
}
