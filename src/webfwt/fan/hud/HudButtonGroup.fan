//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 10  Andy Frank  Creation
//

using fwt
using gfx

**
** HudButtonGroup.
**
@NoDoc
@Js
class HudButtonGroup : ButtonGroup
{
  new make(Str[] text) : super(text) {}

  protected override Str borderOuter() { "#555" }
  protected override Str borderInner() { "#131313" }

  protected override Color fgNorm() { Color.white }

  protected override Gradient bgNorm() { brushBgNorm }
  protected override Gradient bgDown() { brushBgDown }

  private static const Gradient brushBgNorm := Gradient("0% 0%, 0% 100%, #454545, #3b3b3b 0.5, #313131 0.5")
  private static const Gradient brushBgDown := Gradient("0% 0%, 0% 100%, #121212, #2e2e2e")
}

