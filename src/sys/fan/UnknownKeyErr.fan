//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 Mar 12  Brian Frank  Creation
//

**
** UnknownKeyErr indicates an attempt to lookup a non-existent key.
**
const class UnknownKeyErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}
