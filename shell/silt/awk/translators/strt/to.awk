# The SILT document on stdin as .strt text: silt__to_strt. A map's key is
# written as @ and its code in the corpus's index, a type as its code, and a
# bool as 1 or 0 (ADR.16@strata); the depth, an index, a keyless line's empty
# key and every other value are as written. The index is read as it is, so a
# key it lacks is refused, naming the line, the way a closed header refuses
# one (ADR.8@strata); appending to an open header is the corpus writer's.
# Refused too: a type no natural primitive names, and an empty document.
# Loaded after lines.awk and index.awk.
#
#   0."ready":bool=true  under the keys "clean" and "ready"  ->  0.@1:-4=1

# A key as .strt writes it: @ and its code for a map's key literal, an index
# or nothing as written. Refuses a key the index lacks.
function coded_key(key) {
  if (!is_name(key)) {
    return key
  }
  if (!(key in CODE_OF)) {
    refuse_line("no code for the key " key " in an index of " KEYS)
  }

  return "@" CODE_OF[key]
}

# A type's code (ADR.3@strata); refuses a type no natural primitive names.
function type_code(name) {
  if (!(name in TYPE_CODE)) {
    refuse_line("no natural primitive is named " name)
  }

  return TYPE_CODE[name]
}

# A leaf's value as .strt writes it: a bool as 1 or 0, any other as written.
function coded_value(type, value) {
  if (type != "bool") {
    return value
  }

  return (value == "true") ? "1" : "0"
}

# One line: the depth as written, the key coded, the type coded, and a
# leaf's value after it.
function main() {
  parse($0)

  if (LEAF) {
    print DEPTH "." coded_key(KEY) ":" type_code(TYPE) "=" coded_value(TYPE, VALUE)
  } else {
    print DEPTH "." coded_key(KEY) ":" type_code(TYPE)
  }
}

BEGIN {
  load_types()
  load_keys()
}

END {
  if (REFUSED) {
    exit 1
  }
  if (NR == 0) {
    refuse("an empty document holds no value")
  }
}

{ main() }
