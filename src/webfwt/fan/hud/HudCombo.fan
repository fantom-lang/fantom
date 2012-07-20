//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jun 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** HudCombo.
**
@NoDoc
@Js
class HudCombo : WebCombo
{
  ** It-block constructor.
  new make(|This|? f := null) : super(f) {}

  // force peer
  private native Void dummy()
}
