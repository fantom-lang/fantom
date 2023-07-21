//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Brian Frank  Creation
//

using graphics

@Js
class ClipTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    drawStuff(g)

    g.push
    g.translate(200f, 0f)
    g.path.arc(120f, 120f, 75f, 0f, 360f).clip
    drawStuff(g)
    g.pop

    g.push
    g.translate(400f, 0f)
    g.clipRect(45f, 45f, 150f, 150f)
    drawStuff(g)
    g.pop

    g.push
    g.translate(600f, 0f)
    g.clipRoundRect(45f, 45f, 150f, 150f, 50f, 50f)
    drawStuff(g)
    g.pop
  }

  static Void drawStuff(Graphics g)
  {
    g.color = Color("darkorange")
    g.fillRect(20f, 20f, 200f, 200f)
    g.font = Font("24pt Times")
    g.color = Color("Blue")
    g.drawText("Clip this text!", 30f, 120f)
   }

}

