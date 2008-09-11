//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Sep 08  Andy Frank  Creation
//

using fwt

**
** ViewTabPane manages ViewTabs.
**
internal class ViewTabPane : Pane
{

  new make()
  {
    add(tabs = TabBar())
  }

  override Void onLayout()
  {
    th := tabs.prefSize.h
    tabs.bounds = Rect(0, 0, size.w, th)
    tabs.relayout
    tabs.repaint

    if (children.size == 1) active = null
    else
    {
      active = children[1]
      active.bounds = Rect(0, th, size.w, size.h-th)
      active.relayout
    }
  }

  override Void onPaint(Graphics g)
  {
    active?.onPaint(g)
  }

  TabBar tabs
  Widget active

}

**************************************************************************
** TabBar
**************************************************************************
internal class TabBar : Widget
{
  override Size prefSize(Hints hints := Hints.def)
  {
    ph := tabInsets.top + 16.max(fontActive.height) + tabInsets.bottom
    return Size(100, ph)
  }

  override Void onPaint(Graphics g)
  {
    w := size.w
    h := size.h

    bg := Gradient.makeLinear(Point(0,0), Color.sysLightShadow, Point(0,h), Color.sysBg)
    outline := Color.sysNormShadow

    icon := parent->active->image as Image
    text := parent->active->text as Str
    font := fontActive

    iw := icon.size.w
    tw := font.width(text) + iw + iconGap + tabInsets.left + tabInsets.right
    th := prefSize.h
    tx := 0
    ty := h - th
    ix := tabInsets.left
    iy := (th - icon.size.h) / 2
    lx := ix + iw + iconGap
    ly := (th - font.height) / 2

    g.brush = bg
    g.fillRect(tx, ty, tw, th)

    g.brush = outline
    g.drawLine(tx, ty, tx, th)
    g.drawLine(tx, ty, tw, tx)
    g.drawLine(tw, ty, tw, th)

    g.font = font
    g.brush = Color.sysFg
    g.drawImage(icon, ix, iy)
    g.drawText(text, lx, ly)

    g.brush = outline
    g.drawLine(tw, th-1, w-1, th-1)
  }

  const Int iconGap       := 5
  const Insets tabInsets  := Insets(5,10,5,5)
  const Font fontActive   := Font(Font.sys.name, Font.sys.size, true)
  const Font fontInactive := Font.sys
}


