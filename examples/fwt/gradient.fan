#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Sep 09  Brian Frank  Creation
//

using gfx
using fwt

**
** Show SWT's limited support for Gradients
**
class GradientDemo : Canvas
{
  override Void onPaint(Graphics g)
  {
    w := size.w; h := size.h

    g.brush = Color.white
    g.fillRect(0, 0, w, h)

    g.brush = gradient
    g.fillRect(20, 20, w-40, h-40)

    g.brush = Color.black
    g.drawRect(0, 0, w-1, h-1)
    g.drawRect(20, 20, w-40, h-40)
  }

  Gradient gradient := Gradient()

  static Void main()
  {
    canvas := GradientDemo()

    textField := Text { text = canvas.gradient.toStr }
    textField.onAction.add |e|
    {
      canvas.gradient = Gradient.fromStr(textField.text)
      echo("$canvas.gradient")
      canvas.repaint
    }

    // build pane to hold input fields and canvas
    edge := EdgePane
    {
      top = InsetPane { content = textField }
      center = canvas
    }

    // open in window
    Window
    {
      content = InsetPane { content=edge }
      size = Size(400, 400)
    }.open
  }
}