// The alterations of a schema, for test/fuzz/schema.mjs: a table of rules,
// each of which loosens or breaks the schema at one place the seed picks,
// so a value that met the schema it was derived from meets the altered one
// or fails it, and both answers come up. Every rule leaves a schema a
// validator accepts: what it changes is what the schema asks of the value,
// never the kind of operand a keyword takes. A rule answers whether the
// place held what it alters.
//
//   altered(g, {"type":"integer","minimum":1}, context)
//     ->  {"type":"integer","minimum":9}

import { among, chance, whole } from "./draws.mjs";
import { TYPES, isMap } from "./json.mjs";
import { pattern } from "./pattern.mjs";
import { REF_NAMES, refTo } from "./refs.mjs";

// The keywords whose operand is a schema, a list of schemas, or a map of
// schemas by name.
const SCHEMA_UNDER = ["additionalProperties", "items", "not"];
const SCHEMAS_UNDER = ["allOf", "anyOf", "oneOf"];
const SCHEMAS_BY_NAME_UNDER = ["properties", "patternProperties", "$defs"];

const RULES = [
  dropKeyword, allowAnotherType, acceptAnything,
  swapType, raiseMinimum, lowerMaximum, raiseMinLength, lowerMaxLength,
  changeConst, requireAnother, forbidAProperty, raiseMinItems, lowerMaxItems,
  demandUniqueItems, refuseItems, negate, matchTwice, swapPattern, moveToDefs,
];

// A copy of the schema altered at one place or two, by a rule drawn for
// each. A rule the place holds nothing for gives way to negate, which any
// place takes.
export function altered(g, schema, context) {
  const root = structuredClone(schema);
  const times = whole(g, 1, 2);

  for (let time = 0; time < times; time++) {
    const place = among(g, placesOf(root));
    if (!among(g, RULES)(g, place, { ...context, root })) {
      negate(g, place);
    }
  }
  return root;
}

// The schemas a schema holds under its keywords, itself left out.
function heldBy(schema) {
  return [
    ...SCHEMA_UNDER.map((keyword) => schema[keyword]),
    ...SCHEMAS_UNDER.flatMap((keyword) => schema[keyword] ?? []),
    ...SCHEMAS_BY_NAME_UNDER.flatMap((keyword) => Object.values(schema[keyword] ?? {})),
  ];
}

// Every place of a schema a rule can alter: the schema and each schema
// under it that is a map, a bool left as it is.
function placesOf(schema) {
  return [schema, ...heldBy(schema).filter(isMap).flatMap(placesOf)];
}

// Empties a place and writes another schema's keywords into it, so
// whatever holds the place holds the other schema.
function rewrite(place, schema) {
  for (const keyword of Object.keys(place)) {
    delete place[keyword];
  }
  Object.assign(place, schema);
}

// Adds a drawn amount to the number under a keyword, where the place holds
// the keyword.
function shift(g, place, keyword, direction) {
  if (!(keyword in place)) {
    return false;
  }
  place[keyword] = Math.max(keyword.endsWith("imum") ? -Infinity : 0, place[keyword] + direction * whole(g, 1, 8));
  return true;
}

function dropKeyword(g, place) {
  const keywords = Object.keys(place);
  if (keywords.length === 0) {
    return false;
  }
  delete place[among(g, keywords)];
  return true;
}

function allowAnotherType(g, place) {
  if (typeof place.type !== "string") {
    return false;
  }
  place.type = [place.type, among(g, TYPES)];
  return true;
}

function acceptAnything(g, place) {
  rewrite(place, {});
  return true;
}

function swapType(g, place) {
  if (!("type" in place)) {
    return false;
  }
  place.type = among(g, TYPES);
  return true;
}

function raiseMinimum(g, place) {
  return shift(g, place, "minimum", 1) || shift(g, place, "exclusiveMinimum", 1);
}

function lowerMaximum(g, place) {
  return shift(g, place, "maximum", -1) || shift(g, place, "exclusiveMaximum", -1);
}

function raiseMinLength(g, place) {
  return shift(g, place, "minLength", 1);
}

function lowerMaxLength(g, place) {
  return shift(g, place, "maxLength", -1);
}

function changeConst(g, place, context) {
  place.const = among(g, context.scalars);
  return true;
}

function requireAnother(g, place, context) {
  if (!("properties" in place)) {
    return false;
  }
  place.required = [...(place.required ?? []), among(g, context.keys)];
  return true;
}

function forbidAProperty(g, place) {
  const names = Object.keys(place.properties ?? {});
  if (names.length === 0) {
    return false;
  }
  delete place.properties[among(g, names)];
  place.additionalProperties = false;
  return true;
}

function raiseMinItems(g, place) {
  return shift(g, place, "minItems", 1);
}

function lowerMaxItems(g, place) {
  return shift(g, place, "maxItems", -1);
}

function demandUniqueItems(g, place) {
  if (place.type !== "array") {
    return false;
  }
  place.uniqueItems = true;
  return true;
}

function refuseItems(g, place) {
  if (!("items" in place)) {
    return false;
  }
  place.items = false;
  return true;
}

function negate(g, place) {
  rewrite(place, { not: { ...place } });
  return true;
}

function matchTwice(g, place) {
  rewrite(place, { oneOf: [{ ...place }, chance(g, 50) ? { ...place } : {}] });
  return true;
}

function swapPattern(g, place, context) {
  if (!context.plain || !("pattern" in place)) {
    return false;
  }
  place.pattern = pattern(g);
  return true;
}

// Moves the place's schema under the root's $defs and leaves a reference
// to it, which asks of the value what the place did. The root keeps its
// place, since it is what holds the $defs.
function moveToDefs(g, place, context) {
  const name = among(g, REF_NAMES);
  if (place === context.root || name in (context.root.$defs ?? {})) {
    return false;
  }
  context.root.$defs = { ...context.root.$defs, [name]: { ...place } };
  rewrite(place, { $ref: refTo(name) });
  return true;
}
