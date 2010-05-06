//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using gfx
using fwt

**
** NavBar is the primary top level tree based navigation side bar.
**
internal class NavBar : SideBar
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make()
  {
    content = EdgePane
    {
      top = InsetPane(5,4,5,4) { it.add(combo) }
      center = BorderPane
      {
        it.content = treePane
        it.border  = Border("1,1,0,0 $Desktop.sysNormShadow")
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
    state.roots.each |uri| { addTree(FileResource.makeFile(uri.toFile)) }
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
  Void addTree(Resource? r)
  {
    // create new tree for r
    tree := Tree
    {
      it.model = NavTreeModel.make(r == null ? Resource.roots : [r])
      it.border = false
      it.onAction.add |e| { this.onAction(e) }
      it.onPopup.add  |e| { this.onPopup(e) }
    }

    // add tree
    trees.add(tree)
    treePane.add(tree)

    // ignore onModify events while we update combo
    ignore = true
    old   := combo.selectedIndex
    name  := r == null ? Flux.locale("navBar.root") : r.name
    items := combo.items.size == 0 ? combo.items.dup : combo.items[0..<-1]
    combo.items = items.add(name).add(Flux.locale("navBar.editList"))
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
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  internal Void onModify(Event event)
  {
    if (ignore) return
    index := event.widget->selectedIndex
    if (index >= 0)
    {
      if (index == trees.size) editList
      else select(index)
    }
  }

  internal Void onAction(Event event)
  {
    if (event.data != null)
      frame.load(event.data->uri, LoadMode(event))
  }

  internal Void onPopup(Event event)
  {
    Menu? menu
    n := event.data as NavNode
    if (n != null)
    {
      r := n?.resource
      menu = r?.popup(frame, event) ?: Menu()
      if (r is FileResource && r->file->isDir)
      {
        menu.add(MenuItem { mode = MenuItemMode.sep })
        menu.add(MenuItem { command = Command.makeLocale(Pod.of(this), "navBar.refresh") {onRefresh(n)} })
        menu.add(MenuItem { command = Command.makeLocale(Pod.of(this), "navBar.goInto") {onGoInto(n)} })
      }
    }
    else
    {
      menu = Menu()
      menu.add(MenuItem { command = Command.makeLocale(Pod.of(this), "navBar.sync") {onSync} })
    }
    event.popup = menu
  }

  internal Void onRefresh(NavNode n)
  {
    n.refresh
    active.refreshNode(n)
  }

  internal Void onGoInto(NavNode n)
  {
    addTree(n.resource)
    select(trees.size-1)
  }

  internal Void onSync()
  {
    r := frame.view.resource
    if (r isnot FileResource)
    {
      Dialog.openErr(frame, "Resource not found in tree")
      return
    }

    Obj? node := null
    nodes := active.model.roots
    path  := r.uri.path
    path.eachWhile |Str s->Obj|
    {
      found := nodes.eachWhile |Obj n->Obj?|
      {
        if (n->name == s)
        {
          node = n
          nodes = active.model.children(n)
          active.setExpanded(n, true)
          return true
        }
        return null
      }
      return found ? null : false
    }

    if (node != null)
    {
      active.select(node)
      active.show(node)
    }
    else Dialog.openErr(frame, "Resource not found in tree")
  }

  internal Void editList()
  {
    // reset index back to active
    ignore = true
    combo.selectedIndex = trees.findIndex |Tree t->Bool| { t === active }
    ignore = false

    // now show dialog
    list := EditList(combo.items[0..<-1])
    dlg  := Dialog(frame)
    {
      title    = Flux.locale("navBar.edit")
      body     = list
      commands = [Dialog.ok, Dialog.cancel]
    }
    if (dlg.open == Dialog.ok)
    {
      items    := list.getItems
      newTrees := Tree[,]

      // copy new tree order
      items.each |Str item|
      {
        i := combo.items.findIndex |Str x->Bool| { return item == x }
        newTrees.add(trees[i])
      }

      // remove deleted trees
      trees.each |Tree t|
      {
        r := newTrees.find |Tree n->Bool| { return t === n }
        if (r == null) treePane.remove(t)
      }

      // try to select the same tree, or if it was removed
      // fallback to selecting the root
      index := newTrees.findIndex |Tree t->Bool| { return t === active }
      if (index == null) index = 0

      // update widget
      trees = newTrees
      ignore = true
      combo.items = items.add(Flux.locale("navBar.editList"))
      combo.selectedIndex = index
      ignore = false
      select(index)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Tree? active
  Tree[] trees := Tree[,]
  Bool ignore  := true
  Combo combo  := Combo() { it.onModify.add |e| { this.onModify(e) } }
  NavTreePane treePane := NavTreePane()
}

**************************************************************************
** NavBarState
**************************************************************************

@Serializable
internal class NavBarState
{
  static NavBarState load() { return Flux.loadOptions(Flux.pod, "session/navBar", NavBarState#) }
  Void save() { Flux.saveOptions(Flux.pod, "session/navBar", this) }
  Uri[] roots := Uri[,]
  Int? selected := null
}

**************************************************************************
** NavTreeModel
**************************************************************************

internal class NavTreeModel : TreeModel
{
  new make(Resource[] roots) { this.myRoots = NavNode.map(roots) }
  override Obj[] roots() { return myRoots }
  override Str text(Obj node) { return ((NavNode)node).name }
  override Image? image(Obj node) { return ((NavNode)node).icon }
  override Bool hasChildren(Obj node) { return ((NavNode)node).hasChildren }
  override Obj[] children(Obj node) { return ((NavNode)node).children }
  private NavNode[] myRoots
}

**************************************************************************
** NavNode
**************************************************************************

@Serializable
internal class NavNode
{
  static NavNode[] map(Resource[] r)
  {
    return r.map |Resource x->NavNode| { NavNode(x) }
  }
  new make(Resource r) { resource = r }
  Resource resource
  override Str toStr() { return resource.toStr }
  Uri uri() { return resource.uri }
  Str name() { return resource.name }
  Image? icon() { return resource.icon }
  Bool hasChildren() { return resource.hasChildren }
  NavNode[]? children
  {
    get
    {
      if (&children == null) &children = map(resource.children)
      return &children
    }
  }
  Void refresh()
  {
    resource = Resource.resolve(resource.uri)
    children = null
  }
}

**************************************************************************
** NavTreePane
**************************************************************************

internal class NavTreePane : Pane
{
  override Size prefSize(Hints hints := Hints.defVal) { return Size(100,100) }
  override Void onLayout()
  {
    if (active != null)
    {
      active.bounds = Rect(0, 0, size.w, size.h)
      active.relayout
    }
  }
  Widget? active
}

**************************************************************************
** EditListWidget
**************************************************************************

internal class EditList : Canvas
{
  new make(Obj[] items)
  {
    this.items = items.map |Obj obj->Str|  { obj.toStr }
    this.keep  = items.map |Obj obj->Bool| { true }
    onMouseDown.add { onPressed(it) }
  }

  Str[] getItems()
  {
    return items.findAll |Str s, Int i->Bool| { return keep[i] }
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    pw := 0
    ph := rowh * items.size
    items.each |Str item| { pw = pw.max(font.width(item)) }
    pw += 64 + 16
    return Size(pw, ph)
  }

  override Void onPaint(Graphics g)
  {
    g.font = font
    items.each |Str item, Int i|
    {
      dy := i * rowh
      iy := dy + (rowh - 16) / 2
      ty := dy + (rowh - font.height) / 2
      g.push
      try
      {
        if (!keep[i]) g.alpha = 95;
        if (i>0) g.drawImage(delete, 0, iy)
        g.drawImage(folder, 20, iy)
        g.drawText(item, 40, ty)
        if (i>1) g.drawImage(up, size.w-32, iy)
        if (i>0 && i<items.size-1) g.drawImage(down, size.w-16, iy)
      }
      finally g.pop
    }
  }

  Void onPressed(Event e)
  {
    row := e.pos.y / rowh
    if (row < 0) row = 0
    if (row > items.size-1) row = items.size-1
    if (row == 0) return  // can't modify row zero, so just bail
    if (e.pos.x <= 16)    // delete
    {
      keep[row] = !keep[row]
      repaint
      return
    }
    if (e.pos.x > size.w-32) {
      if (e.pos.x < size.w-16) {
        if (row > 1)
        {
          // move up
          items.swap(row, row-1)
          keep.swap(row, row-1)
        }
      }
      else
      {
        if (row < items.size-1)
        {
          // move down
          items.swap(row, row+1)
          keep.swap(row, row+1)
        }
      }
      repaint
    }
  }

  private Str[] items
  private Bool[] keep
  private Font font    := Desktop.sysFont
  private Image folder := Flux.icon(`/x16/folder.png`)
  private Image delete := Flux.icon(`/x16/circleDelete.png`)
  private Image up     := Flux.icon(`/x16/circleArrowUp.png`)
  private Image down   := Flux.icon(`/x16/circleArrowDown.png`)
  private Int rowh     := 16.max(font.height) + 4
}