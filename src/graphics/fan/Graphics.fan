//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

**
** Graphics is used to draw 2D graphics.
**
@Js
mixin Graphics
{

  ** Current paint defines how text and shapes are stroked and filled
  abstract Paint paint

  ** Convenience for setting paint to a solid color.  If the paint
  ** is currently not a solid color, then get returns `Paint.asColorPaint`.
  abstract Color color

  ** Current stroke defines how the shapes are outlined
  abstract Stroke stroke

  ** Global alpha value used to control opacity for rending.
  ** The value must be between 0.0 (transparent) and 1.0 (opaue).
  abstract Float alpha

  ** Current font used for drawing text
  abstract Font font

  ** Get font metrics for the current font
  abstract FontMetrics metrics()

  ** Begin a new path operation to stroke, fill, or clip a shape.
  abstract GraphicsPath path()

  ** Draw a line with the current stroke and paint.
  abstract This drawLine(Float x1, Float y1, Float x2, Float y2)

  ** Draw a rectangle with the current stroke and paint.
  abstract This drawRect(Float x, Float y, Float w, Float h)

  ** Fill a rectangle with the current paint.
  abstract This fillRect(Float x, Float y, Float w, Float h)

  ** Convenience to clip the given the rectangle.  This sets the
  ** clipping area to the intersection of the current clipping region
  ** and the specified rectangle.
  abstract This clipRect(Float x, Float y, Float w, Float h)

  ** Draw a rectangle with rounded corners with the current stroke and paint.
  ** The ellipse of the corners is specified by wArc and hArc.
  abstract This drawRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)

  ** Fill a rectangle with rounded corners with the current paint.
  ** The ellipse of the corners is specified by wArc and hArc.
  abstract This fillRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)

  ** Clip a rectangle with rounded corners with the current paint.
  ** The ellipse of the corners is specified by wArc and hArc.
  abstract This clipRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)

  ** Draw a the text string with the current paint and font.  The x, y
  ** coordinate specifies the left baseline corner of where the text
  ** is to be drawn.  Technically this is a fill operation similiar to
  ** the Canvas fillText function (there is currently no support to
  ** stroke/outline text).
  abstract This drawText(Str s, Float x, Float y)

  ** Draw an image at the given coordinate for the top/left corner.
  ** If the width or height does not correspond to the image's natural size
  ** then the image is scaled to fit.
  abstract This drawImage(Image img, Float x, Float y, Float w := img.w, Float h := img.h)

  ** Draw a rectangular region of the source image to the drawing surface.
  ** The src rectangle defines the subregion of the source image to use.  The
  ** dst rectangle identifies the destination location.  If the src size
  ** does not correspond to the dst size, then the image is scaled to fit.
  abstract This drawImageRegion(Image img, Rect src, Rect dst)

  ** Translate the coordinate system to the new origin.
  ** This call is a convenience for:
  **   transform(Transform.translate(x, y))
  abstract This translate(Float x, Float y)

  ** Perform an affine transformation on the coordinate system
  abstract This transform(Transform transform)

  ** Push the current graphics state onto an internal stack.  Reset the
  ** state back to its current state via `pop`.  If 'r' is non-null, the
  ** graphics state is automatically translated and clipped to the bounds.
  abstract This push(Rect? r := null)

  ** Pop the graphics stack and reset the state to the the last `push`.
  abstract This pop()

  ** Dispose of this graphics context and release underyling OS resources.
  abstract Void dispose()

}