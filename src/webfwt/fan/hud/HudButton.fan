//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Mar 10  Andy Frank  Creation
//

using fwt
using gfx

**
** HudButton.
**
@NoDoc
@Js
class HudButton : MiniButton
{
  **
  ** Constructor
  **
  new make(|This|? f := null) : super(f) {}

  // force peer
  private native Void dummy()

}

