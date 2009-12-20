//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Apr 06  Brian Frank  Creation
//

**
** ReadonlyErr indicates an attempt to modify a readonly instance;
** it is commonly used with List and Map.
**
const class ReadonlyErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}