//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Dec 07  Brian Frank  Creation
//

**
** NameErr indicates an attempt use an invalid name.
** See `Uri.isName` and `Uri.checkName`.
**
const class NameErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}