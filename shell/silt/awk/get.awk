# The value at the path in SILT_SEGMENTS, as a document of its own: silt__get
# past the threshold. Nothing is printed for a path no member holds.
BEGIN { load_segments(); want = 0; at_segment = 1; found = 0; placeholder = "" }

found {
  parse($0)
  if (DEPTH <= at) { exit }
  placeholder = ""
  print redepth($0, -at - 1)
  next
}

{
  parse($0)
  if (DEPTH < want) { exit }
  if (DEPTH != want || KEY != SEGMENT[at_segment]) { next }
  if (at_segment == SEGMENTS) {
    found = 1
    at = DEPTH
    if (LEAF) { placeholder = "0.:" TYPE "=" VALUE } else { placeholder = "0.:" TYPE }
    next
  }
  at_segment++
  want++
}

END { if (placeholder != "") { print placeholder } }
