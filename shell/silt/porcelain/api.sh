#!/usr/bin/env bash

: <<'MODULE'
SILT's porcelain: an `@` name for every `silt__` verb, the names every
repository's shell writes (ADR.34@strata). `@get` is `silt__get`: the same
arguments in the same order, and the same answer in the variable named
first. A register always holds a SILT document. A caller that needs text, JSON
or YAML asks for it at the boundary, with @string, @to_json, @to_yaml or
@dump.

  @str name lib
  @obj cfg name "$name"
  @get entry "$cfg" .name       ->  entry is the document 0.:str="lib"
  @string text "$cfg" .name     ->  text=lib
  @to_json json "$cfg"          ->  json={"name":"lib"}

Each `@` name is documented where it is defined, in a file here named for
its verb or its family of verbs, with a leading underscore: @get in
_get.sh, @pop and @shift in _lists.sh. A `silt__` verb's own documentation
points to it.

A caller sources this file to have the names; SILT's own api.sh does not
load it. The names need a shell that accepts `@` in a function's name,
which bash does and dash does not. A program lowered for another shell
calls the `silt__` verb of the same name.
MODULE

: <<'FUN'
Sets __silt__porcelain__DIR to the directory this file sits in: the
porcelain directory under SILT_DIR when that is set, and otherwise the
directory of the file being sourced.
FUN
__silt__porcelain__home() {
  if [ -n "${SILT_DIR:-}" ]; then
    __silt__porcelain__DIR="$SILT_DIR/porcelain"
    return
  fi

  # shellcheck disable=SC3028  # read only where bash set it, empty elsewhere
  __silt__porcelain__DIR="${BASH_SOURCE:-$0}"

  case "$__silt__porcelain__DIR" in
    */*) __silt__porcelain__DIR="${__silt__porcelain__DIR%/*}" ;;
    *) __silt__porcelain__DIR=. ;;
  esac
}

__silt__porcelain__home
if ! command -v silt__read >/dev/null 2>&1; then
  . "$__silt__porcelain__DIR/../api.sh" || return 1
fi
. "$__silt__porcelain__DIR/_all.sh"
. "$__silt__porcelain__DIR/_any.sh"
. "$__silt__porcelain__DIR/_apply.sh"
. "$__silt__porcelain__DIR/_arr.sh"
. "$__silt__porcelain__DIR/_bind.sh"
. "$__silt__porcelain__DIR/_bool.sh"
. "$__silt__porcelain__DIR/_canon.sh"
. "$__silt__porcelain__DIR/_command.sh"
. "$__silt__porcelain__DIR/_concat.sh"
. "$__silt__porcelain__DIR/_deepmerge.sh"
. "$__silt__porcelain__DIR/_defined.sh"
. "$__silt__porcelain__DIR/_difference.sh"
. "$__silt__porcelain__DIR/_dump.sh"
. "$__silt__porcelain__DIR/_each.sh"
. "$__silt__porcelain__DIR/_entries.sh"
. "$__silt__porcelain__DIR/_filter.sh"
. "$__silt__porcelain__DIR/_find.sh"
. "$__silt__porcelain__DIR/_flatten.sh"
. "$__silt__porcelain__DIR/_from_entries.sh"
. "$__silt__porcelain__DIR/_get.sh"
. "$__silt__porcelain__DIR/_group_by.sh"
. "$__silt__porcelain__DIR/_has.sh"
. "$__silt__porcelain__DIR/_intersect.sh"
. "$__silt__porcelain__DIR/_join.sh"
. "$__silt__porcelain__DIR/_keys.sh"
. "$__silt__porcelain__DIR/_len.sh"
. "$__silt__porcelain__DIR/_lists.sh"
. "$__silt__porcelain__DIR/_load.sh"
. "$__silt__porcelain__DIR/_map.sh"
. "$__silt__porcelain__DIR/_member.sh"
. "$__silt__porcelain__DIR/_merge.sh"
. "$__silt__porcelain__DIR/_min.sh"
. "$__silt__porcelain__DIR/_obj.sh"
. "$__silt__porcelain__DIR/_option.sh"
. "$__silt__porcelain__DIR/_pick.sh"
. "$__silt__porcelain__DIR/_pluck.sh"
. "$__silt__porcelain__DIR/_project.sh"
. "$__silt__porcelain__DIR/_push.sh"
. "$__silt__porcelain__DIR/_read.sh"
. "$__silt__porcelain__DIR/_reduce.sh"
. "$__silt__porcelain__DIR/_run.sh"
. "$__silt__porcelain__DIR/_scalar.sh"
. "$__silt__porcelain__DIR/_set.sh"
. "$__silt__porcelain__DIR/_sort.sh"
. "$__silt__porcelain__DIR/_sort_by.sh"
. "$__silt__porcelain__DIR/_split.sh"
. "$__silt__porcelain__DIR/_str.sh"
. "$__silt__porcelain__DIR/_string.sh"
. "$__silt__porcelain__DIR/_sum.sh"
. "$__silt__porcelain__DIR/_text.sh"
. "$__silt__porcelain__DIR/_text_is.sh"
. "$__silt__porcelain__DIR/_text_is_not.sh"
. "$__silt__porcelain__DIR/_text_starts_with.sh"
. "$__silt__porcelain__DIR/_time.sh"
. "$__silt__porcelain__DIR/_translate.sh"
. "$__silt__porcelain__DIR/_truth.sh"
. "$__silt__porcelain__DIR/_type.sh"
. "$__silt__porcelain__DIR/_unique.sh"
. "$__silt__porcelain__DIR/_validate.sh"
. "$__silt__porcelain__DIR/_validate_file.sh"
. "$__silt__porcelain__DIR/_values.sh"
