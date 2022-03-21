//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Brian Frank  Creation
//

using graphics

@Js
class TransformTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    g.push
    g.translate(20f, 20f)
    paintStuff(g, "No Transform")
    g.pop

    g.push
    g.translate(250f, 0f)
    g.transform(Transform.rotate(45f))
    paintStuff(g, "Rotate 45°")
    g.pop

    g.push
    g.translate(20f, 220f)
    g.transform(Transform.scale(2f, 1f))
    paintStuff(g, "Scale-X x2")
    g.pop

    g.push
    g.translate(300f, 220f)
    g.transform(Transform.scale(1f, 2f))
    paintStuff(g, "Scale-Y x2")
    g.pop

    g.push
    g.translate(20f, 500f)
    g.transform(Transform.skewX(45f))
    paintStuff(g, "Skew-X 45°")
    g.pop

    g.push
    g.translate(300f, 500f)
    g.transform(Transform.skewY(45f))
    paintStuff(g, "Skew-Y 45°")
    g.pop
  }

  Void paintStuff(Graphics g, Str title)
  {
    g.color = Color("green")
    g.stroke = Stroke(3f)
    g.path.moveTo(50f, 0f)
          .lineTo(100f, 50f)
          .lineTo(100f, 100f)
          .lineTo(0f, 100f)
          .lineTo(0f, 50f)
          .close
          .draw
    g.color = Color("blue")
    g.font = Font("12pt Arial")
    g.drawText(title, 10f, 120f)
  }

}

