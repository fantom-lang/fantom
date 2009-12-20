//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jan 06  Brian Frank  Creation
//

**
** UnknownPodErr indicates an attempt to access a non-existent pod.
**
const class UnknownPodErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}