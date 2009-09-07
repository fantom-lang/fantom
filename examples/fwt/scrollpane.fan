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
** Show ScrollPane in action
**
class ScrollPaneDemo
{
  static Void main()
  {
    // build grid of buttons
    grid := GridPane()
    grid.numCols = 10
    200.times |i| { grid.add(Button { text = i.toStr }) }

    // build scroll pane
    scrollPane := ScrollPane
    {
      content = grid
      //border = false
      hbar.onModify.add |evt| { echo("hbar = $evt.data") }
      vbar.onModify.add |evt| { echo("vbar = $evt.data") }
    }

    // open in window
    Window
    {
      content = InsetPane { content=scrollPane }
      size = Size(400, 400)
    }.open
  }

}