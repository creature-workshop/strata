# The elements of a list from the index SILT_FROM up to, but not including,
# SILT_TO, numbered from 0: silt__slice past the threshold.
#
#   SILT_FROM=1 SILT_TO=3   0.0:str="a"
#                           0.1:str="b"
#                           0.2:str="c"   ->  0.0:str="b"
#                                             0.1:str="c"

# The element's own line with its index counted from the start of the range.
function renumbered(line, __rest) {
  __rest = substr(line, 3)

  return "0." (substr(__rest, 1, index(__rest, ":") - 1) - from) substr(__rest, index(__rest, ":"))
}

# Whether the element whose own line this is sits within the range.
function within_range(line, __rest, __index) {
  __rest = substr(line, 3)
  __index = substr(__rest, 1, index(__rest, ":") - 1) + 0

  return __index >= from && __index < to
}

# Keeps an element within the range, numbered from 0, with the lines under
# it, and drops every other line.
function main() {
  if (is_keyless($0)) {
    return
  }

  if (is_member($0)) {
    keeping = within_range($0)
    if (keeping) {
      print renumbered($0)
      kept++
    }
    return
  }

  if (keeping) {
    print
  }
}

BEGIN {
  from = ENVIRON["SILT_FROM"] + 0
  to = ENVIRON["SILT_TO"] + 0
  keeping = 0
  kept = 0
}

END {
  if (kept == 0) {
    print "0.:list"
  }
}

{ main() }
