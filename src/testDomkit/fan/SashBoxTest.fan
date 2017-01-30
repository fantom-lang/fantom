//
// Copyright (c) 2015, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   5 Jun 2015  Andy Frank  Creation
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
      it.cellStyle("all", "all", "padding: 6px")
      it.addRow([Label { it.text="Layout Dir:"  }, dir   ])
      it.addRow([Label { it.text="Child Type:"  }, type  ])
      it.addRow([Label { it.text="Child Sizes:" }, sizes ])
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
    sash := SashBox
    {
      it.dir = this.dir.sel.item
      it.sizes = this.sizes.val.split(',')
      it.resizable = true
    }

    sash.sizes.each |sz,i|
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

    removeAll.add(sash)
  }

  ListButton type := ListButton { it.items = ["box", "block", "inline", "button", "tree"] }
  ListButton dir  := ListButton { it.items = [Dir.right, Dir.down] }
  TextField sizes := TextField { it.style->width="400px"; it.val = "200px, 100%, 400px" }
}