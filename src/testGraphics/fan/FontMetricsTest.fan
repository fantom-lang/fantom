//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2022  Brian Frank  Creation
//

using graphics

@Js
class FontMetricsTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    buf := StrBuf()
    26.times |i| { buf.addChar('A'+i) }
    26.times |i| { buf.addChar('a'+i) }
    10.times |i| { buf.addChar('0'+i) }
    alphabet := buf.toStr

    names := ["Times", "Helvetica", "Consolas", "Courier", "Tahoma", "Arial"]

    ty := 50f
    tx := 30f

    names.each |name|
    {
      g.font = Font([name], 24f)
      paintText(g, name, tx, ty)
      ty += 50f
      paintText(g, alphabet, tx, ty)
      ty += 50f
    }
  }

  private Void paintText(Graphics g, Str str, Float tx, Float ty)
  {
    fm := g.metrics

    /*
    echo("-- $g.font")
    echo("   height  = $fm.height")
    echo("   ascent  = $fm.ascent")
    echo("   descent = $fm.descent")
    echo("   leading = $fm.leading")
    */

    g.color = Color("orange")
    g.fillRect(tx-15f, ty-fm.height+fm.descent, 10f, fm.height)

    g.color = Color("black")
    g.drawText(str, tx, ty)
    g.color = Color("red")
    g.drawLine(tx, ty, tx+fm.width(str), ty)
    g.color = Color("green")
    g.drawLine(tx, ty-fm.ascent, tx+fm.width(str), ty-fm.ascent)
    g.color = Color("blue")
    g.drawLine(tx, ty+fm.descent, tx+fm.width(str), ty+fm.descent)
    g.drawLine(tx, ty-fm.ascent-fm.leading, tx+fm.width(str), ty-fm.ascent-fm.leading)
  }
}

