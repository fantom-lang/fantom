//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Brian Frank  Creation
//

using graphics

@Js
class AlphaTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    sq := 20f
    numx := (size.w / sq + 1f).toInt
    numy := (size.h / sq + 1f).toInt
    numx.times |x|
    {
      numy.times |y|
      {
        g.color = x.isOdd == y.isOdd ? Color("gray") : Color.white
        g.fillRect(x.toFloat*sq, y.toFloat*sq, sq, sq)
      }
    }

    // draw using colors with alpha

    g.color = Color("#0a09")
    PathTest.pathTurtle(g).fill
    g.color = Color("#7B3F0099")
    g.stroke = Stroke(4f)
    PathTest.pathTurtle(g).draw

    g.font = Font("48pt Times")
    g.color = Color("darkorange").opacity(0.7f)
    g.drawText("Alpha", 20f, 220f)

    // set global alpha

    g.alpha = 0.7f
    g.translate(220f, 0f)

    g.color = Color("#0a0")
    PathTest.pathTurtle(g).fill
    g.color = Color("#7B3F00")
    g.stroke = Stroke(4f)
    PathTest.pathTurtle(g).draw

    g.font = Font("48pt Times")
    g.color = Color("darkorange")
    g.drawText("Alpha", 20f, 220f)

    // now set back to opaque

    g.alpha = 1.0f
    g.translate(220f, 0f)

    g.color = Color("#0a0")
    PathTest.pathTurtle(g).fill
    g.color = Color("#7B3F00")
    g.stroke = Stroke(4f)
    PathTest.pathTurtle(g).draw

    g.font = Font("48pt Times")
    g.color = Color("darkorange")
    g.drawText("Opaque", 20f, 220f)
  }


}

