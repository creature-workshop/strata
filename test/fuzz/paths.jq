# Every path of the value but the root, one per line, three fields joined by
# the unit separator: the path as a SILT verb spells it, the array getpath
# takes, and the type of the value there.
#
#   {"a":[1]}  ->  ."a"      ["a"]    array
#                  ."a"[0]   ["a",0]  number

def silt_path: map(if type == "string" then "." + tojson else "[\(.)]" end) | join("");

. as $doc
| [paths]
| .[]
| . as $path
| [silt_path, tojson, ($doc | getpath($path) | type)]
| join("\u001f")
