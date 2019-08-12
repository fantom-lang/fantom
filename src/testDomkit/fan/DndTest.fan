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
class DndTest : DomkitTest
{
  new make()
  {
    add(GridBox
    {
      it.style->padding = "12px"
      it.addRow([sources, target])
    })
  }

  Elem sources()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding:12px 24px 12px 12px")
      it.addRow([Box {
        it.style->background = DomkitTest.colors["red"]
        it.style->padding    = "10px"
        it.style->width      = "200px"
        it.style->height     = "40px"
        it.text = "Drag me #1"
        DragTarget.bind(it) { it.onDrag { "Box #1" }}
      }])
      it.addRow([Box {
        it.style->background = DomkitTest.colors["green"]
        it.style->padding    = "10px"
        it.style->width      = "200px"
        it.style->height     = "40px"
        it.text = "Drag me #2"
        DragTarget.bind(it) { it.onDrag { "Box #2" }}
      }])
      it.addRow([Box {
        it.style->background = DomkitTest.colors["blue"]
        it.style->padding    = "10px"
        it.style->width      = "200px"
        it.style->height     = "40px"
        it.text = "Drag me #3 - No drop"
        DragTarget.bind(it) { it.onDrag { "Box #3" }}
      }])
    }
  }

  Elem target()
  {
    Box {
      it.style.setCss("background: #eee; padding: 10px; width: 300px; height: 300px")
      DropTarget.bind(it)
      {
        it.canDrop |data| { data != "Box #3" }
        it.onDrop  |data|
        {
          files := data as DomFile[]
          if (files == null) echo("# DROP: $data")
          else echo("# DROP: " + files.join(", ") |f| { f.name })
        }
      }
      TextField { it.val="Z-order Test" },
    }
  }
}