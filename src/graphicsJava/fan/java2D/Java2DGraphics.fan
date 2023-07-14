//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

using [java] java.lang::Float as JavaFloat
using [java] java.util::HashMap
using [java] java.awt::AlphaComposite
using [java] java.awt::BasicStroke
using [java] java.awt::Color as AwtColor
using [java] java.awt::Font as AwtFont
using [java] java.awt::Graphics2D
using [java] java.awt::RenderingHints
using [java] java.awt.geom::AffineTransform
using [java] java.awt.geom::Line2D$Double as Line2D
using [java] java.awt.geom::Rectangle2D$Double as Rect2D
using [java] java.awt.geom::RoundRectangle2D$Double as RoundRectangle2D
using [java] java.awt.font::TextAttribute
using [java] fanx.interop::FloatArray
using graphics

**
** Java2D graphics implementation
**
class Java2DGraphics : Graphics
{
  ** Constructor
  new make(Graphics2D g)
  {
    this.g = g
    g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY)
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
    g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_LCD_HRGB)
    this.paint = Color.black
  }

  ** Current paint defines how text and shapes are stroked and filled
  override Paint paint := Color.transparent // set in make
  {
    set
    {
      if (&paint == it) return
      &paint = it
      c := it.asColorPaint
      if (c.a < 1.0f)
        g.setColor(AwtColor(c.r, c.g, c.b, (255f * c.a).toInt))
      else
        g.setColor(AwtColor(c.r, c.g, c.b))
    }
  }

  ** Convenience for setting paint to a solid color.  If the paint
  ** is currently not a solid color, then get returns the last color set.
  override Color color
  {
    get { paint.asColorPaint }
    set { this.paint = it }
  }

  ** Current stroke defines how the shapes are outlined
  override Stroke stroke := Stroke.defVal
  {
    set
    {
      if (&stroke == it) return
      &stroke = it
      cap := toStrokeCap(it.cap)
      join := toStrokeJoin(it.join)
      dash := toStrokeDash(it.dash)
      g.setStroke(BasicStroke(it.width, cap, join, 10f, dash, 0f))
    }
  }

  private static Int toStrokeCap(StrokeCap cap)
  {
    if (cap === StrokeCap.round)  return BasicStroke.CAP_ROUND
    if (cap === StrokeCap.square) return BasicStroke.CAP_SQUARE
    return BasicStroke.CAP_BUTT
  }

  private static Int toStrokeJoin(StrokeJoin join)
  {
    if (join === StrokeJoin.radius) return BasicStroke.JOIN_ROUND
    if (join=== StrokeJoin.bevel)   return BasicStroke.JOIN_BEVEL
    return BasicStroke.JOIN_MITER
  }

  private static FloatArray? toStrokeDash(Str? dash)
  {
    if (dash == null) return null
    toks := GeomUtil.split(dash)
    if (toks.isEmpty) return null
    array := FloatArray.make(toks.size)
    toks.each |tok, i| { array[i] = tok.trim.toFloat }
    return array
  }

  ** Global alpha value used to control opacity for rending.
  ** The value must be between 0.0 (transparent) and 1.0 (opaue).
  override Float alpha := 1.0f
  {
    set
    {
      it = it.clamp(0f, 1f)
      if (&alpha == it) return
      &alpha = it
      if (it >= 1.0f)
        g.setComposite(AlphaComposite.SrcOver)
      else
        g.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, it))
    }
  }

  ** Current font used for drawing text
  override Font font := Font {}
  {
    set
    {
      if (&font === it) return
      &font = it
      g.setFont(env.awtFont(it))
    }
  }

  ** Get font metrics for current font
  override FontMetrics metrics()
  {
    Java2DFontMetrics(g.getFontMetrics)
  }

  ** Begin a new path operation to stroke, fill, or clip a shape.
  override GraphicsPath path()
  {
    Java2DGraphicsPath(g)
  }

  ** Draw a line with the current stroke.
  override This drawLine(Float x1, Float y1, Float x2, Float y2)
  {
    g.draw(Line2D(x1, y1, x2, y2))
    return this
  }

  ** Draw a rectangle with the current stroke.
  override This drawRect(Float x, Float y, Float w, Float h)
  {
    g.draw(Rect2D(x, y, w, h))
    return this
  }

  ** Fill a rectangle with the current fill.
  override This fillRect(Float x, Float y, Float w, Float h)
  {
    g.fill(Rect2D(x, y, w, h))
    return this
  }

  ** Convenience to clip the given the rectangle.  This sets the
  ** clipping area to the intersection of the current clipping region
  ** and the specified rectangle.
  override This clipRect(Float x, Float y, Float w, Float h)
  {
    g.clip(Rect2D(x, y, w, h))
    return this
  }

  ** Draw a rectangle with rounded corners with the current stroke and paint.
  ** The ellipse of the corners is specified by wArc and hArc.
  override This drawRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)
  {
    g.draw(RoundRectangle2D(x, y, w, h, wArc, hArc))
    return this
  }

  ** Fill a rectangle with rounded corners with the current paint.
  ** The ellipse of the corners is specified by wArc and hArc.
  override This fillRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)
  {
    g.fill(RoundRectangle2D(x, y, w, h, wArc, hArc))
    return this
  }

  ** Draw a the text string with the current fill and font.
  ** The x, y coordinate specifies the top left corner of
  ** the rectangular area where the text is to be drawn.
  override This drawText(Str s, Float x, Float y)
  {
    g.drawString(s, x, y)
    return this
  }

  ** Draw an image at the given coordinate for the top/left corner.
  ** If the width or height does not correspond to the image's natural size
  ** then the image is scaled to fit.  Also see `copyImage`.
  override This drawImage(Image img, Float x, Float y, Float w := img.w, Float h := img.h)
  {
    awt := ((Java2DImage)img).awt
    if (awt == null) return this

    g.drawImage(awt, x.toInt, y.toInt, w.toInt, h.toInt, null)
    return this
  }

  ** Copy a rectangular region of the source image to the drawing surface.
  ** The src rectangle defines the region of the soure image to copy.  The
  ** dst rectangle identifies the destination location.  If the src size
  ** does not correspond to the dst size, then the image is scaled to fit.
  ** Also see `drawImage`.
  override This drawImageRegion(Image img, Rect src, Rect dst)
  {
    awt := ((Java2DImage)img).awt
    if (awt == null) return this

    dx1 := dst.x.toInt
    dx2 := dx1 + dst.w.toInt
    dy1 := dst.y.toInt
    dy2 := dy1 + dst.h.toInt

    sx1 := src.x.toInt
    sx2 := sx1 + src.w.toInt
    sy1 := src.y.toInt
    sy2 := sy1 + src.h.toInt

    g.drawImage(awt, dx1, dy1, dx2, dy2, sx1, sy1, sx2, sy2, null)
    return this
  }

  ** Translate the coordinate system to the new origin
  override This translate(Float x, Float y)
  {
    g.translate(x, y)
    return this
  }

  ** Perform an affine transform on the coordinate system
  override This transform(Transform t)
  {
    g.transform(AffineTransform(t.a, t.b, t.c, t.d, t.e, t.f))
    return this
  }

  ** Push the current graphics state onto an internal stack.  Reset
  ** the state back to its current state via `pop`.  If 'r' is non-null
  ** the graphics state is automatically translated and clipped to the
  ** bounds.
  override This push(Rect? r := null)
  {
    stack.push(saveState)
    if (r == null)
      this.g = this.g.create
    else
      this.g = this.g.create(r.x.toInt, r.y.toInt, r.w.toInt, r.h.toInt)
    return this
  }

  ** Pop the graphics stack and reset the state to the the last `push`.
  override This pop()
  {
    if (stack.isEmpty) throw Err("Stack is empty")
    g.dispose
    restoreState(stack.pop)
    return this
  }

  ** Get current environemnt - lazily load
  private Java2DGraphicsEnv env()
  {
    if (envRef == null) return envRef = GraphicsEnv.cur
    return envRef
  }
  private Java2DGraphicsEnv? envRef

  private JavaGraphicsState saveState()
  {
    JavaGraphicsState
    {
      it.g      = this.g
      it.paint  = this.paint
      it.color  = this.color
      it.stroke = this.stroke
      it.alpha  = this.alpha
      it.font   = this.font
    }
  }

  private Void restoreState(JavaGraphicsState s)
  {
    this.g      = s.g
    this.paint  = s.paint
    this.color  = s.color
    this.stroke = s.stroke
    this.alpha  = s.alpha
    this.font   = s.font
  }

  ** Dispose of this graphics context and release underyling OS resources.
  override Void dispose()
  {
    g.dispose
  }

  private Graphics2D g
  private JavaGraphicsState[] stack := [,]
}

**************************************************************************
** JavaGrahicsState
**************************************************************************

internal class JavaGraphicsState
{
  Graphics2D? g
  Paint? paint
  Color? color
  Stroke? stroke
  Float alpha
  Font? font
}

