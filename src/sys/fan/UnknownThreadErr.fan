//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  Brian Frank  Creation
//

**
** UnknownThreadErr indicates an attempt to lookup an unknown thread.
**
const class UnknownThreadErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := null, Err cause := null)

}