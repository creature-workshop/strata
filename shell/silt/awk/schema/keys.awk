# Functions that split a "$ref" into its parts and work out which schema
# document it refers to. Every schema document has a key, which is its
# path. A reference to another document gives the path of that document,
# relative to the document that contains the reference.
#
# This file contains functions only, and needs no other file.
#
#   joined_key("schemas/a.json", "../b.json")   ->  b.json
#   joined_key("", "common/types.json")         ->  common/types.json

# Returns the part of a reference before the "#", which identifies a
# document. It is empty when the reference is to the document that contains
# it.
function document_part(ref, __at) {
  __at = index(ref, "#")

  return (__at > 0) ? substr(ref, 1, __at - 1) : ref
}

# Returns the part of a reference after the first "#", which is a JSON
# pointer into the document. If the reference has a second "#", the pointer
# ends there.
function pointer_part(ref, __at, __rest) {
  __at = index(ref, "#")
  if (__at == 0) {
    return ""
  }

  __rest = substr(ref, __at + 1)
  __at = index(__rest, "#")

  return (__at > 0) ? substr(__rest, 1, __at - 1) : __rest
}

# Adds one segment of a path to the segments kept in SEGMENT_OF_KEY. An
# empty segment and "." are skipped. ".." removes the segment before it,
# unless there is none or it is ".." itself.
function add_segment(segment) {
  if (segment == "" || segment == ".") {
    return
  }
  if (segment == ".." && SEGMENTS_OF_KEY > 0 && SEGMENT_OF_KEY[SEGMENTS_OF_KEY] != "..") {
    SEGMENTS_OF_KEY--
    return
  }

  SEGMENT_OF_KEY[++SEGMENTS_OF_KEY] = segment
}

# Returns the key of the document that a reference refers to. The reference
# is relative to the document that contains it, whose key is <base>: the last
# segment of <base> is replaced by the reference.
function joined_key(base, uri, __part, __count, __i, __key) {
  SEGMENTS_OF_KEY = 0

  __count = split(base, __part, "/")
  for (__i = 1; __i < __count; __i++) {
    add_segment(__part[__i])
  }

  __count = split(uri, __part, "/")
  for (__i = 1; __i <= __count; __i++) {
    add_segment(__part[__i])
  }

  __key = ""
  for (__i = 1; __i <= SEGMENTS_OF_KEY; __i++) {
    __key = __key (__i > 1 ? "/" : "") SEGMENT_OF_KEY[__i]
  }

  return __key
}
