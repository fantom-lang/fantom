//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Sep 2016  Andy Frank  Creation
//

using concurrent
using dom

**
** Tooltip displays a small popup when the mouse hovers over the
** bound node element, and is dismissed when the mouse moves out.
**
** See also: [docDomkit]`docDomkit::Controls#tooltip`
**
@Js class Tooltip : Elem
{
  new make() : super()
  {
    this.style.addClass("domkit-Popup")
    this.style->zIndex = 2000
    // this.onEvent(EventType.mouseEnter, false) { inTooltip=true;  check }
    // this.onEvent("mouseleave", false) { inTooltip=false; check }
  }

  ** Time mouse must be over bound node before opening the
  ** Tooltip. If 'null' the Tooltip is displayed immediatly.
  Duration? delay := 750ms

  ** Bind this tooltip the given node.
  Void bind(Elem node)
  {
    if (this.node != null) throw ArgErr("Tooltip already bound to $this.node")
    this.node = node
    node.onEvent("mouseenter", false) { inNode=true;  check }
    node.onEvent("mouseleave", false) { inNode=false; check }
  }

  ** Check if tooltip should be opened or closed.
  private Void check()
  {
    if (inNode) // || inTooltip)
    {
      // open
      if (delay == null)
      {
        if (isOpen) return
        open
      }
      else
      {
        if (isOpen) return
        if (timerId != null) return
        timerId = Win.cur.setTimeout(delay) { this.open }
      }
    }
    else
    {
      // close
      if (isOpen) { close; return }
      if (timerId != null) { Win.cur.clearTimeout(timerId); timerId=null }
    }
  }

  ** Is Tooltip open.
  private Bool isOpen() { parent != null }

  ** Open tooltip over bound parent node.
  private Void open()
  {
    this.timerId = null

    x := node.pagePos.x
    y := node.pagePos.y + node.size.h + 1

    this.style->left = "${x}px"
    this.style->top  = "${y}px"
    this.style->opacity = "0"

    Win.cur.doc.body.add(this)

    // adjust if outside viewport
    sz := this.size
    vp := Win.cur.viewport
    if (sz.w + gutter + gutter > vp.w) this.style->width  = "${vp.w-gutter-gutter}px"
    if (sz.h + gutter + gutter > vp.h) this.style->height = "${vp.h-gutter-gutter}px"

    // refresh size
    sz = this.size
    if ((x + sz.w + gutter) > vp.w) this.style->left = "${vp.w-sz.w-gutter}px"
    if ((y + sz.h + gutter) > vp.h) this.style->top  = "${vp.h-sz.h-gutter}px"

    this.transition(["opacity": "1"], null, 100ms)
  }

  ** Close this tooltip.
  private Void close()
  {
    this.transition(["opacity":"0"], null, 100ms) {
      this.parent?.remove(this)
    }
  }

  private static const Int gutter := 12

  private Elem? node                // parent elem
  private Int? timerId              // open delay timer
  private Bool inNode    := false   // is mouse inside parent node
  private Bool inTooltip := false   // is mouse inside tooltip
}