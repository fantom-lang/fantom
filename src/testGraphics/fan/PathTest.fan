//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2022  Brian Frank  Creation
//

using graphics

@Js
class PathTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    // moveTo, curveTo, lineTo
    g.color = Color("#0a0")
    pathTurtle(g).fill
    g.color = Color("#7B3F00")
    g.stroke = Stroke(4f)
    pathTurtle(g).draw

    // quadTo
    g.color = Color("yellow")
    pathRoundRect(g, 200f, 40f, 200f, 100f, 15f, 25f).fill
    g.color = Color("blue")
    pathRoundRect(g, 200f, 40f, 200f, 100f, 15f, 25f).draw

    // circle
    g.color = Color("#93c5fd")
    g.fillEllipse(440f, 40f, 100f, 100f)
    g.color = Color("#1e40af")
    g.drawEllipse(440f, 40f, 100f, 100f)
    // oval
    g.color = Color("#93c5fd")
    g.fillEllipse(560f, 40f, 200f, 100f)
    g.color = Color("#1e40af")
    g.drawEllipse(560f, 40f, 200f, 100f)

    // quadTo
    cx := 100f
    cy := 250f
    r  := 45f
    pathArc(g, cx,      cy, r, 0f,   90f).draw
    pathArc(g, cx+100f, cy, r, 0f,  -90f).draw
    pathArc(g, cx+200f, cy, r, 90f,  45f).draw
    pathArc(g, cx+300f, cy, r, 135f, 90f).draw
    pathArc(g, cx+400f, cy, r, 180f, -45f).draw
    pathArc(g, cx+500f, cy, r, 270f, 45f).draw
  }

  static GraphicsPath pathTurtle(Graphics g)
  {
    g.path
     .moveTo(40f, 100f)
     .curveTo(50f, 30f, 110f, 30f, 120f, 100f)
     .curveTo(170f, 80f, 170f, 140f, 120f, 120f)
     .lineTo(110f, 120f)
     .curveTo(115f, 140f, 95f, 140f, 100f, 120f)
     .lineTo(60f, 120f)
     .curveTo(65f, 140f, 45f, 140f, 50f, 120f)
     .lineTo(40f, 120f)
     .close
  }

  static GraphicsPath pathRoundRect(Graphics g, Float x, Float y, Float w, Float h, Float wArc, Float hArc)
  {
    g.path
     .moveTo(x + wArc, y)
     .lineTo(x + w - wArc, y)
     .quadTo(x + w, y, x + w, y + hArc)
     .lineTo(x + w, y + h - hArc)
     .quadTo(x + w, y + h , x + w - wArc, y + h)
     .lineTo(x + wArc, y + h)
     .quadTo(x, y + h , x, y + h - hArc)
     .lineTo(x, y + hArc)
     .quadTo(x, y, x + wArc, y)
  }

  static GraphicsPath pathArc(Graphics g, Float cx, Float cy, Float r, Float start, Float sweep)
  {
    g.stroke = Stroke(1f)
    g.color = Color("gray")
    g.drawLine(cx, cy-r, cx, cy+r)
    g.drawLine(cx-r, cy, cx+r, cy)
    g.path.arc(cx, cy, r, 0f, 360f).draw

    g.font = Font("10pt Arial")
    text := "$start°, $sweep°"
    g.drawText(text, cx - g.metrics.width(text)/2f, cy+r*2f-g.metrics.height)

    g.stroke = Stroke(5f)
    g.color = Color("purple")
    return g.path.arc(cx, cy, r, start, sweep)
  }
}

