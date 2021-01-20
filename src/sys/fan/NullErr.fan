//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jan 06  Brian Frank  Creation
//

**
** NullErr indicates an attempt to dereference null.  It is
** often raised when attempting to access an instance field or method
** on a null reference.  It may also be thrown when a parameter is
** expecting a non-nullable argument and null is passed.
**
const class NullErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}