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
** Build tool
**
class Build : FluxCommand
{
  new make(Str id) : super(id) {}

  override Void invoke(Event event)
  {
    echo("---- TODO Build tool! ----")
  }
}