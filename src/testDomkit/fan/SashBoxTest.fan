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
class SashBoxTest : DomkitTest
{
  new make()
  {
    update
  }

  override Bool hasOptions() { true }

  override Void onOptions()
  {
    dlg := Dialog { it.title = "Options" }
    dlg.add(GridBox
    {
      it.style->padding = "6px"
      it.cellStyle("*", "*", "padding: 6px")
      it.addRow([Label { it.text="Layout Dir:"  }, dir    ])
      it.addRow([Label { it.text="Resizable:"   }, resize ])
      it.addRow([Label { it.text="Child Type:"  }, type   ])
      it.addRow([Label { it.text="Child Sizes:" }, sizes  ])
      it.addRow([FlowBox {
        it.style->paddingTop = "6px"
        it.halign = Align.right
        it.gaps = ["4px"]
        Button { it.text="Update"; onAction { dlg.close; update }},
        Button { it.text="Cancel"; onAction { dlg.close }},
      }], [2])
    })
    dlg.open
  }

  Void update()
  {
    resz := resize.sel.item == true

    sash := SashBox
    {
      it.dir = this.dir.sel.item
      it.sizes = this.sizes.val.split(',')
      it.resizable = resz
    }

    sash.sizes.each |sz,i|
    {
      if (resz && i.isOdd)
      {
        sash.add(SashBox.div)
      }
      else
      {
        t := "kid-$i: $sz"
        c := DomkitTest.safeColor(i)
        Elem? k
        switch (type.sel.index)
        {
          case 0: k = Box  { it.style->background="$c"; it.text=t }
          case 1: k = Elem { it.style->background="$c"; it.text=t }
          case 2: k = Elem("span") { it.style->background="$c"; it.text=t }
          case 3: k = Button { it.text=t }
          case 4: k = Tree { it.roots=TreeTest.testRoots }
        }
        sash.add(k)
      }
    }

    removeAll.add(sash)
  }

  ListButton type   := ListButton { it.items = ["box", "block", "inline", "button", "tree"] }
  ListButton dir    := ListButton { it.items = [Dir.right, Dir.down] }
  TextField sizes   := TextField { it.style->width="400px"; it.val="200px, 5px, 100%, 5px, 400px" }
  ListButton resize := ListButton
  {
    it.items = [true, false]
    it.onSelect |b|
    {
      sizes.val = b.sel.item==true
        ? "200px, 5px, 100%, 5px, 400px"
        : "200px, 100%, 400px"
    }
  }
}