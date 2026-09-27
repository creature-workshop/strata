// What a JSON value is and holds, as JSON Schema names it, for the schema
// generators.
//
//   jsonType([1])  ->  "array"

// The types JSON Schema names.
export const TYPES = ["null", "boolean", "number", "integer", "string", "object", "array"];

// The type of a value by JSON's name for it.
export function jsonType(value) {
  if (value === null) {
    return "null";
  }
  if (Array.isArray(value)) {
    return "array";
  }
  return typeof value;
}

// Whether a value is a map.
export function isMap(value) {
  return jsonType(value) === "object";
}

// The values a collection holds, none for a scalar.
function membersOf(value) {
  if (jsonType(value) === "array") {
    return value;
  }
  return isMap(value) ? Object.values(value) : [];
}

// A value and every value under it, the value first.
export function valuesUnder(value) {
  return [value, ...membersOf(value).flatMap(valuesUnder)];
}

// Every key of every map under a value, each once, in the order met.
export function keysUnder(value) {
  const keys = valuesUnder(value).filter(isMap).flatMap(Object.keys);
  return [...new Set(keys)];
}

// How many characters a text holds, a character outside the Basic
// Multilingual Plane counted once.
export function chars(text) {
  return [...text].length;
}

// The members of a list with each JSON text once, in the order met.
export function distinct(list) {
  const met = new Set();
  return list.filter((member) => {
    const text = JSON.stringify(member);
    const isNew = !met.has(text);
    met.add(text);
    return isNew;
  });
}
