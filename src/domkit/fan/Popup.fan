//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Feb 2015  Andy Frank  Creation
//

using concurrent
using dom

**
** Popup window which can be closed clicking outside of element.
**
** See also: [pod doc]`pod-doc#popup`
**
@Js class Popup : Elem
{
  new make() : super()
  {
    this.uid = nextId.val
    nextId.val = uid+1
    this.style.addClass("domkit-Popup")
    this.onEvent("keydown", false) |e| { if (e.key == Key.esc) close }
  }

  ** Where to align Popup relative to open(x,y):
  **  - Align.left: align left edge popup to (x,y)
  **  - Align.center: center popup with (x,y)
  **  - Align.right: align right edge of popup to (x,y)
  Align halign := Align.left

  ** Return 'true' if this popup currently open.
  Bool isOpen { private set }

  ** Open this popup in the current Window. If popup
  ** is already open this method does nothing.
  Void open(Int x, Int y)
  {
    this.style.setAll([
      "left": "${x}px",
      "top":  "${y}px",
      "-webkit-transform": "scale(1)",
      "opacity": "0.0"
    ])

    body := Win.cur.doc.body
    body.add(Elem {
      it.id = "domkitPopup-mask-$uid"
      it.style.addClass("domkit-Popup-mask")
      it.onEvent("mousedown", false) |e| {
        if (e.target == this || this.containsChild(e.target)) return
        close
      }
      it.add(this)
    })

    // shift halign if needed
    sz := this.size
    switch (halign)
    {
      case Align.center: x -= sz.w / 2; this.style["left"] = "${x}px"
      case Align.right:  x -= sz.w;     this.style["left"] = "${x}px"
    }

    // adjust if outside viewport
    vp := Win.cur.viewport
    if (sz.w + gutter + gutter > vp.w) this.style["width"]  = "${vp.w-gutter-gutter}px"
    if (sz.h + gutter + gutter > vp.h) this.style["height"] = "${vp.h-gutter-gutter}px"

    // refresh size
    sz = this.size
    if ((x + sz.w + gutter) > vp.w) this.style["left"] = "${vp.w-sz.w-gutter}px"
    if ((y + sz.h + gutter) > vp.h) this.style["top"]  = "${vp.h-sz.h-gutter}px"

    this.transition([
      "opacity": "1"
    ], null, 100ms) { fireOpen(null) }
  }

  ** Close this popup. If popup is already closed
  ** this method does nothing.
  Void close()
  {
    this.transition(["transform": "scale(0.75)", "opacity": "0"], null, 100ms)
    {
      mask := Win.cur.doc.elem("domkitPopup-mask-$uid")
      mask?.parent?.remove(mask)
      fireClose(null)
    }
  }

  ** Callback when popup is opened.
  Void onOpen(|This| f) { cbOpen = f }

  ** Callback when popup is closed.
  Void onClose(|This| f) { cbClose = f }

  private Void fireOpen(Event? e)  { cbOpen?.call(this);  isOpen=true  }
  private Void fireClose(Event? e) { cbClose?.call(this); isOpen=false }

  private const Int uid
  private static const AtomicRef nextId := AtomicRef(0)
  private static const Int gutter := 12
  private Func? cbOpen
  private Func? cbClose
}