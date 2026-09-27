// The corpus forms of one fuzz case's value, for test/silt-fuzz.sh: the value
// read from <dir>/value.json written as <dir>/value.strh, every line with the
// LID ADR.9 draws for it from a doc-seed, a line-seed and a document number
// the seed picks; as <dir>/value.strt, its keys and types as codes under an
// index the seed shuffles; and that index as <dir>/index.json, a JSON array
// of the keys in code order. Prints the doc-seed, the line-seed and the
// number on one line, for the to_strh call the driver holds to value.strh.
// BigInt keeps every product exact, and nothing here reads SILT, so the two
// spellings are a second opinion on the translators.
//
//   node store.mjs 7 case  ->  1299709 104729 3

import { readFileSync, writeFileSync } from "node:fs";

const DOC_MULTIPLIER = 40692n;
const DOC_MODULUS = 2147483399n;
const LINE_MULTIPLIER = 40014n;
const LINE_MODULUS = 2147483563n;
const CODE_OF = { null: "0", map: "-1", list: "-2", str: "-3", bool: "-4", int: "-5", float: "-6" };

// Lehmer's generator, seeded once, for the seeds and the shuffle.
let state = 1;

function draw() {
  state = (state * 48271) % 2147483647;
  return (state - 1) / 2147483646;
}

// A whole number from 0 up to but not n.
function pick(n) {
  return Math.floor(draw() * n);
}

// base to the power exponent, modulo m.
function powmod(base, exponent, m) {
  let result = 1n;
  let square = base % m;
  let left = exponent;
  while (left > 0n) {
    if (left & 1n) {
      result = (result * square) % m;
    }
    square = (square * square) % m;
    left >>= 1n;
  }
  return result;
}

// A number as eight lowercase hex characters, zeros in front.
function hex8(n) {
  return n.toString(16).padStart(8, "0");
}

// The LID of line i, from 1, of document k under the two seeds.
function lid(docSeed, lineSeed, k, i) {
  const doc = (powmod(DOC_MULTIPLIER, BigInt(k + 1), DOC_MODULUS) * docSeed) % DOC_MODULUS;
  const line = (powmod(LINE_MULTIPLIER, BigInt(i), LINE_MODULUS) * lineSeed) % LINE_MODULUS;
  return hex8(doc) + hex8(line);
}

// A value's natural primitive.
function typeOf(value) {
  if (value === null) return "null";
  if (Array.isArray(value)) return "list";
  if (typeof value === "object") return "map";
  if (typeof value === "string") return "str";
  if (typeof value === "boolean") return "bool";
  return Number.isInteger(value) ? "int" : "float";
}

// A map's keys in canonical order, RFC 8785's: by UTF-16 code unit, which
// is how JavaScript compares strings.
function canonicalKeys(map) {
  return Object.keys(map).sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
}

// A collection's members as [key, value] pairs, a list's keys its indices.
function membersOf(value) {
  if (Array.isArray(value)) return value.map((item, index) => [String(index), item]);
  return canonicalKeys(value).map((key) => [key, value[key]]);
}

// Whether a value is a collection with no member.
function isEmptyCollection(value) {
  return (typeOf(value) === "map" || typeOf(value) === "list") && membersOf(value).length === 0;
}

// A leaf's value text as SILT writes it: a str's JSON literal, a number as
// JSON.stringify spells it, a bool's word.
function leafText(value) {
  return JSON.stringify(value);
}

// The nodes of a value in document order, over an explicit stack: each
// {depth, key, type, value}, the key a JSON literal under a map, an index
// under a list, empty on a keyless line. A root collection with members has
// no node of its own; its members sit at depth 0.
function nodes(root) {
  const out = [];
  if (isEmptyCollection(root) || (typeOf(root) !== "map" && typeOf(root) !== "list")) {
    out.push({ depth: 0, key: "", literal: false, type: typeOf(root), value: root });
    return out;
  }
  const open = membersOf(root).reverse().map(([key, value]) => ({ depth: 0, key, literal: !Array.isArray(root), value }));
  while (open.length > 0) {
    const frame = open.pop();
    const type = typeOf(frame.value);
    out.push({ depth: frame.depth, key: frame.key, literal: frame.literal, type, value: frame.value });
    if (type === "map" || type === "list") {
      const isMap = type === "map";
      for (const [key, value] of membersOf(frame.value).reverse()) {
        open.push({ depth: frame.depth + 1, key, literal: isMap, value });
      }
    }
  }
  return out;
}

// One SILT line for a node.
function siltLine(node) {
  const key = node.literal ? JSON.stringify(node.key) : node.key;
  const leaf = node.type !== "map" && node.type !== "list" && node.type !== "null";
  return `${node.depth}.${key}:${node.type}${leaf ? `=${leafText(node.value)}` : ""}`;
}

// One .strt line for a node: a map's key as @ and its code, a type as its
// code, a bool as 1 or 0.
function terseLine(node, codeOf) {
  const key = node.literal ? `@${codeOf.get(node.key)}` : node.key;
  const type = CODE_OF[node.type];
  if (node.type === "bool") return `${node.depth}.${key}:${type}=${node.value ? 1 : 0}`;
  const leaf = node.type !== "map" && node.type !== "list" && node.type !== "null";
  return `${node.depth}.${key}:${type}${leaf ? `=${leafText(node.value)}` : ""}`;
}

// The distinct map keys of the nodes, in the order first met, then shuffled.
function shuffledKeys(list) {
  const keys = [];
  for (const node of list) {
    if (node.literal && !keys.includes(node.key)) keys.push(node.key);
  }
  for (let i = keys.length - 1; i > 0; i--) {
    const j = pick(i + 1);
    [keys[i], keys[j]] = [keys[j], keys[i]];
  }
  return keys;
}

const seed = Number(process.argv[2]);
const dir = process.argv[3];
if (!Number.isInteger(seed) || !dir) {
  process.stderr.write("usage: node store.mjs <seed> <dir>\n");
  process.exit(2);
}

state = ((seed + 7919) % 2147483646) + 1;
const docSeed = 1n + BigInt(pick(2147483398));
const lineSeed = 1n + BigInt(pick(2147483562));
const number = pick(1000);

const value = JSON.parse(readFileSync(`${dir}/value.json`, "utf8"));
const list = nodes(value);
const keys = shuffledKeys(list);
const codeOf = new Map(keys.map((key, code) => [key, code]));

writeFileSync(`${dir}/value.strh`, list.map((node, at) => `${lid(docSeed, lineSeed, number, at + 1)} ${siltLine(node)}\n`).join(""));
writeFileSync(`${dir}/value.strt`, list.map((node) => `${terseLine(node, codeOf)}\n`).join(""));
writeFileSync(`${dir}/index.json`, `${JSON.stringify(keys)}\n`);
process.stdout.write(`${docSeed} ${lineSeed} ${number}\n`);
