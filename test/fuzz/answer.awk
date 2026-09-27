# The answer lines of one block of a transcript, the block numbered from 1
# by its "## " header and named by -v wanted=: what follows the header up
# to the next.
#
#   awk -v wanted=2 -f answer.awk transcript  ->  the second call's answer

# Counts a header, and prints the lines of the block wanted.
function main() {
  if ($0 ~ /^## /) {
    block++
    return
  }

  if (block == wanted) {
    print
  }
}

{ main() }
