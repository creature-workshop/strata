# Prints the keys of the other documents that the schema on stdin refers
# to, as a list of strings in sorted order, each key once. Prints an empty
# list if the schema refers to no other document. This is the awk program
# behind silt__references. SILT_BASE is the key of the schema itself, which
# its references are relative to. Load after lines.awk, order.awk and
# schema/keys.awk.
#
#   0."$ref":str="types.json#/$defs/name"   ->  0.0:str="types.json"

# Records the key of the document that a "$ref" line refers to, if that is
# another document.
function record_reference(line, __uri) {
  parse(line)
  if (KEY != "\"$ref\"" || TYPE != "str") {
    return
  }

  __uri = document_part(unwrap(VALUE))
  if (__uri != "") {
    REFERENCED[joined_key(ENVIRON["SILT_BASE"], __uri)] = 1
  }
}

# Prints the recorded keys as a list of strings, in sorted order.
function print_references(__key, __count, __i) {
  LINES = 0
  for (__key in REFERENCED) {
    take("0." wrap(__key) ":null")
  }
  sort_lines()

  __count = 0
  for (__i = 1; __i <= LINES; __i++) {
    parse(LINE[ORDER[__i]])
    print "0." __count ":str=" KEY
    __count++
  }

  if (__count == 0) {
    print "0.:list"
  }
}

# Reads one line of the schema.
function main() {
  record_reference($0)
}

BEGIN {
  order_begin()
}

END {
  if (REFUSED) {
    exit 1
  }

  print_references()
}

{ main() }
