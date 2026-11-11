# Prints the document it was given as it is, through print_document.

function main(line) {
  tree_line(line)
}

BEGIN {
  ROOT = tree_open()
}

END {
  if (REFUSED) {
    exit 1
  }

  print_document(ROOT)
}

{ main($0) }
