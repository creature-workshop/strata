// A schema derived from a value, for test/fuzz/schema.mjs: it says what
// the value is, place by place, in the keywords silt__validate reads, so
// the value meets it nearly always and test/fuzz/alterations.mjs has
// something to loosen or break. Which keywords say it is drawn. The
// context holds whether the value's text is plain, so a pattern may be
// drawn.
//
//   derive(g, {"n":3}, context)
//     ->  {"type":"object","properties":{"n":{"type":"integer","minimum":1}},"required":["n"]}

import { among, chance, several, whole } from "./draws.mjs";
import { chars, distinct, jsonType } from "./json.mjs";
import { pattern, patternOf } from "./pattern.mjs";

const DIVISORS = [1, 2, 3, 5];
const FRACTIONS = [0.5, 0.25, 0.1];

const DERIVED_BY_TYPE = {
  null: ofNull,
  boolean: ofBool,
  number: ofNumber,
  string: ofText,
  object: ofMap,
  array: ofList,
};

// The schema derived from a value.
export function derive(g, value, context) {
  return DERIVED_BY_TYPE[jsonType(value)](g, value, context);
}

function ofNull() {
  return { type: "null" };
}

function ofBool(g, value) {
  return chance(g, 50) ? { type: "boolean", const: value } : { type: "boolean" };
}

// The bounds a number sits within, either bound kept as drawn, and whole
// numbers both, so each is spelled as it was drawn.
function boundsOf(g, value) {
  const bounds = {};
  if (chance(g, 50)) {
    bounds[chance(g, 70) ? "minimum" : "exclusiveMinimum"] = Math.floor(value) - whole(g, 1, 3);
  }
  if (chance(g, 50)) {
    bounds[chance(g, 70) ? "maximum" : "exclusiveMaximum"] = Math.ceil(value) + whole(g, 1, 3);
  }
  return bounds;
}

function ofNumber(g, value) {
  const isWhole = Number.isInteger(value);
  const schema = { type: isWhole && chance(g, 70) ? "integer" : "number", ...boundsOf(g, value) };
  if (chance(g, 30)) {
    schema.multipleOf = among(g, isWhole ? DIVISORS : FRACTIONS);
  }
  return schema;
}

// The lengths a text sits within, either kept as drawn.
function lengthsOf(g, text) {
  const lengths = {};
  if (chance(g, 40)) {
    lengths.minLength = Math.max(0, chars(text) - whole(g, 0, 2));
  }
  if (chance(g, 40)) {
    lengths.maxLength = chars(text) + whole(g, 0, 2);
  }
  return lengths;
}

function ofText(g, text, context) {
  const schema = { type: "string", ...lengthsOf(g, text) };
  if (chance(g, 20)) {
    schema.enum = distinct([text, among(g, context.scalars)]);
  }
  if (context.plain && chance(g, 50)) {
    schema.pattern = patternOf(g, text);
  }
  return schema;
}

// What a map's schema says of the keys it names none of: nothing, that
// there are none, or a pattern's schema where a pattern may be drawn.
function restOf(g, context) {
  if (context.plain && chance(g, 20)) {
    return { patternProperties: { [pattern(g)]: chance(g, 50) ? {} : { type: "string" } } };
  }
  return chance(g, 40) ? { additionalProperties: false } : {};
}

function ofMap(g, map, context) {
  const entries = Object.entries(map).map(([key, member]) => [key, derive(g, member, context)]);
  return {
    type: "object",
    properties: Object.fromEntries(entries),
    required: several(g, Object.keys(map), 3),
    ...restOf(g, context),
  };
}

// The schema every member of a list meets: any schema at all for a list
// holding none, and one of the members' own otherwise.
function itemsOf(g, list, context) {
  const schemas = distinct(list.map((member) => derive(g, member, context)));
  if (schemas.length === 0) {
    return {};
  }
  return schemas.length === 1 ? schemas[0] : { anyOf: schemas };
}

function ofList(g, list, context) {
  const schema = { type: "array", items: itemsOf(g, list, context) };
  if (chance(g, 40)) {
    schema.minItems = Math.max(0, list.length - whole(g, 0, 1));
  }
  if (chance(g, 40)) {
    schema.maxItems = list.length + whole(g, 0, 1);
  }
  if (chance(g, 30)) {
    schema.uniqueItems = chance(g, 70);
  }
  return schema;
}
