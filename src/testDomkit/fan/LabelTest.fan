//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Oct 2017  Andy Frank  Creation
//

using dom
using domkit

@Js
class LabelTest : DomkitTest
{
  new make()
  {
    grid := GridBox
    {
      it.style->padding = "12px"
      it.cellStyle("*", "*", "padding: 12px")
      it.addRow([labels,   links])
      it.addRow([lockups, Elem {}])
    }

    this.style->overflow = "auto"
    this.style->background = "#eee"
    this.add(grid)
  }

  Elem labels()
  {
    FlowBox
    {
      it.gaps = ["12px"]
      Label { it.text="Lorem Ipsom" },
      Label { it.text="Disabled"; it.style.addClass("disabled") },
    }
  }

  Elem links()
  {
    FlowBox
    {
      it.gaps = ["12px"]
      Link { it.uri=`#`; it.text="Lorem Ipsom" },
      Link { it.uri=`#`; it.text="New Tab"; it.target="_blank" },
      Link { it.uri=`#`; it.text="Disabled"; it.style.addClass("disabled") },
    }
  }

  Elem lockups()
  {
    FlowBox {
      it.gaps = ["4px"]
      Label { it.text="Username:" },
      TextField {},
      Button { it.text="Submit" },
    }
  }
}