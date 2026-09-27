# The .strh document on stdin as SILT: silt__from_strh. Each line loses its
# LID, sixteen lowercase hex characters, and the space after it, and nothing
# else changes (ADR.32@strata). Refused, naming the line: one that does not
# open with a LID and a space, and an empty document. Loaded after lines.awk.
#
#   67e924b179c7e1f3 0."runner":str="bats"   ->  0."runner":str="bats"

# Whether the text is a LID: sixteen characters, each a lowercase hex digit.
function is_lid(text) {
  return length(text) == 16 && text ~ /^[0-9a-f]+$/
}

# One line: its LID and the space checked, the rest written.
function main() {
  if (!is_lid(substr($0, 1, 16)) || substr($0, 17, 1) != " ") {
    refuse("line " NR ": a .strh line opens with a LID and a space: " $0)
  }

  print substr($0, 18)
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
