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
internal class ViewTabPane : ContentPane
{

  **
  ** Construct with one default tab.
  **
  new make(Frame frame)
  {
    this.frame = frame
    this.tabs = [ ViewTab(frame) ]
    this.active = tabs[0]
    this.content = active
    add(tbar = TabBar(this))
  }

  **
  ** Associated flux frame.
  **
  readonly Frame frame

  **
  ** Get the active tab.
  **
  readonly ViewTab active

  **
  ** Get a listing of all the tabs.
  **
  readonly ViewTab[] tabs

  **
  ** Get a listing of all the tabs mapped to views.
  **
  View[] views()
  {
    return tabs.map(View[,]) |ViewTab t->View| { return t.view }
  }

  **
  ** Create a new tab.  The new tab is not selected.  It
  ** is up the caller to select it once loading is complete.
  **
  ViewTab newTab()
  {
    tab := ViewTab(frame)
    tabs.add(tab)
    select(tab)
    return tab
  }

  **
  ** Select the specified view tab as the new active tab.
  **
  Void select(ViewTab tab)
  {
    onSelect(Event { data=tab })
  }

  **
  ** Handle new tab selection
  **
  Void onSelect(Event event)
  {
    oldActive := this.active
    this.active = event.data
    if (active === oldActive) return
    oldActive.deactivate
    active.activate
    content = active
    relayout
  }

  **
  ** Layout widget.
  **
  override Void onLayout()
  {
    th := 0

    if (tabs.size == 1)
    {
      tbar.bounds = Rect(0,0,0,0)
    }
    else
    {
      th = tbar.prefSize.h
      tbar.bounds = Rect(0, 0, size.w, th)
      tbar.relayout
      tbar.repaint
    }

    content.bounds = Rect(0, th, size.w, size.h-th)
    content.relayout
    content.repaint
  }

  private TabBar tbar

}

**************************************************************************
** TabBar
**************************************************************************
internal class TabBar : Widget
{
  new make(ViewTabPane pane)
  {
    this.pane = pane
    onMouse.add(&pressed)
  }

  override Size prefSize(Hints hints := Hints.def)
  {
    ph := tabInsets.top + 16.max(fontActive.height) + tabInsets.bottom
    return Size(100, ph)
  }

  override Void onPaint(Graphics g)
  {
    w  := size.w
    h  := size.h
    tx := 0

    outline := Color.sysNormShadow
    bgActive := gradient(Color.sysLightShadow, Color.sysBg, h)
    bgInactive := gradient(Color.sysBg, Color.sysNormShadow, h)

    tabBounds.clear

    pane.tabs.each |ViewTab tab|
    {
      icon := tab.image
      text := tab.text

      active := tab === pane.active
      font   := active ? fontActive : fontInactive
      bg     := active ? bgActive : bgInactive

      // use active font for layout to keep width consistent
      iw := icon.size.w
      tw := fontActive.width(text) + iw + iconGap + tabInsets.left + tabInsets.right
      th := prefSize.h
      ty := h - th
      ix := tx + tabInsets.left
      iy := (th - icon.size.h) / 2
      lx := ix + iw + iconGap
      ly := (th - font.height) / 2

      g.brush = bg
      g.fillRect(tx, ty, tw, th)

      g.brush = outline
      g.drawLine(tx,    ty, tx,    th)
      g.drawLine(tx,    ty, tx+tw, ty)
      g.drawLine(tx+tw, ty, tx+tw, th)

      g.font = font
      g.brush = Color.sysFg
      g.drawImage(icon, ix, iy)
      g.drawText(text, lx, ly)

      g.brush = outline
      g.drawLine(0, th-1, w-1, th-1)

      tabBounds.add(Rect(tx,ty,tw,th))
      tx += tw
    }
  }

  Gradient gradient(Color c1, Color c2, Int h)
  {
    return Gradient.makeLinear(Point(0,0), c1, Point(0,h), c2)
  }

  Void pressed(Event event)
  {
    if (event.id == EventId.mouseDown && event.button == 1)
    {
      tab := tabBounds.eachBreak |Rect r, Int i->Obj| {
        return r.contains(event.pos.x, event.pos.y) ? i : null
      }
      if (tab != null) pane.select(pane.tabs[tab])
    }
  }

  ViewTabPane pane
  Rect[] tabBounds := Rect[,]

  const Int iconGap       := 5
  const Insets tabInsets  := Insets(5,10,5,5)
  const Font fontActive   := Font.sys.toBold
  const Font fontInactive := Font.sys
}


