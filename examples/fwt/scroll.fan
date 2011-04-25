#! /usr/bin/env fan
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Apr 11  Yuri Strot  Creation
//

using gfx
using fwt

**
** Show ScrollBar in action
**
class ScrollDemo
{
  static Void main()
  {
    grid := GridPane()
    grid.numCols = 2

    grid.add(Label { text = "Vertical scroll bar:" })
    vertText := Text { text = "0" }
    grid.add(vertText)

    grid.add(Label { text = "Horizontal scroll bar:" })
    horText := Text { text = "0" }
    grid.add(horText)

    vertScroll := ScrollBar { orientation = Orientation.vertical }
    horScroll  := ScrollBar { orientation = Orientation.horizontal }

    bind(horText, horScroll)
    bind(vertText, vertScroll)

    edgePane := EdgePane
    {
      bottom = horScroll
      right  = vertScroll
      center = grid
    }

    // open in window
    Window
    {
      content = InsetPane { content = edgePane }
      size = Size(500, 500)
    }.open
  }

  static Void bind(Text text, ScrollBar bar)
  {
    text.onModify.add |evt|
    {
      try
      {
        val := text.text.toInt
        if (bar.val != val) bar.val = val
      }
      catch(Err e) {}
    }
    bar.onModify.add |evt|
    {
      try
      {
        val := bar.val.toStr
        if (text.text != val) text.text = val
      }
      catch(Err e) {}
    }
  }

}