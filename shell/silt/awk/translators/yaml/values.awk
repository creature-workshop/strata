# The value a line's text spells, written into the SILT writer: a flow
# collection read member by member, a quoted scalar as the str it holds, and
# a plain scalar as the null, bool, number or str YAML's core schema reads.
# A number spelled outside ADR.20's patterns is written as the map ADR.20
# gives it, its value in ADR.20's form beside the spelling and the format.
# Loaded after translators/write.awk and lines.awk and scalars.awk beside
# this one, with flow.awk.
#
#   write_inline("\"a\"", "0x1F")  ->  0."a":map
#                                      1."format":str="yaml"
#                                      1."spelling":str="0x1F"
#                                      1."value":int=31

# Refuses a value or a key that opens with a construct this reader leaves
# out.
function refuse_unread(text) {
  if (text ~ /^&/) {
    refuse_yaml("an anchor")
  }
  if (text ~ /^\*/) {
    refuse_yaml("an alias")
  }
  if (text ~ /^!/) {
    refuse_yaml("a tag")
  }
}

# Writes the value written on the rest of one line under <key>: a flow
# collection, a quoted scalar, or a plain one.
function write_inline(key, text) {
  refuse_unread(text)

  if (text ~ /^[\[{]/) {
    read_flow(key, text)
  } else if (text ~ /^["']/) {
    write_scalar(key, "str", wrap(unquote_whole(text)))
  } else {
    write_plain(key, text)
  }
}

# The text a quoted scalar holds when the scalar is the whole of the text.
function unquote_whole(text, __end) {
  __end = quote_end(text, 1)

  if (__end == 0) {
    refuse_yaml("a quoted scalar that runs over lines")
  }
  if (__end != length(text) + 1) {
    refuse_yaml("text after the end of a quoted scalar")
  }

  return unquote(text)
}

# Writes a plain scalar under <key> as the value its kind names.
function write_plain(key, text, __kind) {
  __kind = plain_kind(text)

  if (__kind == "null") {
    write_scalar(key, "null", "")
  } else if (__kind == "bool") {
    write_scalar(key, "bool", tolower(text))
  } else if (__kind == "number") {
    write_yaml_number(key, text)
  } else {
    write_scalar(key, "str", wrap(text))
  }
}

# Writes a number under <key>: as an int or a float when ADR.20 spells it
# so, and otherwise as the map that keeps the spelling.
function write_yaml_number(key, text, __adr) {
  __adr = adr_number(text)

  if (__adr == text) {
    write_number(key, text)
    return
  }

  open_collection("map", key)
  write_scalar("\"format\"", "str", "\"yaml\"")
  write_scalar("\"spelling\"", "str", wrap(text))
  write_number("\"value\"", __adr)
  close_collection()
}
