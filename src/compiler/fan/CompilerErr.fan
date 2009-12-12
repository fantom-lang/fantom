//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 May 06  Brian Frank  Creation
//

**
** CompilerErr - instances should always be created via CompilerStep.err().
**
const class CompilerErr : Err
{

  new make(Str msg, Location? location, Err? cause := null, LogLevel level := LogLevel.error)
    : super(msg, cause)
  {
    this.level = level
    if (location != null)
    {
      this.file = location.file
      this.line = location.line
      this.col  = location.col
    }
  }

  Location location()
  {
    return Location(file, line, col)
  }

  Bool isError() { level === LogLevel.error }

  Bool isWarn() { level === LogLevel.warn }

  const LogLevel level
  const Str? file
  const Int? line
  const Int? col
}