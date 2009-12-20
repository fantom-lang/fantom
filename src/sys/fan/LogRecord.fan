//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Dec 07  Brian Frank  Revamp
//

**
** LogRecord all the information of a single logging event.
** See `docLang::Logging` for details.
**
const class LogRecord
{

  **
  ** Constructor with all the fields
  **
  new make(DateTime time, LogLevel level, Str logName, Str message, Err? err := null)

  **
  ** Timestamp of log event
  **
  const DateTime time

  **
  ** Severity level of event
  **
  const LogLevel level

  **
  ** Name of `Log` which generated the event
  **
  const Str logName

  **
  ** Message text event
  **
  const Str msg

** TODO: use `msg`
@deprecated
const Str message

  **
  ** Exception if applicable
  **
  const Err? err

  **
  ** Return standard log format.
  **
  override Str toStr()

  **
  ** Print to the specified output stream.
  **
  Str print(OutStream out := Sys.out)

}