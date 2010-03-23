//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Mar 10  Brian Frank  Creation
//

**
** FieldNotSetErr indicates a non-nullable field was not
** set by the constructor it-block.
**
const class FieldNotSetErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}