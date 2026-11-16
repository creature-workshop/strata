#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/project.sh: @project.
FRAGMENT

: <<'PUB_FUN'
Keeps only the keys named in each record of a list. The answer is a list
with one map for each record, in the records' order. Each map has the keys
that were named, in the order they were named, with the record's values.
It is what `SELECT name, status` does to the rows of a table.

A key that a record lacks is in its map with a null. Given a map and not
a list, the verb takes the map's values as the records.

Three build records, each with a name, a status and a log:

  records="$(cat <<'SILT'
  0.0:map
  1."name":str="build"
  1."status":str="passed"
  1."log":str="42 lines"
  0.1:map
  1."name":str="lint"
  1."status":str="failed"
  1."log":str="7 lines"
  0.2:map
  1."name":str="docs"
  1."status":str="passed"
  1."log":str="3 lines"
  SILT
  )"

Keep the name and the status, and leave the log out:

  @project shown "$records" name status

  shown is:
    0.0:map
    1."name":str="build"
    1."status":str="passed"
    0.1:map
    1."name":str="lint"
    1."status":str="failed"
    0.2:map
    1."name":str="docs"
    1."status":str="passed"

The same, written as JSON:

  records  [{"name": "build", "status": "passed", "log": "42 lines"},
            {"name": "lint",  "status": "failed", "log": "7 lines"},
            {"name": "docs",  "status": "passed", "log": "3 lines"}]

  shown    [{"name": "build", "status": "passed"},
            {"name": "lint",  "status": "failed"},
            {"name": "docs",  "status": "passed"}]

Ask for a key no record has, and each map has it with a null:

  @project owners "$records" name owner

  owners, written as JSON:
    [{"name": "build", "owner": null},
     {"name": "lint",  "owner": null},
     {"name": "docs",  "owner": null}]

args:
  $1  The name of the variable to answer in
  $2  The SILT document, a map or a list
  $@  The keys, at least one
PUB_FUN
@project() {
  silt__project "$@"
}
