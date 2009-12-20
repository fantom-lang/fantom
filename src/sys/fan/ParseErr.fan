//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Aug 07  Brian Frank  Creation
//

**
** ParseErr indicates an invalid string format which cannot be parsed.
** It is often used with 'fromStr' and 'fromLocale' methods.
**
const class ParseErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}