//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Sep 08  Brian Frank  Creation
//

using fwt
using flux

**
** Dump debug to stdout
**
class DebugDump : FluxCommand
{
  new make(Str id) : super(id) {}

  override Void invoked(Event? event)
  {
    echo("=============================================")
  }
}