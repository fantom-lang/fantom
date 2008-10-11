//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

**
** UnknownHostErr indicates a failure to resolve a hostname to an IP address.
**
const class UnknownHostErr : IOErr
{

  new make(Str msg, Err? cause := null)
    : super(msg, cause)
  {
  }

}