//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 08  Brian Frank  Creation
//

using fwt

**
** Console is used to run external programs and capture output.
**
@fluxSideBar
internal class Console : SideBar
{

  new make()
  {
    content = FooBox { bg = Color.white }
  }

  override Obj prefAlign() { return Valign.bottom }

}

/*
@fluxSideBar
internal class LeftGreen : SideBar
{
  new make() { content = FooBox { bg = Color.green } }
  override Obj prefAlign() { return Halign.left }
}

@fluxSideBar
internal class LeftRed : SideBar
{
  new make() { content = FooBox { bg = Color.red } }
  override Obj prefAlign() { return Halign.left }
}

@fluxSideBar
internal class RightYellow : SideBar
{
  new make() { content = FooBox { bg = Color.yellow } }
  override Obj prefAlign() { return Halign.right }
}

@fluxSideBar
internal class RightBlue : SideBar
{
  new make() { content = FooBox { bg = Color.blue } }
  override Obj prefAlign() { return Halign.right }
}

@fluxSideBar
internal class BottomGray : SideBar
{
  new make() { content = FooBox { bg = Color.gray } }
  override Obj prefAlign() { return Valign.bottom }
}

@fluxSideBar
internal class BottomOrange : SideBar
{
  new make() { content = FooBox { bg = Color.orange } }
  override Obj prefAlign() { return Valign.bottom }
}
*/

internal class FooBox : Widget
{
  Color bg
  override Void onPaint(Graphics g)
  {
    w := size.w
    h := size.h
    g.brush = bg
    g.fillRect(0, 0, w, h)
    g.brush = Color.black
    g.drawRect(1, 1, w-2, h-2)
  }
}
