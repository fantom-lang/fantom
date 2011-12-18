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
  const static DocLoc unknown := DocLoc("Unknown", 0)

  ** Construct with file and line number (zero if unknown)
  new make(Str file, Int line)
  {
    this.file = file
    this.line = line
  }

  ** Filename location
  const Str file

  ** Line number or zero if unknown
  const Int line

  ** Return string representation
  override Str toStr()
  {
    if (line <= 0) return file
    return "$file [Line $line]"
  }
}

**
** Fandoc string for a type or slot
**
const class DocFandoc
{
  ** Construct from `loc` and `text`
  new make(DocLoc loc, Str text)
  {
    this.loc = loc
    this.text = text
  }

  ** Location of fandoc in source file
  const DocLoc loc

  ** Plain text fandoc string
  const Str text
}

