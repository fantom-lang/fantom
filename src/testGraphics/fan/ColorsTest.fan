//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2022  Brian Frank  Creation
//

using graphics

@Js
class ColorsTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    keywords := Color.keywords.sort

    x := 10f
    y := 10f

    keywords.each |keyword|
    {
      g.color = Color(keyword)
      g.fillRect(x, y, 40f, 20f)
      g.color = Color.black
      g.drawRect(x, y, 40f, 20f)
      g.drawText(keyword, x+45, y+15f)

      y += 25f
      if (y + 30f > size.h)
      {
        x += 180f
        y = 10f
      }
    }
  }
}

