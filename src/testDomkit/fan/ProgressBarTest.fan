//
// Copyright (c) 2015, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   17 Mar 2015  Andy Frank  Creation
//

using dom
using domkit

@Js
class ProgressBarTest : DomkitTest
{
  new make()
  {
    grid := GridBox
    {
      it.style->padding = "12px"
      it.cellStyle("all", "all", "padding: 12px")
      it.addRow([barDef, barText, barColor, barTextColor])
    }

    this.style->overflow = "auto"
    this.style->background = "#eee"
    this.add(grid)
  }

  Elem barDef()
  {
    GridBox
    {
      it.cellStyle("all", "all", "padding:4px")
      it.addRow([ProgressBar {}])
      it.addRow([ProgressBar { it.val=40 }])
      it.addRow([ProgressBar { it.val=75 }])
      it.addRow([ProgressBar { it.val=100 }])
    }
  }

  Elem barText()
  {
    GridBox
    {
      it.cellStyle("all", "all", "padding:4px")
      it.addRow([ProgressBar { it.onText |p| { p.val.toStr }; }])
      it.addRow([ProgressBar { it.onText |p| { p.val.toStr }; it.val=40 }])
      it.addRow([ProgressBar { it.onText |p| { p.val.toStr }; it.val=75 }])
      it.addRow([ProgressBar { it.onText |p| { p.val.toStr }; it.val=100 }])
    }
  }

  Elem barColor()
  {
    GridBox
    {
      f := |ProgressBar p->Str|
      {
        if (p.val < 25) return DomkitTest.colors["red"]
        if (p.val < 50) return DomkitTest.colors["orange"]
        if (p.val < 80) return DomkitTest.colors["yellow"]
        return DomkitTest.colors["green"]
      }

      it.cellStyle("all", "all", "padding:4px")
      it.addRow([ProgressBar { it.onBarColor |p| { f(p) }; }])
      it.addRow([ProgressBar { it.onBarColor |p| { f(p) }; it.val=40 }])
      it.addRow([ProgressBar { it.onBarColor |p| { f(p) }; it.val=75 }])
      it.addRow([ProgressBar { it.onBarColor |p| { f(p) }; it.val=100 }])
    }
  }

  Elem barTextColor()
  {
    GridBox
    {
      f := |ProgressBar p->Str|
      {
        if (p.val < 25) return DomkitTest.colors["red"]
        if (p.val < 50) return DomkitTest.colors["orange"]
        if (p.val < 80) return DomkitTest.colors["yellow"]
        return DomkitTest.colors["green"]
      }

      it.cellStyle("all", "all", "padding:4px")
      it.addRow([ProgressBar { it.onText |p| { "${p.val}%" }; it.onBarColor |p| { f(p) }; }])
      it.addRow([ProgressBar { it.onText |p| { "${p.val}%" }; it.onBarColor |p| { f(p) }; it.val=40 }])
      it.addRow([ProgressBar { it.onText |p| { "${p.val}%" }; it.onBarColor |p| { f(p) }; it.val=75 }])
      it.addRow([ProgressBar { it.onText |p| { "${p.val}%" }; it.onBarColor |p| { f(p) }; it.val=100 }])
    }
  }
}