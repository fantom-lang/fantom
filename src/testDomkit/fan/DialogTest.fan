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
class DialogTest : DomkitTest
{
  new make()
  {
    add(GridBox
    {
      it.style->padding = "18px"
      it.cellStyle("*", "*", "padding: 18px")
      it.addRow([basics])
    })
  }

  Elem basics()
  {
    FlowBox
    {
      it.gaps = ["12px"]
      Button { it.text="Title";       onAction { open("Title", ["Close"]) }},
      Button { it.text="No Title";    onAction { open(null,    ["Close"]) }},
      Button { it.text="Ok | Cancel"; onAction { open("Hello", ["Ok", "Cancel"]) }},
      Button { it.text="Wide";        onAction { open("Wide",  ["Close"], "width:600px") }},
      Button { it.text="Complex";     onAction { openComplex }},
    }
  }

  Void open(Str? title, Str[] buttons, Str css := "width:400px")
  {
    dlg := Dialog { it.title=title }
    dlg.add(SashBox
    {
      it.dir = Dir.down
      it.sizes = ["auto", "auto"]
      it.style.setCss("padding:12px; $css")
      Box
      {
        it.text= "Lorem ipsum dolor sit amet, consectetur adipiscing
                  elit. Etiam accumsan, felis vestibulum elementum
                  efficitur, ligula sem porta magna, sit amet semper
                  lacus lorem vitae lacus."
      },
      FlowBox
      {
        it.style->paddingTop = "12px"
        it.halign = Align.right
        it.gaps = ["4px"]
        it.addAll(buttons.map |b| {
          Button
          {
            it.text = b
            it.onAction { dlg.close; echo("# close -> $b") }
          }
        })
      },
    })
    dlg.onOpen  { echo("# onOpen: $title") }
    dlg.onClose { echo("# onClose: $title") }
    dlg.open
  }

  Void openComplex()
  {
    dlg := Dialog { it.title="Complex" }
    dlg.add(SashBox
    {
      it.dir = Dir.down
      it.sizes = ["400px", "auto"]
      it.style->width ="700px"
      SashBox
      {
        it.style.addClass("domkit-border-top")
        it.sizes = ["30%", "70%"]
        Tree
        {
          it.style.removeClass("domkit-border").addClass("domkit-border-right")
          it.roots = TreeTest.testRoots
          it.rebuild
        },
        Table
        {
          it.style.removeClass("domkit-border")
          it.model = TestTableModel
          {
            it.cols = 10
            it.rows = 100
          }
          it.rebuild
        },
      },
      SashBox
      {
        it.style.addClass("domkit-border-top")
        it.style->padding = "12px"
        it.sizes = ["100px", "100%"]
        FlowBox
        {
          it.gaps = ["4px"]
          Button { it.text="Foo"; it.onAction { echo("# Foo") }},
        },
        FlowBox
        {
          it.halign = Align.right
          it.gaps = ["4px"]
          Button { it.text="Ok";     it.onAction { dlg.close; echo("# OK")     }},
          Button { it.text="Cancel"; it.onAction { dlg.close; echo("# Cancel") }},
        },
      },
    })
    dlg.open
  }
}