//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jan 06  Brian Frank  Creation
//

**
** Err is the base class of all exceptions.
**
const class Err
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := null, Err cause := null)

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the string message passed to the contructor or null if
  ** a message is not available.
  **
  Str message()

  **
  ** Get the underyling cause exception or null.
  **
  Err cause()

  **
  ** Dump the stack trace of this exception to the specified
  ** output stream (or Sys.out by default).  Return this.
  **
  This trace(OutStream out := Sys.out)

  **
  ** Dump the stack trace of this exception to a Str.
  **
  Str traceToStr()

  **
  ** Return the qualified type name and optional message.
  **
  override Str toStr()

}