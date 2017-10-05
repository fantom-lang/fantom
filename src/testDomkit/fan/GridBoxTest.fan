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
class GridBoxTest : DomkitTest
{
  new make()
  {
    this.add(SashBox {
      it.style->padding = "20px"
      it.dir = Dir.down
      it.sizes = ["auto", "20px", "auto"]
      example,
      Box {},
      Box {
        docDomkit.with {
          it.style.addClass("domkit-border")
          it.style->width   = "auto"
          it.style->display = "inline-block"
        },
      },
    })
  }

  Elem example()
  {
    GridBox
    {
      it.cellStyle("*",   "*",  "padding: 4px")
      it.cellStyle("*", "odd",  "background: #eee")
      it.cellStyle(  0,     0,  "font-weight: bold; border-bottom: 1px solid #666")
      it.cellStyle("*",     5,  "background: #fff; height: 20px")
      it.cellStyle("*",     6,  "font-weight: bold; border-bottom: 1px dashed #666")
      it.cellStyle(  2,     6,  "text-align: right")
      it.cellStyle(  0,   "*",  "padding-right: 18px")
      it.cellStyle(  1,   "*",  "text-align: right")
      it.cellStyle(  0,   7..9, "padding-left: 10px")
      it.cellStyle(  2,   7..9, "text-align: right; color: #999")

      it.addRow([label("A Long Heading")], [3])
      it.addRow([label("Alpha"), label("12.543"),    button("Button 1")])
      it.addRow([label("Beta"),  null,               button("Button 2")])
      it.addRow([null,           label("543.10"),    button("Button 3")])
      it.addRow([label("Delta"), label("(2343.33)"), null])

      it.addRow([null], [3])
      it.addRow([label("Another Heading"), label("Total")], [2])
      it.addRow([label("Site A"), null, label("1400kw")])
      it.addRow([label("Site B"), null, label("735kw")])
      it.addRow([label("Site C"), null, label("2580kw")])
    }
  }

  Elem docDomkit()
  {
    GridBox
    {
      it.cellStyle("*",    "*", "padding: 4px")
      it.cellStyle("*", "even", "background: #f8f8f8")
      it.cellStyle("*",     4,  "background: #e8e8e8; border-top: 1px solid #ccc")

      it.addRow([Label {
        it.text = "Enter User Information"
        it.style->fontWeight = "bold"
      }], [2])
      it.addRow([Label { it.text="First Name:"  }, TextField {}])
      it.addRow([Label { it.text="Middle Name:" }, TextField {}])
      it.addRow([Label { it.text="Last Name:"   }, TextField {}])
      it.addRow([null, Button { it.text="Submit" }])
    }
  }

  private Label label(Str text) { Label { it.text=text } }
  private Button button(Str text) { Button { it.text=text } }
}