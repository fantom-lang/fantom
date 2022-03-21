//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2022  Brian Frank  Creation
//

using graphics

@Js
class StrokeTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    g.font = Font("10pt Arial")

    x := 40f
    y := 20f

    paintDash(g, "1,1", x, y); y += 25f
    paintDash(g, "4,1", x, y); y += 25f
    paintDash(g, "8,2", x, y); y += 25f
    paintDash(g, "1,3", x, y); y += 25f
    paintDash(g, "3,8", x, y); y += 25f

    y += 25f
    paintCap(g, StrokeCap.butt,   x, y); y += 40f
    paintCap(g, StrokeCap.round,  x, y); y += 40f
    paintCap(g, StrokeCap.square, x, y); y += 40f

    y += 25f
    paintJoin(g, StrokeJoin.miter,  x, y); y += 100f
    paintJoin(g, StrokeJoin.radius, x, y); y += 100f
    paintJoin(g, StrokeJoin.bevel,  x, y); y += 100f
  }

  Void paintDash(Graphics g, Str dash, Float x, Float y)
  {
    g.color = Color.black
    g.drawText(dash, x, y+4f)

    g.color = Color("blue")
    g.stroke = Stroke("[$dash]")
    g.drawLine(x+60f, y, x+200f, y)
  }

  Void paintCap(Graphics g, StrokeCap cap, Float x, Float y)
  {
    g.color = Color.black
    g.drawText(cap.name, x, y+4f)

    g.color = Color("blue")
    g.stroke = Stroke("20 $cap")
    g.drawLine(x+60f, y, x+200f, y)
    g.color = Color("#ccc")
    g.stroke = Stroke(1f)
    g.drawLine(x+60f, y, x+200f, y)
  }

  Void paintJoin(Graphics g, StrokeJoin join, Float x, Float y)
  {
    g.color = Color.black
    g.drawText(join.name, x, y+40f)

    g.color = Color("blue")
    g.stroke = Stroke("20 $join")
    g.path
     .moveTo(x+60f, y+80f)
     .lineTo(x+130f, y)
     .lineTo(x+200f, y+80f)
     .draw
    g.stroke = Stroke(1f)
    g.color = Color("#ccc")
    g.path
     .moveTo(x+60f, y+80f)
     .lineTo(x+130f, y)
     .lineTo(x+200f, y+80f)
     .draw
  }

}

