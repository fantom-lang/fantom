//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** NavSideBar is the primary top level tree based
** navigation side bar.
**
internal class NavSideBar : SideBar
{
  new make()
  {
    tree.onAction.add(&onAction)
    content = EdgePane
    {
      top = InsetPane(2,0,2,0) {
        Combo {
          items = ["My Computer"]
        }
      }
      center = tree
    }
  }

  internal Void onAction(Event event)
  {
    frame.load(event.data)
  }

  Tree tree := Tree { model = NavModel.make; border = false }
}

internal class NavModel : TreeModel
{
  override Obj[] roots := Resource.roots
  override Str text(Obj node) { return ((Resource)node).name }
  override Image image(Obj node) { return ((Resource)node).icon }
  override Bool hasChildren(Obj node) { return ((Resource)node).hasChildren }
  override Obj[] children(Obj node) { return ((Resource)node).children }
}
