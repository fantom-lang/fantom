//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 09  Brian Frank  Creation
//

**
** TimeoutErr indicates that a blocking operation
** timed out before normal completion.
**
const class TimeoutErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}