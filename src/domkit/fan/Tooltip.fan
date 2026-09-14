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
** See also: [docDomkit](docDomkit::Controls#tooltip)
**
@Js class Tooltip : Elem
{
  new make() : super()
  {
    this.style.addClass("domkit-Popup")
    this.style->zIndex = 2000
  }

  ** Time mouse must be over bound node before opening the
  ** Tooltip. If `null` the Tooltip is displayed immediatly.
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
    if (inNode)
    {
      if (isOpen || timerId != null) return
      if (delay == null) open
      else timerId = Win.cur.setTimeout(delay) { this.timerId=null; this.open }
    }
    else
    {
      if (timerId != null) { Win.cur.clearTimeout(timerId); timerId=null }
      if (isOpen) close
    }
  }

  ** Is Tooltip open.
  private Bool isOpen() { parent != null }

  ** Is bound node still mounted in the document.
  private Bool mounted() { Win.cur.doc.body.containsChild(node) }

  ** Open tooltip over bound parent node.
  private Void open()
  {
    // an unmounted node never fires mouseleave, which would orphan
    // the tooltip forever; likewise never open if mouse already left
    if (isOpen || !inNode || !mounted) return

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

    // failsafe: close if node unmounted while open
    watchId = Win.cur.setInterval(500ms) { if (!this.mounted) { this.inNode=false; this.close } }
  }

  ** Close this tooltip.
  @NoDoc Void close()
  {
    if (watchId != null) { Win.cur.clearInterval(watchId); watchId=null }
    this.transition(["opacity":"0"], null, 100ms) { this.parent?.remove(this) }
  }

  private static const Int gutter := 12

  private Elem? node             // parent elem
  private Int? timerId           // open delay timer
  private Int? watchId           // open watchdog interval
  private Bool inNode := false   // is mouse inside parent node
}
