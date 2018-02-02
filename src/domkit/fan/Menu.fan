//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 May 2015  Andy Frank  Creation
//

using dom
using graphics

**
** Popup menu
**
** See also: [docDomkit]`docDomkit::Controls#menu`, `MenuItem`
**
@Js class Menu : Popup
{
  new make() : super()
  {
    this->tabIndex = 0
    this.style.addClass("domkit-Menu")
    this.onOpen { this.focus }
    this.onEvent("mouseleave", false) { select(null) }
    this.onEvent("mouseover", false) |e|
    {
      // keyboard scrolling generates move/over events we need to filter out
      if (lastEvent > 0) { lastEvent=0; return }

      // bubble to MenuItem
      Elem? t := e.target
      while (t != null && t isnot MenuItem) t = t?.parent
      if (t == null) { select(null); return }

      // check for selection
      index := children.findIndex |k| { t == k }
      if (index != null)
      {
        MenuItem item := children[index]
        select(item.enabled ? index : null)
      }
      lastEvent = 0
    }
    this.onEvent("mousedown", false) |e| { armed=true }
    this.onEvent("mouseup",   false) |e| { if (armed) fireAction(e) }
    this.onEvent("keydown", false) |e|
    {
      switch (e.key)
      {
        case Key.esc:   close
        case Key.up:    e.stop; lastEvent=1; select(selIndex==null ? findFirst : findPrev(selIndex))
        case Key.down:  e.stop; lastEvent=1; select(selIndex==null ? findFirst : findNext(selIndex))
        case Key.space: // fall-thru
        case Key.enter: e.stop; fireAction(e)
        default:
          if (onCustomKeyDown != null)
          {
            e.stop
            lastEvent = 1
            onCustomKeyDown.call(e)
          }
      }
    }
  }

  protected override Void onBeforeOpen()
  {
    // reselect to force selected item to scroll into view
    if (selIndex != null) select(selIndex)
  }

  // TEMP TODO FIXIT: ListButton.makeLisbox
  //private Void select(Int? index)
  @NoDoc Void select(Int? index)
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

    if (sy > iy) this.scrollPos = Point(0f, iy)
    else if (sy + mh < iy + ih) this.scrollPos = Point(0f, (iy + ih - mh))
  }

  private Int? findFirst()
  {
    i := 0
    kids := children
    while (i++ < kids.size-1)
    {
      item := kids[i] as MenuItem
      if (item != null && item.enabled) return i
    }
    return null
  }

  private Int? findPrev(Int start)
  {
    i := start
    kids := children
    while (--i >= 0)
    {
      item := kids[i] as MenuItem
      if (item != null && item.enabled) return i
    }
    return start
  }

  private Int? findNext(Int start)
  {
    i := start
    kids := children
    while (++i < kids.size)
    {
      item := kids[i] as MenuItem
      if (item != null && item.enabled) return i
    }
    return start
  }

  private Void fireAction(Event e)
  {
    if (selIndex == null) return
    MenuItem item := children[selIndex]
    item.fireAction(e)
  }

  // internal use only
  internal Func? onCustomKeyDown := null

  private Int? selIndex
  private Int lastEvent := 0   // 0=mouse, 1=key
  private Bool armed := false  // don't fire mouseUp unless we first detect a mouse down
}

**
** MenuItem for a `Menu`
**
@Js class MenuItem : Elem
{
  new make() : super()
  {
    this.style.addClass("domkit-control domkit-MenuItem")
  }

  override Bool? enabled
  {
    get { !style.hasClass("disabled") }
    set { style.toggleClass("disabled", !it) }
  }

  ** Callback when item is selected.
  Void onAction(|This| f) { this.cbAction = f }

  internal Void fireAction(Event e)
  {
    if (!enabled) return
    _event = e
    (parent as Popup)?.close
    cbAction?.call(this)
  }

  // TODO: not sure how this works yet
  @NoDoc Event? _event

  private Func? cbAction := null
}