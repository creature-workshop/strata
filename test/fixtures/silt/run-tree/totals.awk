# Prints a map with the sum and the mean of the list "numbers" of the
# document. It calls put(), which tree_edit.awk defines, and
# number_written(), which numbers.awk defines.

function main(line) {
  tree_line(line)
}

# The sum of the numbers in a list.
function sum_of(list, __element, __sum) {
  __sum = 0
  for (__element = NODE_FIRST[list]; __element != 0; __element = NODE_NEXT[__element]) {
    __sum += text_of(__element)
  }

  return __sum
}

BEGIN {
  ROOT = tree_open()
}

END {
  if (REFUSED) {
    exit 1
  }

  numbers = member(ROOT, "numbers")
  totals = new_node("", "map")
  put(totals, "sum", number_written(sum_of(numbers)))
  put(totals, "mean", number_written(sum_of(numbers) / NODE_COUNT[numbers]))
  print_document(totals)
}

{ main($0) }
