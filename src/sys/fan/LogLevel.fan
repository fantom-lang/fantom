//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 06  Brian Frank  Creation
//

**
** LogLevel provides a set of discrete levels used to customize logging.
** See `docLang::Logging` for details.
**
enum class LogLevel
{
  debug,
  info,
  warn,
  err,
  silent
}