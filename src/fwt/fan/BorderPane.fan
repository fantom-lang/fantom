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
    shade := 0.3f

    // background (doesn't support radius well yet)
    if (bg != null)
    {
      g.brush = bg
      g.fillRect(0, 0, w, h)
    }

    // left side
    if (border.widthLeft > 0)
    {
      g.pen = Pen { width = border.widthLeft }
      switch (border.styleLeft)
      {
        case Border.styleInset:  g.brush = border.colorLeft.darker(shade)
        case Border.styleOutset: g.brush = border.colorLeft.lighter(shade)
        default:                 g.brush = border.colorLeft
      }

      off := border.widthLeft / 2
      if (off <= 0) off = 1
      x := off

      g.drawLine(x, border.radiusTopLeft+off, x, h-border.radiusBottomLeft-off)
    }

    // right side
    if (border.widthRight > 0)
    {
      g.pen = Pen { width = border.widthRight }
      switch (border.styleRight)
      {
        case Border.styleInset:  g.brush = border.colorRight.lighter(shade)
        case Border.styleOutset: g.brush = border.colorRight.darker(shade)
        default:                 g.brush = border.colorRight
      }

      off := border.widthRight / 2
      if (off <= 0) off = 1
      x := w - off

      g.drawLine(x, border.radiusTopRight+off, x, h-border.radiusBottomRight-off)
    }

    // top side
    if (border.widthTop > 0)
    {
      g.pen = Pen { width = border.widthTop }
      switch (border.styleTop)
      {
        case Border.styleInset:  g.brush = border.colorTop.darker(shade)
        case Border.styleOutset: g.brush = border.colorTop.lighter(shade)
        default:                 g.brush = border.colorTop
      }

      off := border.widthTop / 2
      if (off <= 0) off = 1
      y := off

      g.drawLine(border.radiusTopLeft+off, y, w-border.radiusTopRight-off, y)

      // top-left corner
      if (border.radiusTopLeft > 0)
        g.drawArc(off, off, border.radiusTopLeft*2, border.radiusTopLeft*2, 90, 90)

      // top-right corner
      if (border.radiusTopRight > 0)
        g.drawArc(w-border.radiusTopRight*2-off, off, border.radiusTopRight*2, border.radiusTopRight*2, 0, 90)
    }

    // bottom side
    if (border.widthBottom > 0)
    {
      g.pen = Pen { width = border.widthBottom }
      switch (border.styleBottom)
      {
        case Border.styleInset:  g.brush = border.colorBottom.lighter(shade)
        case Border.styleOutset: g.brush = border.colorBottom.darker(shade)
        default:                 g.brush = border.colorBottom
      }

      off := border.widthBottom / 2
      if (off <= 0) off = 1
      y := h - off

      g.drawLine(border.radiusBottomLeft+off, y, w-border.radiusBottomRight-off, y)

      // bottom-left corner
      if (border.radiusBottomLeft > 0)
        g.drawArc(off, h-border.radiusBottomLeft*2-off, border.radiusBottomLeft*2, border.radiusBottomLeft*2, 180, 90)

      // bottom-right corner
      if (border.radiusBottomRight > 0)
        g.drawArc(w-border.radiusBottomRight*2-off, h-border.radiusBottomRight*2-off, border.radiusBottomRight*2, border.radiusBottomRight*2, 270, 90)
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
          bg = Color.yellow
          content = Button { text = "hello world" }
        }
      }
    }.open
  }

}

