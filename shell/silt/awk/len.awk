# How many members a map or a list holds: silt__len past the threshold.

# Counts a member's own line.
function main() {
  if (is_member($0)) {
    count++
  }
}

BEGIN {
  count = 0
}

END {
  print count
}

{ main() }
