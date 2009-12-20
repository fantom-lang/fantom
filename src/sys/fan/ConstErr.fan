//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Apr 09  Brian Frank  Creation
//

**
** ConstErr indicates an attempt to set a const field after
** the object has been constructed.
**
const class ConstErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}