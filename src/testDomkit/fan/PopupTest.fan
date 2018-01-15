//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Oct 2017  Andy Frank  Creation
//

using dom
using domkit

@Js
class PopupTest : DomkitTest
{
  new make()
  {
    add(GridBox
    {
      it.style->padding = "18px"
      it.cellStyle("*", "*", "padding: 18px")
      it.addRow([basics])
    })
    this.add(abs("calc(100% - 150px)", "40px"))
    this.add(abs("calc(100% - 150px)", "calc(100% - 60px)"))
  }

  Elem basics()
  {
    FlowBox
    {
      it.gaps = ["12px"]
      Button { it.text="Open"; onAction |b| { open(b) }},
    }
  }

  Elem abs(Str x, Str y)
  {
    Button {
      it.style->position = "absolute"
      it.style->left = x
      it.style->top  = y
      it.text="Test Bounds"
      it.onAction |b|
      {
        open(b, "padding:12px; width:500px; height:300px")
      }
    }
  }

  Void open(Elem b, Str css := "padding:12px; width:300px")
  {
    p := Popup {
      it.style.setCss(css)
      it.onOpen  { echo("# open")  }
      it.onClose { echo("# close") }
      Box
      {
        it.text= "Lorem ipsum dolor sit amet, consectetur adipiscing
                  elit. Etiam accumsan, felis vestibulum elementum
                  efficitur, ligula sem porta magna, sit amet semper
                  lacus lorem vitae lacus."
      },
    }

    p.open(b.pagePos.x, b.pagePos.y + b.size.h)
  }
}