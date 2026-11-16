#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/option.sh: @option, @option_is.
FRAGMENT

: <<'PUB_FUN'
Answers the text of the option at a key, the way @string answers it.
Answers the default when the map does not hold the key, or holds a null or
a collection there. The key is the option's name as plain text, not a path.

  @option how '0."arrays":str="union"' arrays replace   ->  how=union
  @option how '0.:map' arrays replace                   ->  how=replace

  The same, with each SILT document written as JSON:

    @option how {"arrays":"union"} arrays replace   ->  how=union
    @option how {} arrays replace   ->  how=replace

args:
  $1  The name of the variable to answer in
  $2  The map of options
  $3  The key
  $4  The default; the empty string when not given
PUB_FUN
@option() {
  silt__option "$@"
}

: <<'PUB_FUN'
Answers true when the option at a key has the text given, and false
otherwise. An option that is missing or null never matches, whatever text
is given.

  @option_is yes '0."arrays":str="union"' arrays union   ->  yes=true
  @option_is yes '0.:map' arrays ''                      ->  yes=false

  The same, with each SILT document written as JSON:

    @option_is yes {"arrays":"union"} arrays union   ->  yes=true
    @option_is yes {} arrays ''   ->  yes=false

args:
  $1  The name of the variable to answer in
  $2  The map of options
  $3  The key
  $4  The text to compare with
PUB_FUN
@option_is() {
  silt__option_is "$@"
}
