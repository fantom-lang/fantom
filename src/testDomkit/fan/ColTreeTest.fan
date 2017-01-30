//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

/*
using dom
using domkit
using haystack
using ui

@Js
class ColTreeTest : DomkitTest
{
  new make()
  {
    tree = ColTree
    {
      it.model = toModel
    }

    box := FlexBox
    {
      it.dir = "column"
      it.flex = ["0 0 auto", "1 1 auto"]
      it.style.setCss("position: absolute; padding: 12px;")
      // FlexBox
      // {
      //   it.flex = ["1 1 auto", "0 0 auto"]
      //   it.style.setCss("padding:0 0 12px 0;")
      //   OldGridBox
      //   {
      //     colGaps = "6px 24px"
      //     Elem { it.text="Cols:" }, colField,
      //     Elem { it.text="Rows:" }, rowField,
      //     showHeader,
      //   },
      //   Button { it.text = "Update"; it.onAction { doUpdate } },
      // },
Box {},
      tree,
    }

    add(box)
  }

  TreeModel toModel()
  {
    TestTreeModel("Node", 5, 5)
  }

  // Void doUpdate()
  // {
  //   table.showHeader = showHeader.selected
  //   table.model = toModel
  // }

  ColTree tree

  // TextField colField := TextField { it.val="10"   }
  // TextField rowField := TextField { it.val="1000" }
  // ToggleButton showHeader  := ToggleButton
  // {
  //   it.elemOn  = Elem { it.text="Header On"  }
  //   it.elemOff = Elem { it.text="Header Off" }
  //   it.selected = true
  // }
}
*/