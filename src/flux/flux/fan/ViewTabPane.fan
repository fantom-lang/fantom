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
    this.content = this.pane = TabPane() // TODO
    {
      this.active
      onSelect.add(&onSelect)
    }
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
    pane.add(tab) // TODO
    return tab
  }

  **
  ** Select the specified view tab as the new active tab.
  **
  Void select(ViewTab tab)
  {
    pane.selected = tab // TODO
    onSelect(Event { data=tab })
  }

  **
  ** Handle new tab selection
  **
  Void onSelect(Event event)
  {
    oldActive := this.active
    this.active = pane.selected
    if (active === oldActive) return
    oldActive.deactivate
    active.activate
  }

  TabPane pane // TODO


/* TODO: custom painting/layout code
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
*/

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


