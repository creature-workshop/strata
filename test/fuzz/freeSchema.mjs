// A schema drawn free of the value, for test/fuzz/schema.mjs: any of the
// keywords silt__validate reads, each held on a draw of its own, with the
// operand its keyword takes, to three schemas deep. The context holds
// the keys and the scalars the value is likely to hold, so the schema
// meets the value often enough to say something of it, and whether the
// value's text is plain, so a pattern may be drawn.
//
//   free(g, context)  ->  {"type":["string","null"],"maxLength":3,"not":{"const":"yes"}}

import { among, chance, several, whole } from "./draws.mjs";
import { TYPES } from "./json.mjs";
import { pattern } from "./pattern.mjs";
import { REF_NAMES, refTo } from "./refs.mjs";

const DEEPEST = 3;
const BOUNDS = [-1000000, -10, -1, 0, 1, 2, 3, 10, 1000000, 0.5, 1.5, -2.25];
const DIVISORS = [1, 2, 3, 5, 10, 0.5, 0.25, 0.1];

// References that name no schema of the document, each an error against
// the value for both validators.
const STRAY_REFS = ["#/$defs/missing", "other.schema.json#/$defs/n", "#/type", "#"];

// Each keyword with the share of schemas that hold it and the operand
// drawn for it. The keywords that take a pattern are held only where one
// may be drawn.
const KEYWORDS = [
  ["type", 20, type],
  ["enum", 5, (g, context) => Array.from({ length: whole(g, 1, 3) }, () => among(g, context.scalars))],
  ["const", 4, (g, context) => among(g, context.scalars)],
  ["minLength", 6, (g) => whole(g, 0, 12)],
  ["maxLength", 6, (g) => whole(g, 0, 12)],
  ["pattern", 7, (g) => pattern(g), "pattern"],
  ["minimum", 5, (g) => among(g, BOUNDS)],
  ["maximum", 5, (g) => among(g, BOUNDS)],
  ["exclusiveMinimum", 3, (g) => among(g, BOUNDS)],
  ["exclusiveMaximum", 3, (g) => among(g, BOUNDS)],
  ["multipleOf", 4, (g) => among(g, DIVISORS)],
  ["required", 7, (g, context) => several(g, context.keys, 3)],
  ["properties", 15, properties],
  ["patternProperties", 5, patternProperties, "pattern"],
  ["additionalProperties", 7, schemaOrBool],
  ["minItems", 5, (g) => whole(g, 0, 4)],
  ["maxItems", 5, (g) => whole(g, 0, 4)],
  ["uniqueItems", 5, (g) => chance(g, 70)],
  ["items", 12, schemaOrBool],
  ["allOf", 4, schemas],
  ["anyOf", 5, schemas],
  ["oneOf", 5, schemas],
  ["not", 4, (g, context, depth) => schemaAt(g, context, depth + 1)],
  ["$ref", 4, ref],
];

// The schema drawn, its $defs holding a schema for each name a reference
// may take.
export function free(g, context) {
  const schema = schemaAt(g, context, 0);
  if (schema === true || schema === false) {
    return schema;
  }

  const defs = REF_NAMES.map((name) => [name, schemaAt(g, context, 1)]);
  return { ...schema, $defs: Object.fromEntries(several(g, defs, 3)) };
}

// A schema at a depth: a bool or the empty schema at the deepest and now
// and then above it, and a map of keywords otherwise.
function schemaAt(g, context, depth) {
  if (depth >= DEEPEST || chance(g, 10)) {
    return among(g, [true, false, {}]);
  }

  const held = KEYWORDS.filter(([, share, , needs]) => (needs !== "pattern" || context.plain) && chance(g, share));
  return Object.fromEntries(held.map(([keyword, , operand]) => [keyword, operand(g, context, depth)]));
}

function type(g) {
  return chance(g, 75) ? among(g, TYPES) : several(g, TYPES, 3);
}

function schemaOrBool(g, context, depth) {
  return schemaAt(g, context, depth + 1);
}

function schemas(g, context, depth) {
  return Array.from({ length: whole(g, 1, 3) }, () => schemaAt(g, context, depth + 1));
}

function properties(g, context, depth) {
  const names = several(g, context.keys, 4);
  return Object.fromEntries(names.map((name) => [name, schemaAt(g, context, depth + 1)]));
}

function patternProperties(g, context, depth) {
  return { [pattern(g)]: schemaAt(g, context, depth + 1) };
}

// A reference to a name the $defs may hold, or now and then to no schema.
function ref(g) {
  return chance(g, 80) ? refTo(among(g, REF_NAMES)) : among(g, STRAY_REFS);
}
