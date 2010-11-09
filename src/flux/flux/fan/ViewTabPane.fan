//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Sep 08  Andy Frank  Creation
//

using gfx
using fwt

**
** ViewTabPane manages ViewTabs.
**
internal class ViewTabPane : Pane
{

  **
  ** Construct with one default tab.
  **
  new make(Frame frame)
  {
    this.frame = frame
    this.tabs = [ ViewTab(frame) ]
    this.active = tabs[0]

    add(tbar = TabBar(this))
    add(active)
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
    tabs.map |ViewTab t->View| { t.view }
  }

  **
  ** Create a new tab.  The new tab is not selected.  It
  ** is up the caller to select it once loading is complete.
  **
  ViewTab newTab()
  {
    tab := ViewTab(frame)
    add(tab)
    tabs.add(tab)
    select(tab)
    return tab
  }

  **
  ** Close the specified view tab.
  **
  Void close(ViewTab tab)
  {
    if (!tab.confirmClose) return
    ViewTab? newActive := null
    if (tab === active)
    {
      i := tabs.index(tab)
      if (i == 0) newActive = tabs[1]
      else if (i == tabs.size-1) newActive = tabs[-2]
      else newActive = tabs[i+1]
    }
    remove(tab)
    tabs.remove(tab)
    if (newActive != null) select(newActive)
    else relayout
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
    oldActive.visible = false
    active.visible = true
    relayout
  }

  **
  ** Use pref size
  **
  override Size prefSize(Hints hints := Hints.defVal)
  {
    return Size(100, 100)
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

    active.bounds = Rect(0, th, size.w, size.h-th)
    active.relayout
  }

  private TabBar tbar

}

**************************************************************************
** TabBar
**************************************************************************
internal class TabBar : Canvas
{
  new make(ViewTabPane pane)
  {
    this.pane = pane
    onMouseDown.add { pressed(it) }
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    ph := tabInsets.top + 16.max(fontActive.height) + tabInsets.bottom
    return Size(100, ph)
  }

  const Gradient bgActive   := Gradient("0% 0%, 0% 100%, $Desktop.sysLightShadow, $Desktop.sysBg")
  const Gradient bgInactive := Gradient("0% 0%, 0% 100%, $Desktop.sysBg, $Desktop.sysNormShadow")

  override Void onPaint(Graphics g)
  {
    w  := size.w
    h  := size.h
    tx := 0

    outline := Desktop.sysNormShadow

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
      cw := iconClose.size.w
      tw := fontActive.width(text) + tabInsets.left + tabInsets.right + iw + iconGap + cw + iconGap
      th := prefSize.h
      ty := h - th
      ix := tx + tabInsets.left
      iy := (th - icon.size.h) / 2
      lx := ix + iw + iconGap
      ly := (th - font.height) / 2
      cx := tx + tw - tabInsets.right - cw
      cy := (th - iconClose.size.h) / 2

      g.brush = bg
      g.fillRect(tx, ty, tw, th)

      g.brush = outline
      g.drawLine(tx,    ty, tx,    th)
      g.drawLine(tx,    ty, tx+tw, ty)
      g.drawLine(tx+tw, ty, tx+tw, th)

      g.font = font
      g.brush = Desktop.sysFg
      g.drawImage(icon, ix, iy)
      g.drawText(text, lx, ly)
      g.drawImage(iconClose, cx, cy)

      g.brush = outline
      g.drawLine(0, th-1, w-1, th-1)

      tabBounds.add(Rect(tx,ty,tw,th))
      tx += tw
    }
  }

  Void pressed(Event event)
  {
    if (event.id == EventId.mouseDown && event.button == 1)
    {
      close := false
      Int? tab := tabBounds.eachWhile |Rect r, Int i->Int?|
      {
        if (r.contains(event.pos.x, event.pos.y))
        {
          if (event.pos.x > r.x + r.w - tabInsets.right - iconClose.size.w)
            close = true
          return i
        }
        return null
      }

      if (tab != null)
      {
        t := pane.tabs[tab]
        if (close) pane.close(t)
        else pane.select(t)
      }
    }
  }

  ViewTabPane pane
  Rect[] tabBounds := Rect[,]
  Image iconClose  := Flux.icon(`/x16/close.png`)

  const Int iconGap       := 3
  const Insets tabInsets  := Insets(5,5,5,5)
  const Font fontActive   := Desktop.sysFont.toBold
  const Font fontInactive := Desktop.sysFont
}