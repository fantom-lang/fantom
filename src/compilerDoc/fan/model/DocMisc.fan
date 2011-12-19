//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

**
** DocPage is the base class for encapsulating documents
** which are logically one "page".  All docs are organized
** under a pod.  Subclasses include:
**  - `DocPod`: pod index (manual or API)
**  - `DocType`: type API
**  - `DocChapter`: chapter in manual
**
const abstract class DocPage
{
  ** Default title for the document
  abstract Str title()
}

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

