// A random JSON value from a seed, for test/silt-fuzz.sh: one compact line
// with every map's keys in canonical order, so reading it into SILT and
// writing it back must give the same bytes. fast-check draws the value; this
// file only says what a value may hold and prints it. It keeps to what jq
// and yq spell the same way: ints within 2^53, decimals with a digit after
// the point, no exponent, no -0, keys inside the Basic Multilingual Plane,
// and no character jq escapes and JSON.stringify does not, so the awkward
// cases live in the strings and the keys.
//
//   node value.mjs 7  ->  {"a":[1,"x y"],"k.d":null}

import fc from "fast-check";
import { KEYS, PIECES } from "./vocabulary.mjs";

// Text with the characters taken out that jq escapes and JSON.stringify
// leaves raw, or that no line can carry: NUL, DEL and the C1 controls.
function withoutUnsafe(text) {
  return text.replace(/[\u0000\u007f-\u009f]/g, "");
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

// A map's entries with each key once, in canonical order: JavaScript
// compares strings by UTF-16 code unit, which is RFC 8785's order.
function canonical(entries) {
  const held = new Map();
  for (const [name, value] of entries) {
    if (!held.has(name)) {
      held.set(name, value);
    }
  }
  return [...held.entries()].sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
}

const { value } = fc.letrec((tie) => ({
  value: fc.oneof(
    { maxDepth: 4, depthSize: "small" },
    { weight: 6, arbitrary: scalar },
    { weight: 2, arbitrary: tie("map") },
    { weight: 2, arbitrary: tie("list") },
  ),
  map: fc.array(fc.tuple(key, tie("value")), { maxLength: 4 }).map((entries) => ({ kind: "map", entries: canonical(entries) })),
  list: fc.array(tie("value"), { maxLength: 4 }).map((items) => ({ kind: "list", items })),
}));

const root = fc.oneof(
  { weight: 65, arbitrary: fc.array(fc.tuple(key, value), { maxLength: 5 }).map((entries) => ({ kind: "map", entries: canonical(entries) })) },
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
// drawn, in canonical order.
function render(top) {
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

const seed = Number(process.argv[2]);
if (!Number.isInteger(seed)) {
  process.stderr.write("usage: node value.mjs <seed>\n");
  process.exit(2);
}

const [drawn] = fc.sample(root, { seed, numRuns: 1 });
process.stdout.write(`${render(drawn)}\n`);
