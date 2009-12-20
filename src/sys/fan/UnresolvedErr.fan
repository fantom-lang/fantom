//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Nov 07  Brian Frank  Creation
//

**
** UnresolvedErr indicates the failure to resolve a Uri to a resource.
**
const class UnresolvedErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}