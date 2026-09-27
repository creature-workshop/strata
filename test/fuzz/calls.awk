# The twins file of one fuzz case, for test/silt-fuzz.sh: the SILT calls to
# run over the value read from value.json, each paired with the jq program
# that must answer the same over the JSON, "<call> => <jq program>". The
# paths come in on stdin as test/fuzz/paths.jq prints them; a seed picks
# which are exercised, drawn by a Lehmer generator of this file's own, the
# root's type comes in as -v root=, -v yaml=0 leaves the YAML out, and
# -v toml=1 brings the TOML in.
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

# Keeps one path with its spellings and type.
function keep_path(line, __part) {
  split(line, __part, "\037")
  PATHS++
  SILT[PATHS] = __part[1]
  JQ[PATHS] = __part[2]
  TYPE[PATHS] = __part[3]
}

# The calls every case makes over the root: read it, write it back, and
# read it again through YAML in both styles yq writes unless -v yaml=0 says
# yq could not spell the value, and through TOML when -v toml=1 says TOML
# holds it.
function root_calls() {
  print "as d from_json value.json"
  print "to_json @d => tojson"
  print "as c canon @d"
  print "equals @d $c => true"

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

# The calls over a root that is a collection: its length, and for a map its
# keys and a key it does not hold.
function collection_root_calls() {
  print "len @d => length"

  if (root == "object") {
    print "as k keys @d"
    print "join @k , => keys | join(\",\")"
    print "has @d .\"no such key\" => has(\"no such key\")"
    print "as t set @d .\"fresh\" 0.:str=\"new\""
    print "to_json @t => setpath([\"fresh\"]; \"new\") | tojson"
  }
}

# The calls over a path whose value is a scalar: its text, and whether it
# is there.
function scalar_calls(i) {
  print "string @d " SILT[i] " => getpath(" JQ[i] ")"
  print "has @d " SILT[i] " => true"
}

# The calls over a path whose value is a collection: the value as JSON, its
# length, and for a map its keys.
function collection_calls(i) {
  print "as s" i " get @d " SILT[i]
  print "to_json @s" i " => getpath(" JQ[i] ") | tojson"
  print "len @s" i " => getpath(" JQ[i] ") | length"

  if (TYPE[i] == "object") {
    print "as k" i " keys @s" i
    print "join @k" i " , => getpath(" JQ[i] ") | keys | join(\",\")"
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
}

END {
  root_calls()
  if (root == "object" || root == "array") {
    collection_root_calls()
  }
  drawn_path_calls()
}

{ main() }
