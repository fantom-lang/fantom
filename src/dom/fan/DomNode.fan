//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 2026  Brian Frank  Creation
//

**
** DomNode models a DOM node object: the base class of [Elem] for
** elements, [DomText] for text nodes, [Doc] for documents, and
** [DomFrag] for document fragments.  Other node types such as
** comments are modeled directly as DomNode.
**
@Js
class DomNode
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  ** Internal constructor
  internal new make() {}

//////////////////////////////////////////////////////////////////////////
// Accessors
//////////////////////////////////////////////////////////////////////////

  ** Text content of this node and its descendants.  This is
  ** always empty string for a [Doc].
  native Str text

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  ** Get the parent node of this node which may be an element,
  ** document, or fragment.  Return null if this node has no parent.
  native DomNode? parentNode()

  ** Get the parent element of this node, or null if this node has
  ** no parent or its parent is not an element.
  native Elem? parent()

  ** Get all the child nodes of this node including text nodes.
  native DomNode[] childNodes()

  ** Get the first child node of this node including text
  ** nodes, or null if this node has no child nodes.
  native DomNode? firstNode()

  ** Get the last child node of this node including text
  ** nodes, or null if this node has no child nodes.
  native DomNode? lastNode()

  ** Get the previous sibling node including text nodes, or null
  ** if this is the first node under its parent.
  native DomNode? prevNode()

  ** Get the next sibling node including text nodes, or null
  ** if this is the last node under its parent.
  native DomNode? nextNode()

  ** Return `true` if given node is this node or a descendant
  ** of this node, or `false` if not.
  native Bool containsChild(DomNode node)

  ** Return a duplicate of this node.
  virtual native DomNode clone(Bool deep := true)

  ** Add a new node as a child to this node. Return this.
  @Operator virtual This add(DomNode child)
  {
    addChild(child)
    added(child)
    return this
  }

  ** Insert a new node as a child to this node before the
  ** specified reference node.  The reference node must
  ** be a child of this node. Returns this.
  virtual This insertBefore(DomNode child, DomNode ref)
  {
    insertChildBefore(child, ref)
    added(child)
    return this
  }

  ** Replace existing child node with a new child.  Returns this.
  virtual This replace(DomNode oldChild, DomNode newChild)
  {
    replaceChild(oldChild, newChild)
    removed(oldChild)
    added(newChild)
    return this
  }

  ** Remove a child node from this node. Return this.
  virtual This remove(DomNode child)
  {
    removeChild(child)
    removed(child)
    return this
  }

  ** Add all nodes to this node.  Returns this.
  This addAll(DomNode[] nodes)
  {
    nodes.each |n| { add(n) }
    return this
  }

  ** Remove all child nodes including text nodes.  Returns this.
  This removeAll()
  {
    kids := (this as Elem)?.children ?: Elem#.emptyList
    removeAllChildren
    kids.each |kid| { removed(kid) }
    return this
  }

  ** Add a new node as a child to this node.
  @NoDoc protected native Void addChild(DomNode child)

  ** Insert a new node as a child to this node before given node.
  @NoDoc protected native Void insertChildBefore(DomNode child, DomNode ref)

  ** Replace an existing child node with new node.
  @NoDoc protected native Void replaceChild(DomNode oldChild, DomNode newChild)

  ** Remove a child node from this node.
  @NoDoc protected native Void removeChild(DomNode child)

  ** Remove all child nodes from this node.
  @NoDoc protected native Void removeAllChildren()

  ** Fire the Elem add callbacks when both parent and child are elements
  private Void added(DomNode child)
  {
    parent := this as Elem
    kid := child as Elem
    if (parent == null || kid == null) return
    parent.onAdd(kid)
    kid.onParent(parent)
  }

  ** Fire the Elem remove callbacks when both parent and child are elements
  private Void removed(DomNode child)
  {
    parent := this as Elem
    kid := child as Elem
    if (parent == null || kid == null) return
    kid.onUnparent(parent)
    parent.onRemove(kid)
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Attach an event handler for the given event on this node.
  ** Returns callback function instance.
  native Func onEvent(Str type, Bool useCapture, |Event e| handler)

  ** Remove the given event handler from this node.  If this
  ** handler was not registered, this method does nothing.
  native Void removeEvent(Str type, Bool useCapture, Func handler)

  ** Dispatch an event such as one from `Event.makeCustom` to this
  ** node.  Return false if the event is cancelable and a handler
  ** called `Event.preventDefault`, otherwise true.
  native Bool dispatchEvent(Event event)
}
