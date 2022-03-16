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

  ** Current fill defines how text and shapes are filled
  abstract Fill fill

  ** Current stroke defines how the shapes are outlined
  abstract Stroke stroke

  ** Current font used for drawing text
  abstract Font font

  ** Get font metrics for the given font
  abstract FontMetrics metrics(Font font := this.font)

  ** Draw a line with the current stroke.
  abstract This drawLine(Float x1, Float y1, Float x2, Float y2)

  ** Draw a rectangle with the current stroke.
  abstract This drawRect(Float x, Float y, Float w, Float h)

  ** Fill a rectangle with the current fill.
  abstract This fillRect(Float x, Float y, Float w, Float h)

  ** Draw a the text string with the current fill and font.
  ** The x, y coordinate specifies the left baseline corner of
  ** where the text is to be drawn.
  abstract This drawText(Str s, Float x, Float y)

  ** Push the current graphics state onto an internal stack.  Reset
  ** the state back to its current state via `pop`.
  abstract This push()

  ** Pop the graphics stack and reset the state to the the last `push`.
  abstract This pop()

}