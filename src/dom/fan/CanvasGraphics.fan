//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2022  Brian Frank  Creation
//

using graphics

**
** CanvasGraphics implements Graphics using HTML5 canvas.
**
@Js
internal native class CanvasGraphics : Graphics
{
  static Void render(Elem canvas, |Graphics| cb)

  override native Paint paint

  override native Color color

  override native Stroke stroke

  override native Float alpha

  override native Font font

  override native FontMetrics metrics()

  override native GraphicsPath path()

  override native This drawLine(Float x1, Float y1, Float x2, Float y2)

  override native This drawRect(Float x, Float y, Float w, Float h)

  override native This fillRect(Float x, Float y, Float w, Float h)

  override native This clipRect(Float x, Float y, Float w, Float h)

  override native This drawRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)

  override native This fillRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)

  override native This clipRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)

  override native This drawText(Str s, Float x, Float y)

  override native This drawImage(Image img, Float x, Float y, Float w := img.w, Float h := img.h)

  override native This drawImageRegion(Image img, Rect src, Rect dst)

  override This translate(Float x, Float y)

  override This transform(Transform transform)

  override native This push(Rect? r := null)

  override native This pop()

  override native Void dispose()
}

**************************************************************************
** CanvasGraphicsPath
**************************************************************************

@Js
internal native class CanvasGraphicsPath : GraphicsPath
{
  override native This draw()

  override native This fill()

  override native This clip()

  override native This moveTo(Float x, Float y)

  override native This lineTo(Float x, Float y)

  override native This arc(Float x, Float y, Float radius, Float start, Float sweep)

  override native This curveTo(Float cp1x, Float cp1y, Float cp2x, Float cp2y, Float x, Float y)

  override native This quadTo(Float cpx, Float cpy, Float x, Float y)

  override native This close()
}

**************************************************************************
** CanvasFontMetrics
**************************************************************************

@Js
internal native const class CanvasFontMetrics : FontMetrics
{
  override native Float height

  override native Float ascent

  override native Float descent

  override native Float leading

  override native Float width(Str s)
}

