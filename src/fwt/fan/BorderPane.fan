//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 08  Andy Frank   Creation
//   10 Aug 09  Brian Frank  Refactor to use gfx::Border
//

using gfx

**
** BorderPane is used paint a CSS styled border around a content widget.
**
class BorderPane : Pane
{
// TODO: this will be replaced with a declarative CSS Border
|Graphics g, Size size, Insets insets|? onBorder := null

  **
  ** Border to paint around the edge of the content.
  ** Default is zero pixels.
  **
  Border border := Border("0")

  **
  ** Background to paint under content, or null for transparent.
  ** The background does not include the border itself, but
  ** does include the insets and content.  Default is null.
  **
  Brush? bg := null

  **
  ** Insets to leave between border and the content.
  ** Default is zero pixels.
  **
  Insets insets := Insets(0,0,0,0)

  **
  ** The content child widget.
  **
  Widget? content { set { remove(*content); Widget.super.add(val); *content = val } }

  **
  ** If this the first widget added, then assume it the content.
  **
  override This add(Widget? child)
  {
    if (*content == null) *content=child
    super.add(child)
    return this
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    if (content == null) return Size.defVal
    edgew := border.widthLeft + insets.left + insets.right  + border.widthRight
    edgeh := border.widthTop  + insets.top  + insets.bottom + border.widthBottom
    edge  := Size(edgew, edgeh)
    pref  := content.prefSize(hints - edge)
    return Size(pref.w + edgew, pref.h + edgeh)
  }

  override Void onLayout()
  {
    if (content == null) return
    size := this.size
    content.bounds = Rect(
      border.widthLeft + insets.left,
      border.widthTop + insets.top,
      size.w - border.widthLeft - insets.left - insets.right  - border.widthRight,
      size.h - border.widthTop  - insets.top  - insets.bottom - border.widthBottom)
  }

  internal Void onPaint(Graphics g)
  {
if (onBorder != null) { onBorder?.call(g, size, insets); return }
    w := size.w
    h := size.h

    if (border.widthLeft > 0)
    {
      g.pen   = Pen { width = border.widthLeft }
      g.brush = border.colorLeft
      x := border.widthLeft / 2
      g.drawLine(x, 0, x, h)
    }

    if (border.widthRight > 0)
    {
      g.pen   = Pen { width = border.widthRight }
      g.brush = border.colorRight
      x := w - border.widthRight / 2
      if (x >= w) --x
      g.drawLine(x, 0, x, h)
    }

    if (border.widthTop > 0)
    {
      g.pen   = Pen { width = border.widthTop }
      g.brush = border.colorTop
      y := border.widthTop / 2
      g.drawLine(0, y, w, y)
    }

    if (border.widthBottom > 0)
    {
      g.pen   = Pen { width = border.widthBottom }
      g.brush = border.colorBottom
      y := h - border.widthBottom / 2
      if (y >= h) --y
      g.drawLine(0, y, w, y)
    }
  }

  // to force native peer
  private native Void dummyBorderPane()


  static Void main(Str[] args)
  {
    i := Insets(args[0])
    b := Border(args[1])
    echo("Insets: $i")
    echo("Border: $b")
    Window
    {
      size = Size(300,200)
      content = InsetPane
      {
        content = BorderPane
        {
          insets = i
          border = b
          content = Button { text = "hello world" }
        }
      }
    }.open
  }

}

