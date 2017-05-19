//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 2016  Andy Frank  Creation
//

using concurrent
using dom

**
** Sheet
**
// TODO FIXIT: combine Popup + Dialog + Sheet (and add modal/non-modal support)
@NoDoc @Js class Sheet : Box
{
  new make() : super()
  {
    this.uid = nextId.val
    nextId.val = uid+1
    this->tabIndex = 0
    this.style.addClass("domkit-Sheet")
    this.onEvent("mousedown", false) |e| { e.stop; if (canDismiss) close }
  }

  ** Can this sheet be dismissed by clicking anywhere in the window?
  Bool canDismiss := false

  ** Return 'true' if this sheet currently open.
  Bool isOpen { private set }

  ** Optional delay for open animation.
  @NoDoc Duration? delay := null

  ** Open this sheet over given element. If sheet
  ** is already open this method does nothing.
  This open(Elem parent, Str height)
  {
    if (isOpen) return this

    ppos := parent.pagePos
    this.style.setAll([
      "left": "${ppos.x}px",
      "top":  "${ppos.y}px",
      "width": "${parent.size.w}px",
      "height": "0px"
    ])

    body := Win.cur.doc.body
    body.add(Elem {
      it.id = "domkitSheet-mask-$uid"
      it.style.addClass("domkit-Sheet-mask")
      if (canDismiss)
      {
        it.onEvent("keydown",   false) |e| { e.stop; close }
        it.onEvent("mousedown", false) |e| { e.stop; close }
      }
      it.add(this)
    })

    opts := delay == null ? null : ["transition-delay":delay]
    this.transition(["height": height], opts, 250ms) { this.focus; fireOpen(null) }
    return this
  }

  ** Close this sheet. If sheet is already closed this method does
  ** nothing. This method takes an `onClose` callback as a convenience
  ** to set and close in a single operation.
  Void close(|This|? f := null)
  {
    if (f != null) cbClose = f
    this.transition(["height": "0"], null, 250ms)
    {
      mask   := Win.cur.doc.elemById("domkitSheet-mask-$uid")
      parent := mask?.parent
      if (parent != null)
      {
        parent.remove(mask)
        parent.querySelector("input")?.focus  // <-- TODO FIXIT
      }
      fireClose(null)
    }
  }

  ** Callback when sheet is opened.
  Void onOpen(|This| f) { cbOpen = f }

  ** Callback when sheet is closed.
  Void onClose(|This| f) { cbClose = f }

  private Void fireOpen(Event? e)  { cbOpen?.call(this);  isOpen=true  }
  private Void fireClose(Event? e) { cbClose?.call(this); isOpen=false }

  private const Int uid
  private static const AtomicRef nextId := AtomicRef(0)

  private Func? cbOpen
  private Func? cbClose
}