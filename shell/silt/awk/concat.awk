# A list's lines with each element's index moved on by SILT_INDEX, its deeper
# lines as they are, the empty list's line dropped: silt__concat past the
# threshold.

# The element's own line with its index moved on.
function shifted(line, __rest) {
  __rest = substr(line, 3)

  return "0." (substr(__rest, 1, index(__rest, ":") - 1) + offset) substr(__rest, index(__rest, ":"))
}

# Drops the empty list's line, moves an element's index on, and keeps a
# deeper line as it is.
function main() {
  if (is_keyless($0)) {
    return
  }

  if (is_member($0)) {
    print shifted($0)
    return
  }

  print
}

BEGIN {
  offset = ENVIRON["SILT_INDEX"] + 0
}

{ main() }
