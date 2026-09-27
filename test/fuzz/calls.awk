# The twins file of one fuzz case, for test/silt-fuzz.sh: the SILT calls to
# run over the value read from value.json, each paired with the jq program
# that must answer the same over the JSON, "<call> => <jq program>". The
# paths come in on stdin as test/fuzz/paths.jq prints them; a seed picks
# which are exercised, drawn by a Lehmer generator of this file's own, the
# root's type comes in as -v root=, -v yaml=0 leaves the YAML out, and
# -v toml=1 brings the TOML in. Over every collection read, the verbs over
# each run with the transcript's callbacks; over every scalar, the truth
# verbs and string with a default.
#
#   awk -v seed=7 -v root=object -f calls.awk paths  ->  as d from_json value.json
#                                                        to_json @d => tojson
#                                                        string @d ."a"[0] => getpath(["a",0])

# The next draw, from 0 up to but not 1: Lehmer's generator.
function draw() {
  STATE = (STATE * 48271) % 2147483647
  return (STATE - 1) / 2147483646
}

# A whole number from 0 up to but not n.
function pick(n) {
  return int(draw() * n)
}

# Keeps one path with its spellings, its type, its parent's path and its key.
function keep_path(line, __part) {
  split(line, __part, "\037")
  PATHS++
  SILT[PATHS] = __part[1]
  JQ[PATHS] = __part[2]
  TYPE[PATHS] = __part[3]
  PARENT[PATHS] = __part[4]
  KEY[PATHS] = __part[5]
}

# Whether the collection whose path is <parent>, as getpath takes it, holds a
# member of the type.
function holds_member_of_type(parent, type, __j) {
  for (__j = 1; __j <= PATHS; __j++) {
    if (PARENT[__j] == parent && TYPE[__j] == type) {
      return 1
    }
  }

  return 0
}

# A map key of the value, drawn, as its JSON literal; "a" when the value has
# no map key at all.
function drawn_key(__j, __count, __at) {
  __count = 0
  for (__j = 1; __j <= PATHS; __j++) {
    if (KEY[__j] != "") {
      __count++
    }
  }
  if (__count == 0) {
    return "\"a\""
  }

  __at = pick(__count)
  for (__j = 1; __j <= PATHS; __j++) {
    if (KEY[__j] != "" && __at-- == 0) {
      return KEY[__j]
    }
  }
}

# Whether the collection whose path is <parent>, as getpath takes it, holds
# any member at all.
function holds_member(parent, __j) {
  for (__j = 1; __j <= PATHS; __j++) {
    if (PARENT[__j] == parent) {
      return 1
    }
  }

  return 0
}

