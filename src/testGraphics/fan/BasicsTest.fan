//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

using graphics

@Js
class BasicsTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    g.color = Color("yellow")
    g.fillRect(20f, 20f, size.w-40f, size.h-40f)
    g.color = Color("green")
    g.drawRect(20f, 20f, size.w-40f, size.h-40f)
    g.drawLine(20f, 20f, size.w-20f, size.h-20f)
    g.drawLine(20f, size.h-20f, size.w-20f, 20f)

    g.font = Font("bold 24pt Arial")
    text := "Hello World"
    tm := g.metrics
    tw := tm.width(text)
    tx := (size.w - tw) / 2f
    ty := (size.h - g.metrics.height) / 2f + g.metrics.ascent
    g.color = Color("thistle")
    g.fillRoundRect(tx - 30f, ty-60f, tw+60f, tm.height+60f, 20f, 20f)
    g.color = Color("purple")
    g.drawRoundRect(tx - 30f, ty-60f, tw+60f, tm.height+60f, 20f, 20f)
    g.color = Color("blue")
    g.drawText(text, tx, ty)
  }
}

