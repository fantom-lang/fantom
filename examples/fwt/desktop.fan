#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 08  Brian Frank  Creation
//

using gfx
using fwt

**
** Paint the desktop monitor configuration.
**
class DesktopDemo : Canvas
{
  Void main()
  {
    Window
    {
      it.title = "Desktop Demo"
      it.size = Size(600,400)
      DesktopDemo {},
    }.open
  }

  override Void onPaint(Graphics g)
  {
    w := size.w
    h := size.h
    f := Font { it.name=Desktop.sysFont.name; it.size=14 }

    // paint background white
    g.font = f
    g.brush = Color.white
    g.fillRect(0, 0, w, h)

    // paint desktop bounds in 1/10 scale
    d := Desktop.bounds
    g.translate( (w-(d.w-d.x)/10)/2, (h-(d.h-d.y)/10)/2 )
    g.brush = Color.blue
    g.pen = Pen { width = 5 }
    g.drawRect(d.x/10, d.y/10, d.w/10, d.h/10)
    g.pen = Pen { width = 1 }

    // paint each monitor
    mon := Monitor.list
    mon.each |Monitor m, Int i|
    {
      g.brush = Color.red
      r := m.screenBounds
      g.fillRect(r.x/10, r.y/10, r.w/10, r.h/10)

      g.brush = Color.yellow
      r = m.bounds
      g.fillRect(r.x/10, r.y/10, r.w/10, r.h/10)

      r = m.screenBounds
      g.brush = Color.black
      g.drawRect(r.x/10, r.y/10, r.w/10, r.h/10)

      g.brush = Color.black
      name := i.toStr
      if (m == Monitor.primary) name += "*"
      g.drawText(name, r.x/10 + (r.w/10-f.width(name))/2, r.y/10 + (r.h/10-f.height)/2)
    }
  }

}