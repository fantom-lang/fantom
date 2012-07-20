//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Feb 2012  Andy Frank  Creation
//

using fwt
using gfx

**
** HudText.
**
@Js
class HudText : WebText
{
  ** Constructor.
  new make(|This|? f := null) : super(f) {}

  // force peer
  private native Void dummy()
}

