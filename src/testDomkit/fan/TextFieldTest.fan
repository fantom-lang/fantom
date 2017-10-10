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
class TextFieldTest : DomkitTest
{
  new make()
  {
    this.style->background = "#eee"
    add(GridBox
    {
      it.style->padding = "12px"
      it.cellStyle("*", "*", "vertical-align: top")
      it.addRow([fields, areas])
    })
  }

  Elem fields()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding: 12px;")
      it.addRow([FlowBox {
        it.gaps = ["5px"]
        Label { it.text="Username:" },
        TextField
        {
          it.onAction |f| { echo("f1: $f.val") }
        },
      }])
      it.addRow([TextField
      {
        it.cols = 40
        it.val = "Hello, world"
        it.onAction |f| { echo("f2: $f.val") }
      }])
      it.addRow([TextField
      {
        it.cols = 60
        it.placeholder = "Placeholder text..."
        it.onModify |f| { echo("f3: $f.val") }
        it.onAction |f| { echo("f3: $f.val") }
      }])
      it.addRow([TextField
      {
        it.password = true
        it.cols = 60
        it.onModify |f| { echo("p1: $f.val") }
        it.onAction |f| { echo("p2: $f.val") }
      }])
      it.addRow([TextField
      {
        it.val = "Disabled"
        it.enabled = false
        it.cols = 60
        it.onModify |f| { throw Err("SHOULD NEVER HAPPEN") }
        // it.onAction |f| { throw Err("SHOULD NEVER HAPPEN") }
      }])
      it.addRow([TextField
      {
        it.val = "Yippee do-da"
        it.ro = true
        it.cols = 60
        it.onModify |f| { throw Err("SHOULD NEVER HAPPEN") }
        // it.onAction |f| { throw Err("SHOULD NEVER HAPPEN") }
      }])

      // docDomkit
      it.addRow([TextField { it.cols=40 }])
      it.addRow([TextField { it.cols=40; it.val="Hello, World" }])
      it.addRow([TextField { it.cols=40; it.placeholder="Search..." }])
    }
  }

  Elem areas()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding: 12px;")
      it.addRow([TextArea
      {
        it.placeholder = "Type something..."
        it.onModify |f| { echo("a1: $f.val") }
      }])
      it.addRow([TextArea
      {
        it.cols = 40
        it.rows = 10
        it.val = "Some text\n  Here\nAnd there"
        it.onModify |f| { echo("a2: $f.val") }
      }])
      it.addRow([TextArea
      {
        it.ro = true
        it.cols = 40
        it.rows = 10
        it.val = "Can't edit\n  me!\nSo there!"
        it.onModify |f| { echo("a2: $f.val") }
      }])
      it.addRow([TextArea
      {
        it.cols = 40
        it.rows = 5
        it.enabled = false
        it.val = "Disabled\nDude"
      }])
    }
  }
}
