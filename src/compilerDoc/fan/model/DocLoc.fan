//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

**
** DocLoc models a filename / linenumber
**
const class DocLoc
{
  ** Construct with file and optional line number
  new make(Str file, Int? line := null)
  {
    this.file = file
    this.line = line
  }

  ** Filename location
  const Str file

  ** Line number of null if unknown
  const Int? line

  ** Return string representation
  override Str toStr()
  {
    if (line == null) return file
    return "$file [Line $line]"
  }
}