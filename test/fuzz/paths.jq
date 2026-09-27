# Every path of the value but the root, one per line, five fields joined by
# the unit separator: the path as a SILT verb spells it, the array getpath
# takes, the type of the value there, the parent's array, and the last
# segment as its JSON literal when it is a key, else nothing.
#
#   {"a":[1]}  ->  ."a"      ["a"]    array   []     "a"
#                  ."a"[0]   ["a",0]  number  ["a"]

def silt_path: map(if type == "string" then "." + tojson else "[\(.)]" end) | join("");

. as $doc
| [paths]
| .[]
| . as $path
| [silt_path, tojson, ($doc | getpath($path) | type), (.[:-1] | tojson), (.[-1] | if type == "string" then tojson else "" end)]
| join("\u001f")
