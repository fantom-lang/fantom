//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 2015  Andy Frank  Creation
//

using dom

**************************************************************************
** TreeNode
**************************************************************************

**
** TreeNode models a node in a Tree.
**
@Js class TreeNode
{
  ** Constructor.
  new make(Obj obj) { this.obj = obj }

  ** Backing object for this node.
  Obj obj { private set }

  ** Return true if this has or might have children. This
  ** is an optimization to display an expansion control
  ** without actually loading all the children.  The
  ** default returns '!children.isEmpty'.
  virtual Bool hasChildren() { !children.isEmpty }

  ** Get the children of this node.  If no children return
  ** an empty list. Default behavior is no children.
  virtual TreeNode[] children() { TreeNode#.emptyList }

  ** Callback to customize Elem for this node.
  virtual Void onElem(Elem elem, TreeFlags flags)
  {
    elem.text = obj.toStr
  }

  override Str toStr() { obj.toStr }

  internal Int? depth
  internal Elem? elem
  internal Bool expanded := false
}

**************************************************************************
** TreeFlags
**************************************************************************

** Tree specific flags for eventing
@Js const class TreeFlags
{
  new make(|This| f) { f(this) }

  ** Tree has focus.
  const Bool focused

  ** Node is selected.
  const Bool selected

  override Str toStr()
  {
    "TreeFlags { focused=$focused; selected=$selected }"
  }
}

**************************************************************************
** Tree
**************************************************************************

**
** Tree visualizes a TreeModel as a series of expandable nodes.
**
@Js class Tree : Box
{
  ** Constructor.
  new make() : super()
  {
    this.sel = TreeSelection(this)
    this->tabIndex = 0
    this.style.addClass("domkit-Tree domkit-border")

    this.onEvent(EventType.mouseUp, false) |e| { handleMouseUp(e) }
    this.onEvent(EventType.mouseDoubleClick, false) |e| { handleMouseDoubleClick(e) }

    // manually track focus so we can detect when
    // the browser window becomes unactive while
    // maintaining focus internally in document
    this.onEvent(EventType.focus, false) |e| { manFocus=true;  refresh }
    this.onEvent(EventType.blur,  false) |e| { manFocus=false; refresh }
  }

  ** Root nodes for this tree.
  TreeNode[] roots := [,]

  ** Rebuild tree layout.
  Void rebuild()
  {
    if (this.size.w > 0) doRebuild
    else Win.cur.setTimeout(16ms) |->| { rebuild }
  }

  ** Refresh tree content.
  Void refresh()
  {
    roots.each |r| { refreshNode(r) }
  }

  ** Refresh given node.
  Void refreshNode(TreeNode node)
  {
    doRefreshNode(node)
  }

  ** Set expanded state for given node.
  Void expand(TreeNode node, Bool expanded)
  {
    // short-cirucit if no-op
    if (node.expanded == expanded) return

    node.expanded = expanded
    refreshNode(node)
  }

  ** Selection for tree. Index based selection is not supported for Tree.
  Selection sel { private set }

  ** Callback when selection changes.
  Void onSelect(|This| f) { cbSelect = f }

  ** Callback when a node has been double clicked.
  Void onAction(|Tree, Event| f) { cbAction = f }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  private Void doRebuild()
  {
    removeAll
    roots.each |r| { add(toElem(null, r)) }
  }

  private Void doRefreshNode(TreeNode node)
  {
    // TODO: how does this work?
    if (node.elem == null) return

    // update css
    node.elem.style.toggleClass("expanded", node.expanded)

    // set expander icon
    expander := node.elem.querySelector(".domkit-Tree-node-expander")
    expander.html = node.hasChildren ? "\u25ba" : "&nbsp;"

    // remove existing children
    while (node.elem.children.size > 1)
      node.elem.remove(node.elem.lastChild)

    // update selection
    selected := sel.items.contains(node)
    content  := node.elem.querySelector(".domkit-Tree-node")
    content.style.toggleClass("domkit-sel", selected)

    // update content
    flags := TreeFlags
    {
      it.focused  = manFocus
      it.selected = selected
    }
    content.style->paddingLeft = "${node.depth*20}px"
    node.onElem(content.lastChild, flags)

    // add children if expanded
    if (node.expanded)
    {
      node.children.each |k|
      {
        node.elem.add(toElem(node, k))
        doRefreshNode(k)
      }
    }
  }

  ** Map TreeNode to DOM element.
  private Elem toElem(TreeNode? parent, TreeNode node)
  {
    if (node.elem == null)
    {
      node.depth = parent==null ? 0 : parent.depth+1
      node.elem = Elem
      {
        it.style.addClass("domkit-Tree-node-block")
        Elem {
          it.style.addClass("domkit-Tree-node")
          Elem { it.style.addClass("domkit-Tree-node-expander") },
          Elem {},
        },
      }
      refreshNode(node)
    }
    return node.elem
  }

  ** Map DOM element to TreeNode.
  private TreeNode toNode(Elem elem)
  {
    // bubble to block elem
    while (!elem.style.hasClass("domkit-Tree-node-block")) elem = elem.parent

    // find dom path
    elemPath := Elem[elem]
    while (!elemPath.first.parent.style.hasClass("domkit-Tree"))
      elemPath.insert(0, elemPath.first.parent)

    // walk path from roots
    TreeNode? node
    elemPath.each |p|
    {
      i := p.parent.children.findIndex |k| { p == k }
      node = node==null ? roots[i] : node.children[i-1]
    }

    return node
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  private Void handleMouseUp(Event e)
  {
    elem := e.target
    if (elem == this) return
    node := toNode(elem)

    if (elem.style.hasClass("domkit-Tree-node-expander"))
    {
      // expand node
      expand(node, !node.expanded)
    }
    else
    {
      // short-circuit if already selected
      if (sel.items.contains(node)) return

      // update selection
      sel.item = node
      cbSelect?.call(this)
    }
  }

  private Void handleMouseDoubleClick(Event e)
  {
    elem := e.target
    if (elem == this) return
    node := toNode(elem)
    cbAction?.call(this, e)
  }

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

  internal Void onUpdateSel(TreeNode[] oldNodes, TreeNode[] newNodes)
  {
    oldNodes.each |n| { refreshNode(n) }
    newNodes.each |n| { refreshNode(n) }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private TreeNode[] nodes := [,]
  private Func? cbSelect
  private Func? cbAction

  // focus/blur
  private Bool manFocus := false
}

**************************************************************************
** TreeSelection
**************************************************************************

@Js internal class TreeSelection : Selection
{
  new make(Tree tree) { this.tree = tree }

  override Bool isEmpty() { items.isEmpty }

  override Int size() { items.size }

  override Obj? item
  {
    get { items.first }
    set { items = (it == null) ? Obj[,] : [it] }
  }

  override Obj[] items := [,]
  {
    set
    {
      if (!enabled) return
      oldItems := &items
      newItems := (multi ? it : (it.size > 0 ? [it.first] : Obj[,])).ro
      &items = newItems
      tree.onUpdateSel(oldItems, newItems)
    }
  }

  // TODO: unless we can make index meaningful/useful and performant
  // its probably better to fail fast so its not used

  override Int? index
  {
    get { throw Err("Not implemented for Tree") }
    set { throw Err("Not implemented for Tree") }
  }

  override Int[] indexes
  {
    get { throw Err("Not implemented for Tree") }
    set { throw Err("Not implemented for Tree") }
  }

  private Tree tree
}