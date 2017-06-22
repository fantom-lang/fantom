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
    fx    := ["No effect", "slideLeft", "slideRight"]
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
      it.cellStyle("*", "*", "width:200px; height:200px; padding:12px")
      it.cellStyle(  1, "*", "width:100px")
      it.cellStyle(  2, "*", "width:100px")
      it.addRow([
        cardBox,
        ListButton
        {
          it.items = items
          it.onSelect |b| { cardBox.selIndex = b.sel.index }
        },
        ListButton
        {
          it.items = fx
          it.onSelect |b| { cardBox.effect = b.sel.index==0 ? null : b.sel.item }
        },
      ])
    })
  }
}