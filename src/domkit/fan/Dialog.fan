//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 2014  Andy Frank  Creation
//

using concurrent
using dom

**
** Dialog manages a modal window above page content.
**
@Js class Dialog : Box
{
  new make() : super()
  {
    this.uid = nextId.val
    nextId.val = uid+1
    this.set("tabindex", "0")
    this.style.addClass("domkit-Dialog")
  }

  ** Text displayed in title bar, or empty Str to hide title bar.
  Str? title := null

  ** Protected sub-class callback invoked directly before dialog is opened.
  protected virtual Void onBeforeOpen() {}

  ** Callback when a key is pressed while Dialog is open, including
  ** events that where dispatched outside the dialog.
  protected Void onKeyDown(|Event e| f) { this.cbKeyDown = f }

  ** Open this dialog in the current Window. If dialog
  ** is already open this method does nothing.
  Void open()
  {
    onBeforeOpen

    mask := Elem {
      it.id = "domkitDialog-mask-$uid"
      it->tabindex = 0
      it.style.addClass("domkit-Dialog-mask")
      it.style->opacity = "0"
      it.onEvent(EventType.keyDown, false) |e| { cbKeyDown?.call(e) }
    }

    this.frame = Elem
    {
      it.style.addClass("domkit-Dialog-frame")
      it.style.setAll([
        "transform": "scale(0.75)",
        "opacity": "0.0"
      ])
    }

    if (title != null)
      frame.add(Elem {
        it.style.addClass("domkit-Dialog-title")
        it.text = title
        it.onEvent(EventType.mouseDown, false) |e| {
          e.stop
          vp  := Win.cur.viewport
          doc := Win.cur.doc
          off := e.pagePos.rel(doc.body)
          fps := frame.pos
          fsz := frame.size
          Obj? fmove
          Obj? fup

          fmove = doc.onEvent(EventType.mouseMove, true) |de| {
            pos := de.pagePos.rel(doc.body)
            fx  := (pos.x - (off.x - fps.x)).max(0).min(vp.w - fsz.w)
            fy  := (pos.y - (off.y - fps.y)).max(0).min(vp.h - fsz.h)
            mask.style->display = "block"
            frame.style->position = "absolute"
            frame.style->left = "${fx}px"
            frame.style->top  = "${fy}px"
          }

          fup = doc.onEvent(EventType.mouseUp, true) |de| {
            de.stop
            doc.removeEvent(EventType.mouseMove, true, fmove)
            doc.removeEvent(EventType.mouseUp,   true, fup)
          }
        }
      })

    frame.add(this)
    mask.add(frame)

    body := Win.cur.doc.body
    body.add(mask)

    mask.transition(["opacity":"1"], null, 100ms)
    frame.transition([
      "transform": "scale(1)",
      "opacity": "1"
    ], null, 100ms) { this.focus; fireOpen }
  }

  ** Close this dialog. If dialog is already closed
  ** this method does nothing.
  Void close()
  {
    mask := Win.cur.doc.elem("domkitDialog-mask-$uid")
    mask?.transition(["opacity":"0"], null, 100ms)
    frame?.transition(["transform": "scale(0.75)", "opacity": "0"], null, 100ms)
    {
      mask?.parent?.remove(mask)
      fireClose
    }
  }

  ** Callback when dialog is opened.
  Void onOpen(|This| f) { cbOpen = f }

  ** Callback when popup is closed.
  Void onClose(|This| f) { cbClose = f }

  private Void fireOpen()    { cbOpen?.call(this)    }
  private Void fireClose()   { cbClose?.call(this)   }

  private const Int uid
  private static const AtomicRef nextId := AtomicRef(0)

  private Elem? frame     := null
  private Func? cbOpen    := null
  private Func? cbClose   := null
  private Func? cbKeyDown := null
}