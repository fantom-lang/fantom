//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 09  Brian Frank  Creation
//

**
** UnknownSymbolErr indicates an attempt to access a non-existent symbol.
**
const class UnknownSymbolErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str? msg := null, Err? cause := null)

}