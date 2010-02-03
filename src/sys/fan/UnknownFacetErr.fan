//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 09  Brian Frank  Creation
//   03 Feb 09  Brian Frank  Rename from UnknownSymbolErr
//

**
** UnknownFacetErr indicates an attempt to access a undefined facet.
**
const class UnknownFacetErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}