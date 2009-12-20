//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Feb 07  Brian Frank  Creation
//

**
** NotImmutableErr indicates using a mutable Obj where an immutable Obj is
** required.  See Obj.isImmutable for the definition of immutability.
**
const class NotImmutableErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}