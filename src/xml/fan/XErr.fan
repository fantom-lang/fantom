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
  ** Line number of XML error or zero if unknown.
  **
  const Int line

  **
  ** Column number of XML error or zero if unknown.
  **
  const Int col

}