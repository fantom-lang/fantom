//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 May 08  Brian Frank  Creation
//

**
** FandocErr
**
const class FandocErr : Err
{

  new make(Str msg, Str file, Int line, Err? cause := null)
    : super(msg, cause)
  {
    this.file = file
    this.line = line
  }

  override Str toStr()
  {
    return "$msg [$file:$line]"
  }

  const Str file
  const Int line
}