# The text of a key literal a verb can take as one word, since the transcript
# splits a writer's or a collection verb's words on spaces and the shell
# would expand a glob: none of a space, a backslash, a quote, a star, a
# question mark or a bracket inside; nothing when the literal holds one.
function plain_text(literal, __text) {
  __text = substr(literal, 2, length(literal) - 2)
  if (__text == "" || __text ~ /[ \\"*?[\]]/) {
    return ""
  }

  return __text
}

# The verbs over each, run over a collection: <doc> names it for a call, <at>
# is the jq expression for the value there, and <parent> its path as getpath
# takes it, for what it holds. map and filter take the transcript's
# callbacks, which read the member with the reader verbs; find only where a
# list member exists, since it answers nothing otherwise; pluck with a key
# drawn from the value's own, and has_at and project with it where it is one
# plain word.
function each_calls(doc, at, parent, __n, __key, __text) {
  EACH_CALLS++
  __n = EACH_CALLS
  print "as m" __n " map " doc " str_of_key"
  print "to_json @m" __n " => " at " | (if type == \"array\" then [keys[] | tostring] else with_entries(.value = .key) end) | tojson"
  print "as g" __n " map " doc " value_at ."
  print "to_json @g" __n " => " at " | tojson"
  print "as f" __n " filter " doc " is_list"
  print "to_json @f" __n " => " at " | (if type == \"array\" then map(select(type == \"array\")) else with_entries(select(.value | type == \"array\")) end) | tojson"
  print "any " doc " is_list => " at " | any(.[]; type == \"array\")"
  print "all " doc " is_list => " at " | all(.[]; type == \"array\")"

  if (holds_member_of_type(parent, "array")) {
    print "as x" __n " find " doc " is_list"
    print "to_json @x" __n " => " at " | first(.[] | select(type == \"array\")) | tojson"
  }

  __key = drawn_key()
  print "as p" __n " pluck " doc " ."
  print "to_json @p" __n " => " at " | [.[]] | tojson"
  print "as q" __n " pluck " doc " ." __key
  print "to_json @q" __n " => " at " | [.[] | if type == \"object\" then .[" __key "] else null end] | tojson"
  __text = plain_text(__key)
  if (__text != "") {
    print "as w" __n " filter " doc " has_at ." __key
    print "to_json @w" __n " => " at " | (if type == \"array\" then map(select(type == \"object\" and has(" __key "))) else with_entries(select(.value | type == \"object\" and has(" __key "))) end) | tojson"
    print "as j" __n " project " doc " " __text
    print "to_json @j" __n " => " at " | [.[] | {" __key ": (if type == \"object\" then .[" __key "] else null end)}] | tojson"
  }
}

# The truth verbs and string with a default over a scalar: <doc> names it
# for a call, <path> is its path for string, and <at> the jq expression for
# the value there.
function scalar_verb_calls(doc, path, at, __n) {
  SCALAR_CALLS++
  __n = SCALAR_CALLS
  print "string-or @d none " path " => " at " | if . == null then \"none\" else . end"
  print "as v" __n " get @d " path
  print "is_true @v" __n " => " at " == true"
  print "is_false @v" __n " => " at " == false"
  print "is_zero @v" __n " => " at " == 0"
}

# The calls every case makes over the root: read it, write it back, read it
# again through the .strh and the .strt node wrote, the .strt under the index
# node shuffled, and through YAML in both styles yq writes unless -v yaml=0
# says yq could not spell the value, and through TOML when -v toml=1 says
# TOML holds it.
function root_calls() {
  print "as d from_json value.json"
  print "to_json @d => tojson"
  print "as c canon @d"
  print "equals @d $c => true"
  print "as h from_strh value.strh"
  print "equals @d $h => true"
  print "as i from_json index.json"
  print "as t from_strt value.strt $i"
  print "equals @d $t => true"

  if (yaml != 0) {
    print "as y from_yaml block.yaml"
    print "equals @d $y => true"
    print "as f from_yaml flow.yaml"
    print "equals @d $f => true"
  }
  if (toml != 0) {
    print "as t from_toml table.toml"
    print "equals @d $t => true"
  }
}

# The calls over a root that is a collection: its length, the verbs over
# each, and for a map its keys and a key it does not hold.
function collection_root_calls() {
  print "len @d => length"
  each_calls("@d", ".", "[]")

  if (root == "object") {
    print "as k keys @d"
    print "join @k , => keys_unsorted | join(\",\")"
    print "has @d .\"no such key\" => has(\"no such key\")"
    print "string-or @d none .\"no such key\" => .[\"no such key\"] // \"none\""
    print "as t set @d .\"fresh\" 0.:str=\"new\""
    print "to_json @t => setpath([\"fresh\"]; \"new\") | tojson"
  }
}

# The calls over a path whose value is a scalar: its text, whether it is
# there, and the scalar verbs.
function scalar_calls(i) {
  print "string @d " SILT[i] " => getpath(" JQ[i] ")"
  print "has @d " SILT[i] " => true"
  scalar_verb_calls("@d", SILT[i], "getpath(" JQ[i] ")")
}

# Prints the calls that apply to every collection, a map or a list: read
# the value, write it as JSON, count its members, run the verbs that loop
# over its members, list its values, and write it on one line and read it
# back.
function any_collection_calls(i) {
  print "as s" i " get @d " SILT[i]
  print "to_json @s" i " => getpath(" JQ[i] ") | tojson"
  print "len @s" i " => getpath(" JQ[i] ") | length"
  each_calls("@s" i, "getpath(" JQ[i] ")", JQ[i])

  print "as l" i " values @s" i
  print "to_json @l" i " => getpath(" JQ[i] ") | [.[]] | tojson"
  print "line @s" i " => \"one line: true\\nidentity: true\""
}

# Prints the calls that apply to a map: its keys, its entries, and the root
# merged with it when the root is a map too.
function map_calls(i) {
  print "as k" i " keys @s" i
  print "join @k" i " , => getpath(" JQ[i] ") | keys_unsorted | join(\",\")"
  print "as n" i " entries @s" i
  print "to_json @n" i " => getpath(" JQ[i] ") | to_entries | tojson"

  if (root == "object") {
    print "as m" i " merge @d $s" i
    print "to_json @m" i " => . + getpath(" JQ[i] ") | tojson"
  }
}

# Prints the calls that take part of a list: a slice, and the first and
# last element. The first and last element are only asked for when the
# list has a member, because an empty list has neither.
function list_part_calls(i) {
  print "as c" i " slice @s" i " 1 3"
  print "to_json @c" i " => getpath(" JQ[i] ") | .[1:3] | tojson"

  if (holds_member(JQ[i])) {
    print "as a" i " first @s" i
    print "to_json @a" i " => getpath(" JQ[i] ") | .[0] | tojson"
    print "as z" i " last @s" i
    print "to_json @z" i " => getpath(" JQ[i] ") | .[-1] | tojson"
  }
}

# Prints the calls that treat a list as a set: its unique values, and its
# intersection and difference with itself.
function list_set_calls(i) {
  print "as u" i " unique @s" i
  print "to_json @u" i " => getpath(" JQ[i] ") | reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end) | tojson"
  print "as i" i " intersect @s" i " $s" i
  print "to_json @i" i " => getpath(" JQ[i] ") | tojson"
  print "as e" i " difference @s" i " $s" i
  print "to_json @e" i " => [] | tojson"
}

# Prints the calls for a path whose value is a map or a list.
function collection_calls(i) {
  any_collection_calls(i)

  if (TYPE[i] == "object") {
    map_calls(i)
  } else {
    list_part_calls(i)
    list_set_calls(i)
  }
}

# A set at the path: an int put in place of whatever is there, and the whole
# document written back.
function set_calls(i) {
  print "as t" i " set @d " SILT[i] " 0.:int=41"
  print "to_json @t" i " => setpath(" JQ[i] "; 41) | tojson"
}

# The calls over one path, by the type of the value there. A set is drawn
# only for a path with no space and no backslash in it, since the
# transcript splits a writer's words on spaces and reads them through
# printf %b.
function path_calls(i) {
  if (TYPE[i] == "object" || TYPE[i] == "array") {
    collection_calls(i)
  } else {
    scalar_calls(i)
  }

  if (pick(3) == 0 && index(SILT[i], " ") == 0 && index(SILT[i], "\\") == 0) {
    set_calls(i)
  }
}

# The calls over up to eight paths drawn from the value.
function drawn_path_calls(__count, __i) {
  __count = (PATHS < 8) ? PATHS : 8

  for (__i = 0; __i < __count; __i++) {
    path_calls(1 + pick(PATHS))
  }
}

# Keeps every path for END.
function main() {
  keep_path($0)
}

BEGIN {
  STATE = ((seed + 7919) % 2147483646) + 1
  PATHS = 0
  EACH_CALLS = 0
  SCALAR_CALLS = 0
}

END {
  root_calls()
  if (root == "object" || root == "array") {
    collection_root_calls()
  } else {
    scalar_verb_calls("@d", ".", ".")
  }
  drawn_path_calls()
}

{ main() }
