# Prints every function name that more than one line under shell/silt
# defines, with each place that defines it. The shell has one table of
# functions, so a second definition replaces the first without a message.
#
#   awk -f test/silt-names.awk shell/silt/*.sh  ->  __silt__read_json shell/silt/read.sh:177 shell/silt/translate.sh:40

# Keeps the place of one definition under the function's name.
function keep_definition(name, place) {
  COUNT[name]++
  PLACES[name] = PLACES[name] " " place
}

/^[A-Za-z_]+\(\) \{/ {
  keep_definition(substr($1, 1, length($1) - 2), FILENAME ":" FNR)
}

END {
  for (name in COUNT) {
    if (COUNT[name] > 1) {
      print name PLACES[name]
    }
  }
}
