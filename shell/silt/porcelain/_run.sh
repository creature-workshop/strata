#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` name in shell/silt/run.sh: @run.
FRAGMENT

: <<'PUB_FUN'
Runs an awk program over a SILT document in one process, for a transformation
that loops over a document's members. The variable holds what the program
printed, without its last newline: a document when the program prints SILT
lines, as it should, and plain text otherwise. No verb checks which.

The program can be given a second document, values by name, and awk
libraries that two programs share: see options. Refuses a program that is
not a file, and a call with no document.

examples:
  A list of records:

    records="$(cat <<'SILT'
    0.0:map
    1."name":str="build"
    1."status":str="passed"
    0.1:map
    1."name":str="lint"
    1."status":str="failed"
    SILT
    )"

  names.awk prints the name of each record as an element of a list:

    BEGIN { ROOT = tree_open() }

    { tree_line($0) }

    END {
      for (record = NODE_FIRST[ROOT]; record != 0; record = NODE_NEXT[record]) {
        print "0." printed++ ":str=" wrap(text_of(member(record, "name")))
      }
    }

  The program printed SILT lines, so names holds a list document:

    @run names "$dir/names.awk" "$records"

    names is:
      0.0:str="build"
      0.1:str="lint"

  count.awk ends with `print NODE_COUNT[ROOT] " records"`. That is not a
  SILT line, so summary holds plain text:

    @run summary "$dir/count.awk" "$records"   ->  summary='2 records'

  --arg hands the program a value. failed.awk prints the names of the
  records whose status is arg("status"):

    END {
      for (record = NODE_FIRST[ROOT]; record != 0; record = NODE_NEXT[record]) {
        if (text_of(member(record, "status")) == arg("status")) {
          print "0." printed++ ":str=" wrap(text_of(member(record, "name")))
        }
      }
    }

    @run failed "$dir/failed.awk" "$records" --arg status failed   ->  failed='0.0:str="lint"'

  --with hands it a second document, and --load a library. missing.awk
  prints the tools that are wanted and not installed. It opens the second
  document with tree_ahead(), and calls is_listed(), which listed.awk
  defines:

    wanted="$(cat <<'SILT'
    0.0:str="git"
    0.1:str="awk"
    0.2:str="yq"
    SILT
    )"
    installed='0.0:str="git"'

    BEGIN { INSTALLED = tree_ahead(); ROOT = tree_open() }

    { tree_line($0) }

    END {
      for (tool = NODE_FIRST[ROOT]; tool != 0; tool = NODE_NEXT[tool]) {
        if (!is_listed(INSTALLED, text_of(tool))) {
          print "0." printed++ ":str=" wrap(text_of(tool))
        }
      }
    }

    @run missing "$dir/missing.awk" "$wanted" --with "$installed" --load "$dir/listed.awk"

    missing is:
      0.0:str="awk"
      0.1:str="yq"

options:
  Put the options after the SILT document. You can put them in any order, and
  you can use each one more than once. If you put an option before the
  document, the verb reads that option as the SILT document.

  --with <document>
      Passes a second SILT document to the program. The program reads it in
      its BEGIN block by calling tree_ahead(), and then opens the main
      document with tree_open(). If you use --with twice, the program
      calls tree_ahead() twice: the first call returns the first
      document, and the second call returns the second.

  --arg <name> <value>
      Passes a value to the program. The program reads it by calling
      arg("<name>"). The value is plain text, not a SILT document. The name
      can contain letters, digits and underscores. If you use the same
      name twice, the program gets the later value. If the program asks
      for a name you did not pass, it gets the empty string.

  --load <file>
      Loads a file of awk functions that the program can call. If you use
      --load more than once, the files are loaded in the order you gave
      them. They are loaded after SILT's own awk functions and before the
      program. The path cannot contain a newline.

  The verb fails, and says why, in these cases:
    - the option is not one of these three
    - the option has no value after it
    - the name after --arg contains another character
    - the file after --load does not exist

args:
  $1  The name of the variable to answer in
  $2  The awk program, a file
  $3  The SILT document
  $@  The options
PUB_FUN
@run() {
  silt__run "$@"
}
