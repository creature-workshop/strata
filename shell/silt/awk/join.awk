# A list's scalars joined by SILT_SEPARATOR into one text: silt__join past
# the threshold. A member that is a collection ends the run with status 1
# and a message, as the shell does.
BEGIN { separator = ENVIRON["SILT_SEPARATOR"]; first = 1 }

is_member($0) {
  parse($0)
  if (!LEAF && TYPE != "null") {
    printf "ERROR: silt: join of a list holding a collection\n" > "/dev/stderr"
    exit 1
  }
  if (first) { out = scalar_text($0); first = 0 } else { out = out separator scalar_text($0) }
}

END { if (!first) { printf "%s\n", out } }
