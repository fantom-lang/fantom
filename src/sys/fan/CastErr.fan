//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jun 06  Brian Frank  Creation
//

**
** CastErr is a runtime exception raised when invalid cast is performed.
**
const class CastErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}