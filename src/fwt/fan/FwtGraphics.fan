//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Aug 12  Brian Frank  Creation
//

using gfx

**
** Stub for native implementation of gfx::Graphics
**
@Js
internal native class FwtGraphics : Graphics
{
  override native Brush brush
  override native Pen pen
  override native Font font
  override native Bool antialias
  override native Int alpha
  override native GraphicsPath path()
  override native This drawLine(Int x1, Int y1, Int x2, Int y2)
  override native This drawPolyline(Point[] p)
  override native This drawPolygon(Point[] p)
  override native This fillPolygon(Point[] p)
  override native This drawRect(Int x, Int y, Int w, Int h)
  override native This fillRect(Int x, Int y, Int w, Int h)
  override native This drawRoundRect(Int x, Int y, Int w, Int h, Int wArc, Int hArc)
  override native This fillRoundRect(Int x, Int y, Int w, Int h, Int wArc, Int hArc)
  override native This drawOval(Int x, Int y, Int w, Int h)
  override native This fillOval(Int x, Int y, Int w, Int h)
  override native This drawArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)
  override native This fillArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)
  override native This drawText(Str s, Int x, Int y)
  override native This drawImage(Image image, Int x, Int y)
  override native This copyImage(Image image, Rect src, Rect dest)
  override native This translate(Int x, Int y)
  override native This clip(Rect r)
  override native Rect clipBounds()
  override native Void push()
  override native Void pop()
  override native Void dispose()
}