# A list's lines with each element's index moved on by SILT_INDEX, its deeper
# lines as they are, the empty list's line dropped: silt__concat past the
# threshold.

# The element's own line with its index moved on.
function shifted(line, __rest) {
  __rest = substr(line, 3)

  return "0." (substr(__rest, 1, index(__rest, ":") - 1) + offset) substr(__rest, index(__rest, ":"))
}

BEGIN {
  offset = ENVIRON["SILT_INDEX"] + 0
}

is_keyless($0) {
  next
}

is_member($0) {
  print shifted($0)
  next
}

{
  print
}
