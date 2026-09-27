# How many members a map or a list holds: silt__len past the threshold.

is_member($0) {
  count++
}

END {
  print count + 0
}
