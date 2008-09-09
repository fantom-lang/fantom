//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jun 08  Brian Frank  Creation
//

//
// TODO:
//   - clipping
//   - pen stroking
//   - brush fills
//   - affine transformations
//   - anti-aliasing
//   - font metrics
//

**
** Graphics is used to draw to the screen or to an offscreen image.
**
class Graphics
{

  **
  ** Current brush defines how text and shapes are filled.
  **
  native Brush brush

  **
  ** Current pen defines how the shapes are stroked.
  **
  native Pen pen

  **
  ** Current font used for drawing text.
  **
  native Font font

  **
  ** Used to toggle anti-aliasing on and off.
  **
  native Bool antialias

  **
  ** Draw a pixel with the current brush.
  **
  native This drawPoint(Int x, Int y)

  **
  ** Draw a line with the current pen and brush.
  **
  native This drawLine(Int x1, Int y1, Int x2, Int y2)

  **
  ** Draw a rectangle with the current pen and brush.
  **
  native This drawRect(Int x, Int y, Int w, Int h)

  **
  ** Fill a rectangle with the current brush.
  **
  native This fillRect(Int x, Int y, Int w, Int h)

  **
  ** Draw an oval with the current pen and brush.  The
  ** oval is fit within the rectangle specified by x, y, w, h.
  **
  native This drawOval(Int x, Int y, Int w, Int h)

  **
  ** Fill an oval with the current brush.  The oval is
  ** fit within the rectangle specified by x, y, w, h.
  **
  native This fillOval(Int x, Int y, Int w, Int h)

  **
  ** Draw an arc with the current pen and brush.  The angles
  ** are measured in degrees with 0 degrees is 3 o'clock.
  ** The origin of the arc is centered within x, y, w, h.
  **
  native This drawArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)

  **
  ** Fill an arc with the current brush.  The angles are
  ** measured in degrees with 0 degrees is 3 o'clock.
  ** The origin of the arc is centered within x, y, w, h.
  **
  native This fillArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)

  **
  ** Draw a the text string with the current brush and font.
  ** The x, y coordinate specifies the top left corner of
  ** the rectangular area where the text is to be drawn.
  **
  native This drawText(Str s, Int x, Int y)

  **
  ** Draw a the image string with its top left corner at x,y.
  **
  native This drawImage(Image image, Int x, Int y)

  **
  ** Copy a rectangular region of the image to the graphics
  ** device.  If the source and destination don't have the
  ** same size, then the copy is resized.
  **
  native This copyImage(Image image, Rect src, Rect dest)

  **
  ** Translate the coordinate system to the new origin.
  **
  native This translate(Int x, Int y)

  **
  ** Current clipping rectangle.  Also see `clip`.
  **
  native Rect clipRect

  **
  ** Set the clipping area to the intersection of the
  ** current `clipRect` and the specified rectangle.
  **
  native This clip(Rect r)

  **
  ** Free any operating system resources used by this instance.
  **
  native Void dispose()

}