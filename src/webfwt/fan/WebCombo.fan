//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Dec 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** WebCombo extends Combo with additional functionality.
**
@Js
class WebCombo : Combo
{
  ** It-block constructor.
  new make(|This|? f := null) : super(f) {}

  ** Get display text for item.
  virtual Str itemText(Obj item) { item.toStr }

  // force peer
  private native Void dummy()
}


