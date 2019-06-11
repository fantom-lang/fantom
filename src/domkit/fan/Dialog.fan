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
** See also: [docDomkit]`docDomkit::Modals#dialog`
**
@Js class Dialog : Box
{
  new make() : super()
  {
    this.uid = nextId.val
    nextId.val = uid+1
    this.style.addClass("domkit-Dialog")
    this->tabIndex = 0
  }

  ** 'Str' or 'Elem' content displayed in title bar, or
  ** 'null' to hide title bar.
  Obj? title := null

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
      it->tabIndex = 0
      it.style.addClass("domkit-Dialog-mask")
      it.style->opacity = "0"
      it.onEvent("keydown", false) |e| { cbKeyDown?.call(e) }
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
    {
      telem := title as Elem ?:
        Label { it.style.addClass("def-label"); it.text=title.toStr }

      frame.add(Elem {
        it.style.addClass("domkit-Dialog-title")
        it.add(telem)
        it.onEvent("mousedown", false) |e| {
          e.stop
          vp  := Win.cur.viewport
          doc := Win.cur.doc
          off := doc.body.relPos(e.pagePos)
          fps := frame.pos
          fsz := frame.size
          Obj? fmove
          Obj? fup

          fmove = doc.onEvent("mousemove", true) |de| {
            pos := doc.body.relPos(de.pagePos)
            fx  := (pos.x.toInt - (off.x.toInt - fps.x.toInt)).max(0).min(vp.w.toInt - fsz.w.toInt)
            fy  := (pos.y.toInt - (off.y.toInt - fps.y.toInt)).max(0).min(vp.h.toInt - fsz.h.toInt)
            mask.style->display = "block"
            frame.style->position = "absolute"
            frame.style->left = "${fx}px"
            frame.style->top  = "${fy}px"
          }

          fup = doc.onEvent("mouseup", true) |de| {
            de.stop
            doc.removeEvent("mousemove", true, fmove)
            doc.removeEvent("mouseup",   true, fup)
          }
        }
      })
    }

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
    mask := Win.cur.doc.elemById("domkitDialog-mask-$uid")
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