#!/usr/bin/env bash

: <<'FRAGMENT'
The `@` names in shell/silt/time.sh: @time, @now.
FRAGMENT

: <<'PUB_FUN'
Creates a time document from an RFC 3339 date-time string. The string must
include a UTC offset (Z or +HH:MM). The result is converted to UTC, and the
fractional seconds are padded with zeros to nine digits.

Fails if the string is not a valid date-time, has no offset, has a field
that is out of range, names a day that does not exist, or has more than
nine fractional digits. Values are never rounded.

  @time doc '2026-09-22T08:10:04.5+02:00'
    ->  doc='0.:time-rfc3339-utc=2026-09-22T06:10:04.500000000Z'

args:
  $1  Name of the variable that receives the result
  $2  The date-time string. The date and time may be separated by T, t or
      a space.
PUB_FUN
@time() {
  silt__time "$@"
}

: <<'PUB_FUN'
Creates a time document for the current time. Runs the date command once.
If date does not support fractional seconds (BSD date does not), the
fraction is nine zeros.

  @now doc   ->  doc='0.:time-rfc3339-utc=2026-09-27T14:03:11.402118337Z'

  The same, with each SILT document written as JSON:

    @now doc   ->  doc="2026-09-27T14:03:11.402118337Z"

args:
  $1  Name of the variable that receives the result
PUB_FUN
@now() {
  silt__now "$@"
}
