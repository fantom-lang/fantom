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
class CardBoxTest : DomkitTest
{
  new make()
  {
    items := Str[,]
    cardBox := CardBox {}

    colors.vals.each |c,i|
    {
      items.add("Show Card #$i")
      cardBox.add(Box {
        it.style->background = c
        it.style->padding    = "12px"
        it.style->width      = "100%"
        it.style->height     = "100%"
        it.text = "Card #$i"
      })
    }

    add(GridBox
    {
      it.style->padding = "12px"
      it.cellStyle("all", "all", "width:200px; height:200px; padding:12px")
      it.addRow([
        cardBox,
        ListButton
        {
          it.items = items
          it.onSelect |b| { cardBox.selectedIndex = b.sel.index }
        },
      ])
    })
  }
}