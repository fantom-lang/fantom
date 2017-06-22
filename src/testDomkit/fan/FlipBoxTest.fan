//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

using dom
using domkit

@Js
class FlipBoxTest : DomkitTest
{
  new make()
  {
    box1 := FlipBox
    {
      front = Box {
        it.style.setCss("background:#ccc; padding:12px; width:100%; height:100%")
        it.text = "Front"
      }
      back  = Box {
        it.style.setCss("background:#666; padding:12px; color:#fff; width:100%; height:100%")
        it.text = "Back"
      }
    }

    buttons := GridBox
    {
      it.cellStyle("*", "*", "padding:4px 0")
      it.addRow([Button { it.text="Flip";     it.style->width="100%"; onAction { box1.flip    }}])
      it.addRow([Button { it.text="To Front"; it.style->width="100%"; onAction { box1.toFront }}])
      it.addRow([Button { it.text="To Back";  it.style->width="100%"; onAction { box1.toBack  }}])
    }

    add(GridBox
    {
      it.style->padding = "12px"
      it.cellStyle("*", "*", "width:200px; height:200px; padding:12px")
      it.addRow([box1, buttons])
    })
  }
}