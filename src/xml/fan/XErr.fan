//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** XML exception.
**
const class XErr : Err
{

// TODO: add starting line of error - see issue 945

  **
  ** Construct with optional message, line number, and root cause.
  **
  new make(Str? message := null, Int line := 0, Int col := 0, Err? cause := null)
    : super(message, cause)
  {
    this.line = line
    this.col  = col
  }

  **
  ** String representation.
  **
  override Str toStr()
  {
    s := super.toStr
    if (line > 0)
    {
      if (col > 0)
        s += " [line $line, col $col]"
      else
        s += " [line $line]"
    }
    return s
  }

  **
  ** Line number of XML error or zero if unknown.
  **
  const Int line

  **
  ** Column number of XML error or zero if unknown.
  **
  const Int col

}