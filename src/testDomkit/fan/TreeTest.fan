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
class TreeTest : DomkitTest
{
  new make()
  {
    tree = Tree
    {
      it.style->width  = "300px"
      it.style->height = "90%"
      it.roots = testRoots
      it.onSelect { echo("# sel: $tree.sel.item [${tree.sel.item->parent}]") }
      it.onAction { echo("# ACTION: $tree.sel.item") }
      it.onTreeEvent("mousedown") |te| { echo("> $te") }
      it.rebuild
    }

    add(Box {
      it.style->padding="24px"
      tree,
    })
  }

  static TreeNode[] testRoots()
  {
    return [
      TestTreeNode("0"),
      TestTreeNode("1"),
      TestTreeNode("2"),
      TestTreeNode("3"),
      TestTreeNode("4"),
    ]
  }

  Tree tree
}

@Js class TestTreeNode : TreeNode
{
  new make(Str key, Int numKids := 5)
  {
    this.key = key
    numKids.times |i| {
      kids.add(TestTreeNode("$key-$i", key.size < 5 ? 5 : 0))
    }
  }
  override TreeNode[] children() { kids }
  override Void onElem(Elem elem, TreeFlags flags)
  {
    sel   := flags.selected && flags.focused
    icon  := true //col % 4 == 0
    color := (flags.selected && flags.focused) ? "white" : "grey"

    elem.style->padding            = icon ? "0 0 0 18px" : "0"
    elem.style->backgroundImage    = icon ? "url(/pod/testDomkit/res/info-${color}.svg)" : ""
    elem.style->backgroundRepeat   = "no-repeat"
    elem.style->backgroundPosition = "0px center"
    elem.style->backgroundSize     = "14px 14px"

    elem.text = "Node $key"
  }
  override Str toStr() { key }
  private const Str key
  private Bool icon := true
  private TreeNode[] kids := [,]
}
