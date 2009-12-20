//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jan 07  Brian Frank  Creation
//

**
** InterruptedErr indicates that a thread is interrupted from
** its normal execution.
**
const class InterruptedErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}