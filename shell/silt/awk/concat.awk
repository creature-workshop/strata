# A list's lines with each element's index moved on by SILT_INDEX, its
# deeper lines as they are, the empty list's line dropped: silt__concat past
# the threshold.
BEGIN { offset = ENVIRON["SILT_INDEX"] + 0 }
substr($0, 1, 3) == "0.:" { next }
substr($0, 1, 2) == "0." {
  rest = substr($0, 3)
  print "0." (substr(rest, 1, index(rest, ":") - 1) + offset) substr(rest, index(rest, ":"))
  next
}
{ print }
