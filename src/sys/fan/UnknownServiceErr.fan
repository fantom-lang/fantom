//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  Brian Frank  Creation
//   26 Mar 09  Brian Frank  Renamed from UnknownThreadErr
//

**
** UnknownServiceErr indicates an attempt to lookup an service
** not installed.  See `Service.find`.
**
const class UnknownServiceErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null)

}