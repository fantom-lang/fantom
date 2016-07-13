//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 2014  Andy Frank  Creation
//

using dom

**
** Button is a widget that invokes an action when pressed.
**
** See also: [pod doc]`pod-doc#button`, `ToggleButton`, `ListButton`
**
@Js class Button : Elem
{
  new make() : super()
  {
    this.style.addClass("domkit-Button")
    this.set("tabindex", "0")
    this.onEvent(EventType.mouseDown, false) |e|
    {
      e.stop
      if (!enabled) return
      mouseDown = true
      doMouseDown
    }
    this.onEvent(EventType.mouseUp, false) |e|
    {
      if (!enabled) return
      doMouseUp
      if (mouseDown)
      {
        fireAction(e)
        if (cbPopup != null) openPopup
      }
      mouseDown = false
    }
    this.onEvent(EventType.mouseLeave, false) |e|
    {
      if (!mouseDown) return
      doMouseUp
      mouseDown = false
    }
    this.onEvent(EventType.keyDown, false) |e|
    {
      if (!enabled) return
      if (e.key == Key.space)
      {
        doMouseDown
        if (cbPopup == null) Win.cur.setTimeout(100ms) |->| { fireAction(e); doMouseUp }
        else
        {
          if (popup?.isOpen == true) popup.close
          else openPopup
        }
      }
    }
  }

  ** Callback when button action is invoked.
  Void onAction(|This| f) { this.cbAction = f }

  ** Callback to create Popup to display when button is pressed.
  Void onPopup(|Button->Popup| f) { this.cbPopup = f }

// TODO: how should this work?
// TODO: something like onLazyPopup work better?
  ** Remove existing popup callback.
  @NoDoc Void removeOnPopup() { this.cbPopup = null }

  ** Programmatically open popup, or do nothing if no popup defined.
  Void openPopup()
  {
    if (cbPopup == null) return
    if (popup?.isOpen == true) return

    x := pagePos.x
    y := pagePos.y + size.h
    w := size.w

    if (isCombo)
    {
      // stretch popup to fit combo
      combo := this.parent
      x = combo.pagePos.x
      w = combo.size.w
    }

    // shift to align text
    if (isList) x -= 12

    showDown
    popup = cbPopup(this)

    // adjust popup origin if haligned
    switch (popup.halign)
    {
      case Align.center: x += w / 2
      case Align.right:  x += w
    }

    popup.onClose
    {
      showUp
      if (isCombo) ((Combo)this.parent).field.focus
    }
    popup.style["min-width"] = "${w}px"
    popup.open(x, y)
  }

  override Bool? enabled
  {
    get { !style.hasClass("disabled") }
    set
    {
      if (it)
      {
        style.removeClass("disabled")
        this.set("tabindex", "0")
      }
      else
      {
        style.addClass("disabled")
        this.set("tabindex", "-1")
      }
    }
  }

  // internal use only
  internal Bool isCombo := false
  internal Bool isList  := false

  internal Void showDown() { style.addClass("down") }
  internal Void showUp()   { style.removeClass("down") }
  internal virtual Void doMouseDown() { showDown }
  internal virtual Void doMouseUp()   { showUp }
  internal Bool mouseDown := false

  private Void fireAction(Event e) { cbAction?.call(this) }

  private Popup? popup   := null
  private Func? cbAction := null
  private Func? cbPopup  := null
}