//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

using graphics

@Js
class FontStyleTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    names := ["Times", "Consolas", "Courier"]

    tx := 20f
    ty := 0f
    g.color = Color.black
    names.each |n|
    {
      ty += 40f
      g.font = Font("italic 12pt $n")
      g.drawText("$g.font", tx, ty)

      9.times |i|
      {
        weight := 100*(i+1)
        ty += 20f
        g.font = Font("$weight 12pt $n")
        g.drawText("$g.font", tx, ty)
      }
    }
  }
}

