# Prints the map "config" of the document with some of its values changed.
# It calls the functions that tree_edit.awk defines.

function main(line) {
  tree_line(line)
}

# Changes the config: a value replaced, a value added, a map created under
# a name, a node copied under another name, and elements appended to a
# list.
function edit(config, __paths, __extra, __labels, __node) {
  put(config, "enabled", "bool=true")
  put(config, "retries", "int=3")
  put(map_under(config, "report"), "format", "str=\"junit\"")
  put(map_under(config, "runner"), "name", "str=\"bats\"")

  __paths = member(config, "paths")
  put_node(config, "watched", __paths)
  put_node(config, "missing", member(config, "no such member"))
  append_text(__paths, "test \"quoted\"")

  __node = new_node("", "null")
  write_value(__node, "int=7")
  append_node(__paths, __node)

  __extra[1] = "fast"
  __extra[2] = "unit"
  __labels = list_of_texts(__extra, 2)
  put_node(config, "labels", __labels)
}

BEGIN {
  ROOT = tree_open()
}

END {
  if (REFUSED) {
    exit 1
  }

  edit(member(ROOT, "config"))
  print_document(member(ROOT, "config"))
}

{ main($0) }
