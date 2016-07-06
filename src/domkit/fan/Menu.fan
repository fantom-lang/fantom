//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 May 2015  Andy Frank  Creation
//

using dom

**
** Popup menu
**
@Js class Menu : Popup
{
  new make() : super()
  {
    this->tabIndex = 0
    this.style.addClass("domkit-Menu")
    this.onOpen { this.focus }
    this.onEvent(EventType.mouseLeave, false) { select(null) }
    this.onEvent(EventType.mouseOver, false) |e|
    {
      // keyboard scrolling generates move/over events we need to filter out
      if (lastEvent > 0) { lastEvent=0; return }

      // bubble to MenuItem
      Elem? t := e.target
      while (t != null && t isnot MenuItem) t = t?.parent
      if (t == null) return

      // check for selection
      index := children.findIndex |k| { t == k }
      if (index != null) select(index)
      lastEvent = 0
    }
    this.onEvent(EventType.mouseUp, false) |e| { fireAction }
    this.onEvent(EventType.keyDown, false) |e|
    {
      switch (e.key)
      {
        case Key.esc:   close
        case Key.up:    e.stop; lastEvent=1; select(selIndex==null ? 0 : selIndex-1)
        case Key.down:  e.stop; lastEvent=1; select(selIndex==null ? 0 : selIndex+1)
        case Key.space: // fall-thru
        case Key.enter: e.stop; fireAction
      }
    }
  }

  // TEMP TODO FIXIT: ListButton.makeLisbox
  //private Void select(Int? index)
  internal Void select(Int? index)
  {
    kids := children
    if (kids.size == 0) return

    // clear old selection
    if (selIndex != null) kids[selIndex].style.removeClass("domkit-sel")

    // clear all selection
    if (index == null)
    {
      selIndex = null
      return
    }

    // check bounds
    if (index < 0) index = 0
    if (index > kids.size-1) index = kids.size-1

    // new selection
    item := kids[index]
    item.style.addClass("domkit-sel")
    this.selIndex = index

    // scroll if needed
    sy := this.scrollPos.y
    mh := this.size.h
    iy := item.pos.y
    ih := item.size.h

    if (sy > iy) this.scrollPos = Pos(0, iy)
    else if (sy + mh < iy + ih) this.scrollPos = Pos(0, iy + ih - mh)
  }

  private Void fireAction()
  {
    if (selIndex == null) return
    MenuItem item := children[selIndex]
    item.fireAction
  }

  private Int? selIndex
  private Int lastEvent := 0  // 0=mouse, 1=key
}

**
** MenuItem for a `Menu`
**
@Js class MenuItem : Elem
{
  new make() : super()
  {
    this.style.addClass("domkit-MenuItem")
  }

  ** Callback when item is selected.
  Void onAction(|This| f) { this.cbAction = f }

  internal Void fireAction()
  {
    (parent as Popup)?.close
    cbAction?.call(this)
  }

  private Func? cbAction := null
}