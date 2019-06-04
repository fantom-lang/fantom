//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 2014  Andy Frank  Creation
//

using dom
using graphics

**
** Button is a widget that invokes an action when pressed.
**
** See also: [docDomkit]`docDomkit::Controls#button`,
** `ToggleButton`, `ListButton`
**
@Js class Button : Elem
{
  new make() : super()
  {
    this.style.addClass("domkit-control domkit-control-button domkit-Button")
    this->tabIndex = 0
    this.onEvent("mousedown", false) |e|
    {
      e.stop
      if (!enabled) return
      this._event = e
      mouseDown = true
      doMouseDown
    }
    this.onEvent("mouseup", false) |e|
    {
      if (!enabled) return
      this._event = e
      doMouseUp
      if (mouseDown)
      {
        fireAction(e)
        if (cbPopup != null) openPopup
      }
      mouseDown = false
    }
    this.onEvent("mouseleave", false) |e|
    {
      if (!mouseDown) return
      this._event = e
      doMouseUp
      mouseDown = false
    }
    this.onEvent("keydown", false) |e|
    {
      if (!enabled) return
      this._event = e
      if (e.key == Key.space || (this is ListButton && e.key == Key.down))
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

  ** Offset to apply to default origin for `onPopup`.
  @NoDoc Point popupOffset := Point.defVal

// TODO: how should this work?
// TODO: something like onLazyPopup work better?
  ** Remove existing popup callback.
  @NoDoc Void removeOnPopup() { this.cbPopup = null }

  ** Programmatically open popup, or do nothing if no popup defined.
  Void openPopup()
  {
    if (cbPopup == null) return
    if (popup?.isOpen == true) return

    x := pagePos.x + popupOffset.x
    y := pagePos.y + popupOffset.y + size.h.toInt
    w := size.w.toInt

    if (isCombo)
    {
      // stretch popup to fit combo
      combo := this.parent
      x = combo.pagePos.x
      w = combo.size.w.toInt
    }

    showDown
    popup = cbPopup(this)

    // adjust popup origin if haligned
    switch (popup.halign)
    {
      case Align.center: x += w / 2
      case Align.right:  x += w
    }

    // use internal _onClose to keep onClose available for use
    popup._onClose
    {
      showUp
      if (isCombo) ((Combo)this.parent).field.focus
      else this.focus
    }

    // limit width to button size if not explicity set
    if (popup.style.effective("min-width") == null)
      popup.style->minWidth = "${w}px"

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
        this->tabIndex = 0
      }
      else
      {
        style.addClass("disabled")
        this->tabIndex = -1
      }
    }
  }

  // internal use only
  internal Bool isCombo := false

  internal Void showDown() { style.addClass("down") }
  internal Void showUp()   { style.removeClass("down") }
  internal virtual Void doMouseDown() { showDown }
  internal virtual Void doMouseUp()   { showUp }
  internal Bool mouseDown := false

  private Void fireAction(Event e)
  {
    cbAction?.call(this)
  }

  // TODO: not sure how this works yet
  @NoDoc Event? _event

  private Popup? popup   := null
  private Func? cbAction := null
  private Func? cbPopup  := null
}