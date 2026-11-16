//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 2026  Brian Frank  Creation
//

/*
 * DomNodePeer is the base peer of every DomNode subclass.  A Fantom
 * object has one peer, so each subclass peer extends this class:
 * ElemPeer, DomTextPeer, DocPeer, and DomFragPeer.  The peer holds
 * the native DOM node in `node`; ElemPeer and DocPeer alias it as
 * `elem` and `doc` for existing natives.
 *
 * Each native node maps to exactly one Fantom wrapper, cached on the
 * native node as `_fanNode`.  All wrapping goes thru `wrap` so the
 * wrapper type always follows the native node type; the one exception
 * is Event.target, which gives a window or document target an uncached
 * Elem wrapper.
 */
class DomNodePeer extends sys.Obj {

  constructor(self) { super(); }

  /*
   * Native only method to wrap an existing DOM node.  If this node
   * has already been wrapped, return the existing instance.  If
   * fanNode is omitted then create an Elem, DomText, Doc, DomFrag,
   * or plain DomNode based on the node type.
   */
  static wrap = function(node, fanNode)
  {
    if (!node) throw sys.ArgErr.make("node is null")

    if (node._fanNode != undefined)
      return node._fanNode;

    if (fanNode && !(fanNode instanceof DomNode))
      throw sys.ArgErr.make("Type does not subclass DomNode: " + fanNode);

    const x = fanNode || DomNodePeer.#make(node.nodeType);
    x.peer.bind(x, node);
    return x;
  }

  /* Construct a wrapper without its make, which creates a native node */
  static #make(nodeType)
  {
    switch (nodeType)
    {
      case 1:  return new Elem();
      case 3:  return new DomText();
      case 9:  return new Doc();
      case 11: return new DomFrag();
      default: return new DomNode();
    }
  }

  /* Native document of the current window */
  static doc() { return Win.cur().doc().peer.node; }

  /* Bind this peer and its Fantom node to a native node */
  bind(self, node)
  {
    this.node = node;
    node._fanNode = self;
  }

  /* Wrap a native node, or return null if node is null */
  static wrapOrNull(node) { return node == null ? null : DomNodePeer.wrap(node); }

//////////////////////////////////////////////////////////////////////////
// Accessors
//////////////////////////////////////////////////////////////////////////

  text(self, it)
  {
    if (it === undefined) return this.node.textContent ?? "";
    else this.node.textContent = it;
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  parentNode(self) { return DomNodePeer.wrapOrNull(this.node.parentNode); }

  parent(self) { return DomNodePeer.wrapOrNull(this.node.parentElement); }

  childNodes(self)
  {
    const kids = this.node.childNodes;
    const list = new Array(kids.length);
    for (let i=0; i<kids.length; i++) list[i] = DomNodePeer.wrap(kids[i]);
    return sys.List.make(DomNode.type$, list);
  }

  firstNode(self) { return DomNodePeer.wrapOrNull(this.node.firstChild); }

  lastNode(self) { return DomNodePeer.wrapOrNull(this.node.lastChild); }

  prevNode(self) { return DomNodePeer.wrapOrNull(this.node.previousSibling); }

  nextNode(self) { return DomNodePeer.wrapOrNull(this.node.nextSibling); }

  containsChild(self, test) { return this.node.contains(test.peer.node); }

  clone(self, deep) { return DomNodePeer.wrap(this.node.cloneNode(deep)); }

  addChild(self, child) { this.node.appendChild(child.peer.node); }

  insertChildBefore(self, child, ref) { this.node.insertBefore(child.peer.node, ref.peer.node); }

  replaceChild(self, oldChild, newChild) { this.node.replaceChild(newChild.peer.node, oldChild.peer.node); }

  removeChild(self, child) { this.node.removeChild(child.peer.node); }

  removeAllChildren(self) { this.node.replaceChildren(); }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  onEvent(self, type, useCapture, handler)
  {
    handler.$func = function(e) { handler(EventPeer.make(e)); }
    this.node.addEventListener(type, handler.$func, useCapture);
    return handler;
  }

  removeEvent(self, type, useCapture, handler)
  {
    if (handler.$func)
      this.node.removeEventListener(type, handler.$func, useCapture);
  }

  dispatchEvent(self, event)
  {
    return this.node.dispatchEvent(event.peer.event);
  }
}
