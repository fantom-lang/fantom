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

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make()
  {
    content = EdgePane
    {
      top = InsetPane(5,0,4,4)
      {
        EdgePane
        {
          center = InsetPane(0,4,0,0) { combo }
          right  = ToolBar { addCommand(closeCmd) }
        }
      }
      center = BorderPane
      {
        content  = treePane
        insets   = Insets(1,1,0,0)
        onBorder = |Graphics g, Insets insets, Size size|
        {
          g.brush = Color.sysNormShadow
          g.drawLine(0, 0, size.w, 0)
          g.drawLine(size.w-1, 0, size.w-1, size.h-1)
        }
      }
    }

    // always add root as first tree
    addTree(null)
    select(0)
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  override Void onLoad()
  {
    state := NavBarState.load
    state.roots.each |Uri uri| { addTree(FileResource.makeFile(uri.toFile)) }
    if (state.selected != null) select(state.selected)
  }

  override Void onUnload()
  {
    state := NavBarState()
    trees.each |Tree t, Int i|
    {
      // never store root
      if (i > 0) state.roots.add(t.model.roots.first->uri)
    }
    state.selected = combo.selectedIndex
    state.save
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Add a new tree rooted at the given resource. If null
  ** is passed, use the root of the file system for the
  ** tree root.
  **
  Void addTree(Resource r)
  {
    // create new tree for r
    tree := Tree
    {
      model = NavTreeModel.make(r == null ? Resource.roots : [r])
      border = false
      onAction.add(&onAction)
      onPopup.add(&onPopup)
    }

    // add tree
    trees.add(tree)
    treePane.add(tree)

    // ignore onModify events while we update combo
    ignore = true
    old  := combo.selectedIndex
    name := r == null ? type.loc("navBar.root") : r.name
    combo.items = combo.items.dup.add(name)
    if (old >= 0) combo.selectedIndex = old
    ignore = false
  }

  **
  ** Select the tree with the given index.
  **
  Void select(Int index)
  {
    if (index < 0 || index >= trees.size)
      throw ArgErr("Index out of bounds: $index")

    // bail if already selected
    tree := trees[index]
    if (active === tree) return

    // update tree pane
    active = tree
    if (treePane.active != null)
      treePane.active.visible = false
    treePane.active = tree
    treePane.active.visible = true
    treePane.relayout

    // update combo
    ignore = true
    combo.selectedIndex = index
    ignore = false

    // update cmd state
    closeCmd.enabled = tree != trees.first
  }

  **
  ** Close the current tree. If there is only one tree
  ** open, then this method has no effect.
  **
  Void close()
  {
    index := combo.selectedIndex
    if (index == 0) return // can't close root

    // remove tree
    tree := trees.removeAt(index)
    treePane.remove(tree)

    // remove combo item
    ignore = true
    items := combo.items.dup
    items.removeAt(index)
    combo.items = items
    ignore = false

    // select prev tree
    select(index-1)
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  internal Void onModify(Event event)
  {
    if (ignore) return
    index := event.widget->selectedIndex
    if (index >= 0) select(index)
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
      menu.add(MenuItem { mode = MenuItemMode.sep })
      menu.add(MenuItem { command = Command.makeLocale(type.pod, "navBar.refresh", &onRefresh(r)) })
      menu.add(MenuItem { command = Command.makeLocale(type.pod, "navBar.goInto", &onGoInto(r)) })
    }
    event.popup = menu
  }

  internal Void onRefresh(Resource r)
  {
    r.refresh
    active.refreshNode(r)
  }

  internal Void onGoInto(Resource r)
  {
    addTree(r)
    select(trees.size-1)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Tree active
  Tree[] trees := Tree[,]
  Bool ignore  := true
  Combo combo  := Combo() { onModify.add(&onModify) }
  NavTreePane treePane := NavTreePane()
  Command closeCmd := Command.makeLocale(type.pod, "navBar.close", &close)
}

**************************************************************************
** NavBarState
**************************************************************************

@serializable
internal class NavBarState
{
  static NavBarState load() { return Flux.loadOptions("session/navBar", NavBarState#) }
  Void save() { Flux.saveOptions("session/navBar", this) }
  Uri[] roots := [,]
  Int selected := null
}

**************************************************************************
** NavTreeModel
**************************************************************************

internal class NavTreeModel : TreeModel
{
  new make(Obj[] roots) { this.myRoots = roots }
  override Obj[] roots() { return myRoots }
  override Str text(Obj node) { return ((Resource)node).name }
  override Image image(Obj node) { return ((Resource)node).icon }
  override Bool hasChildren(Obj node) { return ((Resource)node).hasChildren }
  override Obj[] children(Obj node) { return ((Resource)node).children }
  private Obj[] myRoots
}

**************************************************************************
** NavTreePane
**************************************************************************

internal class NavTreePane : Pane
{
  override Size prefSize(Hints hints := Hints.def) { return Size(100,100) }
  override Void onLayout()
  {
    if (active != null)
    {
      active.bounds = Rect(0, 0, size.w, size.h)
      active.relayout
    }
  }
  Widget active
}