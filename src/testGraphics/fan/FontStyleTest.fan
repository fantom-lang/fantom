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
    names := ["sans-serif", "Inter", "Helvetica Neue", "Monaco", "Consolas", "monospace"]

    tx := 20f
    ty := 0f
    points := 12
    pixels := 16f
    text := "0123456789 abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    names.each |n|
    {
      ty += 40f
      g.color = Color("black")
      g.font = Font("${points}pt $n")
      g.drawText("$g.font", tx, ty)

      ty += 20f
      g.color = Color("green")
      g.fillRect(tx, ty-pixels, 6f, pixels)
      g.color = Color("black")
      g.drawText(text, tx+10f, ty)

      ty += 20f
      g.color = Color("red")
      g.fillRect(tx, ty-pixels, 6f, pixels)
      g.color = Color("black")
      g.font = Font("bold ${points}pt $n")
      g.drawText(text, tx+10f, ty)

      ty += 20f
      g.color = Color("purple")
      g.fillRect(tx, ty-pixels, 6f, pixels)
      g.color = Color("black")
      g.font = Font("italic ${points}pt $n")
      g.drawText(text, tx+10f, ty)

      ty += 20f
      g.color = Color("orange")
      g.fillRect(tx, ty-pixels, 6f, pixels)
      g.color = Color("black")
      g.font = Font("italic bold ${points}pt $n")
      g.drawText(text, tx+10f, ty)
    }
  }
}

