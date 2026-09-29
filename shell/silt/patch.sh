#!/bin/sh

: <<'PUB_FUN'
Puts each value that is given at its path, as silt__set does, and leaves
out every pair whose value is the empty string. A caller can pass all the
fields it might change, and only the ones that have a value are written.

  silt__patch doc '0."a":int=1' .a '' .b '0.:int=2'   ->  doc='0."a":int=1
                                                               0."b":int=2'

args:
  $1  The name of the variable to answer in
  $2  The document
  $@  A path and a value, pair by pair
PUB_FUN
silt__patch() {
  __silt__paths__set_pairs true "$@"
}
