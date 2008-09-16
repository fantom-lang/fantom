//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** NavBar is the primary top level tree based navigation side bar.
**
@fluxSideBar
internal class NavBar : SideBar
{
  new make()
  {
    content = EdgePane
    {
      top = BorderPane
      {
        content  = Combo {}
        insets   = Insets(4,4,6,4)
        onBorder = |Graphics g, Insets insets, Size size|
        {
          g.brush = Color.sysNormShadow
          g.drawLine(0, size.h-1, size.w, size.h-1)
        }
      }
      center = NavSideBarPane {}
    }
    goInto(null)
  }

  override Void onLoad()
  {
    state := NavBarState.load
    state.goInto.each |Uri uri|
    {
      goInto(FileResource.makeFile(uri.toFile))
    }
  }

  override Void onUnload()
  {
    state := NavBarState()
    trees.each |Tree t|
    {
      if (t.model.roots.size == 1)
        state.goInto.add(t.model.roots.first->uri)
    }
    state.save
  }

  internal Void onAction(Event event)
  {
    if (event.data != null)
      frame.load(event.data, LoadMode(event))
  }

  internal Void onPopup(Event event)
  {
    r := event.data as Resource
    menu := r?.popup(frame, event) ?: Menu()
    if (r is FileResource && r->file->isDir)
    {
      menu.add(MenuItem { mode=MenuItemMode.sep })
      menu.add(MenuItem { text=type.loc("goInto.name"); onAction.add(&goInto(r)) })
    }
    event.popup = menu
  }

  internal Void goInto(Resource r)
  {
    tree := Tree
    {
      model = NavModel.make(r==null ? Resource.roots : [r])
      border = false
      onAction.add(&onAction)
      onPopup.add(&onPopup)
    }
    trees.add(tree)
    select(tree, true)

    items := trees.map(Obj[,]) |Tree t->Obj|
    {
      roots := t.model.roots
      return roots.size>1 ? type.loc("navBar.root") : roots.first->name
    }
    content->top->content = Combo
    {
      items = items
      selectedIndex = items.size-1
      onModify.add(|Event e| { select(trees[e.widget->selectedIndex]) })
    }
    content.relayout
  }

  internal Void select(Tree tree, Bool add := false)
  {
    if (active === tree) return
    active = tree
    pane := content->center as NavSideBarPane
    if (add) pane.add(tree)
    if (pane.active != null) pane.active.visible = false
    pane.active = tree
    pane.active.visible = true
    pane.relayout
  }

  Tree active
  Tree[] trees := Tree[,]
}

internal class NavModel : TreeModel
{
  new make(Obj[] roots) { this.myRoots = roots }
  override Obj[] roots() { return myRoots }
  override Str text(Obj node) { return ((Resource)node).name }
  override Image image(Obj node) { return ((Resource)node).icon }
  override Bool hasChildren(Obj node) { return ((Resource)node).hasChildren }
  override Obj[] children(Obj node) { return ((Resource)node).children }
  private Obj[] myRoots
}

@serializable
internal class NavBarState
{
  static NavBarState load() { return Flux.loadOptions("session/navBar", NavBarState#) }
  Void save() { Flux.saveOptions("session/navBar", this) }

  Uri[] goInto := [,]
}

internal class NavSideBarPane : Pane
{
  override Size prefSize(Hints hints := Hints.def) { return Size(100,100) }
  override Void onLayout()
  {
    active.bounds = Rect(0, 0, size.w, size.h)
    active.relayout
  }
  Widget active
}
