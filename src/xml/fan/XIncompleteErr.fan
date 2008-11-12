//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** Incomplete document exception indicates that the end of stream
** was reached before the end of the document was parsed.
**
const class XIncompleteErr : XErr
{

  **
  ** Construct with optional message, line number, and root cause.
  **
  new make(Str? message := null, Int line := 0, Int col := 0, Err? cause := null)
    : super(message, line, col, cause)
  {
  }

}