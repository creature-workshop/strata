# A list's scalars joined by SILT_SEPARATOR into one text: silt__join past
# the threshold. A member that is a collection is refused, as the shell
# refuses it.

# Adds one member's text to the answer, after the separator unless it is the
# first.
function add_member(line) {
  parse(line)

  if (!LEAF && TYPE != "null") {
    refuse("join of a list holding a collection")
  }

  if (first) {
    out = scalar_text(line)
    first = 0
  } else {
    out = out separator scalar_text(line)
  }
}

# Adds a member's text to the answer.
function main() {
  if (is_member($0)) {
    add_member($0)
  }
}

BEGIN {
  separator = ENVIRON["SILT_SEPARATOR"]
  first = 1
  out = ""
}

END {
  if (!first) {
    printf "%s\n", out
  }
}

{ main() }
