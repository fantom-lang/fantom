//
// Copyright (c) 2018, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jan 2018  Andy Frank  Creation
//

using dom
using domkit

@Js
class AccordionBoxTest : DomkitTest
{
  new make()
  {
    acc := AccordionBox
    {
      it.style->padding = "10px"
      it.addGroup(header("Group 1"), content("#1"), true)
      it.addGroup(header("Group 2"), content("#2"), false)
      it.addGroup(header("Group 3"), content("#3"), false)
      it.addGroup(header("Group 4"), content("#4"), false)
    }

    actions := GridBox
    {
      grid := it
      it.style->padding = "20px"
      it.cellStyle("*", "*", "padding: 5px")
      (0..3).each |i|
      {
        grid.addRow([
          Button { it.text="Toggle #${i+1}";   it.onAction { acc.expand(i, !acc.isExpanded(i)) }},
          Button { it.text="Expand #${i+1}";   it.onAction { acc.expand(i, true) }},
          Button { it.text="Collapse #${i+1}"; it.onAction { acc.expand(i, false) }},
        ])
      }
    }

    add(SashBox
    {
      it.dir = Dir.right
      it.sizes = ["50%","50%"]
      acc,
      actions,
    })
  }

  private Elem header(Str text)
  {
    Label {
      it.style->dislay = "block"
      it.style->padding = "5px"
      it.style->background = "#f8f8f8"
      it.style->borderBottom = "1px solid #e5e5e5"
      it.text = text
    }
  }

  private Elem[] content(Str text)
  {
    [Box {
//      it.style->height = "200px"
      it.style->padding = "10px"
      it.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit,
                 sed do eiusmod tempor incididunt ut labore et dolore magna
                 aliqua. Ut enim ad minim veniam, quis nostrud exercitation
                 ullamco laboris nisi ut aliquip ex ea commodo consequat.
                 Duis aute irure dolor in reprehenderit in voluptate velit
                 esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
                 occaecat cupidatat non proident, sunt in culpa qui officia
                 deserunt mollit anim id est laborum"
    }]
  }
}