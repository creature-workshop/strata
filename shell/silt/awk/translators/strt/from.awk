# The .strt document on stdin as SILT: silt__from_strt. A key written as @
# and a code becomes the key literal with that code in the corpus's index, a
# type written as a code becomes its name, and a bool's 1 or 0 becomes true
# or false (ADR.16@strata); the depth, an index, a keyless line's empty key
# and every other value are as written. Refused, naming the line: a code the
# index lacks, a type code no natural primitive has, a key or a type not
# written as a code, a bool spelled otherwise, an index that is not a list
# of str, and an empty document. Loaded after lines.awk and index.awk.
#
#   0.@1:-4=1  under the keys "clean" and "ready"  ->  0."ready":bool=true

# The key a .strt line's key stands for: the literal under a code, or an
# index or nothing as written. Refuses a key that is none of the three.
function spelled_key(key) {
  if (key ~ /^@/) {
    return key_of_code(substr(key, 2))
  }
  if (key == "" || key ~ /^[0-9]+$/) {
    return key
  }

  refuse_line("a .strt line writes a key as a code")
}

# The key literal under a code, refused when the code is not a number or the
# index lacks it.
function key_of_code(code) {
  if (code !~ /^[0-9]+$/) {
    refuse_line("a .strt line writes a key as @ and a code")
  }
  if (code + 0 >= KEYS) {
    refuse_line("no key has the code " code " in an index of " KEYS)
  }

  return KEY_OF[code + 0]
}

# The natural primitive a type code names (ADR.3@strata); refuses any other.
function type_name(code) {
  if (!(code in NAME_OF)) {
    refuse_line("no natural primitive has the type code " code)
  }

  return NAME_OF[code]
}

# The word a .strt bool's digit stands for; refuses any other spelling.
function bool_word(digit) {
  if (digit == "1") {
    return "true"
  }
  if (digit == "0") {
    return "false"
  }

  refuse_line("a .strt line writes a bool as 1 or 0")
}

# A leaf's type name and value, a bool's digit as its word.
function spelled_leaf(node, __type, __value) {
  __type = type_name(substr(node, 1, index(node, "=") - 1))
  __value = substr(node, index(node, "=") + 1)
  if (__type == "bool") {
    __value = bool_word(__value)
  }

  return __type "=" __value
}

# One line: the depth as written, the key spelled out, the type named and a
# leaf's value after it.
function main(__rest, __key, __node) {
  if ($0 !~ /^[0-9]+\.[^:]*:/) {
    refuse_line("not a .strt line")
  }

  __rest = substr($0, index($0, ".") + 1)
  __key = spelled_key(substr(__rest, 1, index(__rest, ":") - 1))
  __node = substr(__rest, index(__rest, ":") + 1)

  if (index(__node, "=") > 0) {
    print substr($0, 1, index($0, ".")) __key ":" spelled_leaf(__node)
  } else {
    print substr($0, 1, index($0, ".")) __key ":" type_name(__node)
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
