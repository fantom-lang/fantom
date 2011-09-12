#! /usr/bin/env fan
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 11  Brian Frank  Creation
//

using gfx
using fwt

**
** Clipboard illustrates use of the `fwt::Clipboard` API
**
class ClipboardDemo
{
  Void main()
  {
    area  := Text { multiLine = true; text = "Clipboard Example" }
    copy  := |Event e| { Desktop.clipboard.setText(area.text) }
    paste := |Event e| { area.text = Desktop.clipboard.getText ?: "text not avail" }

    Window
    {
      title = "Clipboard Demo"
      EdgePane
      {
        top = InsetPane
        {
          content = GridPane
          {
            it.numCols = 2
            Button { text = "Copy"; onAction.add(copy) },
            Button { text = "Paste"; onAction.add(paste) },
          }
        }
        center = InsetPane { content = area }
      },;
      size = Size(500,400)
    }.open
  }
}

