//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 2026  Brian Frank  Creation
//

package fan.dom;

import java.util.ArrayList;
import fan.sys.*;
import fanx.interop.*;

public class DomNodePeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static DomNodePeer make(DomNode fan)
  {
    return DomPeerFactory.factory().makeDomNode(fan);
  }

//////////////////////////////////////////////////////////////////////////
// Accessors
//////////////////////////////////////////////////////////////////////////

  public String text(DomNode self) { return this.text; }
  public void text(DomNode self, String text)
  {
    String old = this.text;
    this.text = text;
    if (self instanceof DomText) MutationObserverPeer.charData(self, old);
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  public DomNode parentNode(DomNode self) { return this.parentNode; }

  public Elem parent(DomNode self) { return parentNode instanceof Elem ? (Elem)parentNode : null; }

  public List childNodes(DomNode self) { return Interop.toFan(kids, Type.find("dom::DomNode")); }

  public DomNode firstNode(DomNode self) { return kids.size() == 0 ? null : (DomNode)kids.get(0); }

  public DomNode lastNode(DomNode self) { return kids.size() == 0 ? null : (DomNode)kids.get(kids.size()-1); }

  public DomNode prevNode(DomNode self) { return sibling(self, -1); }

  public DomNode nextNode(DomNode self) { return sibling(self, 1); }

  private DomNode sibling(DomNode self, int delta)
  {
    if (parentNode == null) return null;
    ArrayList sibs = parentNode.peer.kids;
    int i = sibs.indexOf(self) + delta;
    return i < 0 || i >= sibs.size() ? null : (DomNode)sibs.get(i);
  }

  ArrayList elemKids()
  {
    ArrayList acc = new ArrayList();
    for (int i=0; i<kids.size(); i++)
      if (kids.get(i) instanceof Elem) acc.add(kids.get(i));
    return acc;
  }

  // Walk up from the node instead of searching every descendant
  public boolean containsChild(DomNode self, DomNode node)
  {
    for (DomNode n = node; n != null; n = n.peer.parentNode)
      if (n == self) return true;
    return false;
  }

  // Clone a node like the DOM does.  An element keeps its attributes,
  // classes and inline styles, but not its listeners or properties
  public DomNode clone(DomNode self, boolean deep)
  {
    DomNode copy = cloneSelf(self);
    if (deep)
      for (int i=0; i<kids.size(); i++) copy.peer.addChild(copy, ((DomNode)kids.get(i)).clone(true));
    return copy;
  }

  private static DomNode cloneSelf(DomNode self)
  {
    if (self instanceof DomText) return DomText.make(self.text());
    if (self instanceof DomFrag) return DomFrag.make();
    if (!(self instanceof Elem)) throw UnsupportedErr.make("clone " + self.typeof());
    Elem elem = (Elem)self;
    Elem copy = Elem.make(elem.tagName(), elem.ns());
    Map attrs = elem.attrs();
    List names = attrs.keys();
    for (int i=0; i<names.sz(); i++) copy.setAttr((String)names.get(i), (String)attrs.get(names.get(i)));
    copy.style().peer.props.putAll(elem.style().peer.props);
    return copy;
  }

  public void addChild(DomNode self, DomNode child)
  {
    if (child.parentNode() != null) throw new RuntimeException("child already parented");
    child.peer.parentNode = self;
    kids.add(child);
    MutationObserverPeer.childList(self, child, null, child.prevNode(), null);
  }

  public void insertChildBefore(DomNode self, DomNode child, DomNode ref)
  {
    if (child.parentNode() != null) throw new RuntimeException("child already parented");
    int i = kids.indexOf(ref);
    if (i < 0) throw new RuntimeException("ref not a child of this node");
    child.peer.parentNode = self;
    kids.add(i, child);
    MutationObserverPeer.childList(self, child, null, child.prevNode(), ref);
  }

  public void replaceChild(DomNode self, DomNode oldChild, DomNode newChild)
  {
    if (oldChild == newChild) return;
    if (newChild.parentNode() != null) throw new RuntimeException("child already parented");
    int i = kids.indexOf(oldChild);
    if (i < 0) throw new RuntimeException("oldChild not a child of this node");
    oldChild.peer.parentNode = null;
    newChild.peer.parentNode = self;
    kids.set(i, newChild);
    removed(self);
    MutationObserverPeer.childList(self, newChild, oldChild, newChild.prevNode(), newChild.nextNode());
  }

  public void removeChild(DomNode self, DomNode child)
  {
    int i = kids.indexOf(child);
    if (i < 0) return;
    child.peer.parentNode = null;
    kids.remove(i);
    removed(self);
    MutationObserverPeer.childList(self, null, child, i == 0 ? null : (DomNode)kids.get(i-1), i < kids.size() ? (DomNode)kids.get(i) : null);
  }

  // Nodes were removed from under a node.  If that took an open
  // popover out of the document, close it as a browser does
  private static void removed(DomNode parent)
  {
    DocPeer doc = DocPeer.of(parent);
    if (doc != null && doc.popovers.size() > 0) DomFuncs.closeRemoved(doc);
  }

  public void removeAllChildren(DomNode self)
  {
    Object[] removed = kids.toArray();
    for (int i=0; i<removed.length; i++) ((DomNode)removed[i]).peer.parentNode = null;
    kids.clear();
    removed(self);
    MutationObserverPeer.childrenRemoved(self, removed);
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  public Func onEvent(DomNode self, String type, boolean useCapture, Func handler)
  {
    listeners.add(new Listener(type, useCapture, handler));
    return handler;
  }

  public void removeEvent(DomNode self, String type, boolean useCapture, Func handler)
  {
    for (int i=0; i<listeners.size(); i++)
      if (((Listener)listeners.get(i)).matches(type, useCapture, handler)) { listeners.remove(i); return; }
  }

  // Dispatch an event like the DOM does: capture from the root down
  // to the target, fire the target's listeners, then bubble back up
  // if the event bubbles.  If the node is in a document then the
  // window is at the top of the path
  public boolean dispatchEvent(DomNode self, Event event)
  {
    EventPeer e = event.peer;
    e.target = self;

    ArrayList path = new ArrayList();
    for (DomNode p = parentNode; p != null; p = p.peer.parentNode) path.add(p);
    DocPeer doc = DocPeer.of(self);
    WinPeer win = doc == null ? null : doc.win.peer;

    if (win != null) win.fire(event, Boolean.TRUE);
    for (int i=path.size()-1; i>=0; i--) ((DomNode)path.get(i)).peer.fire(event, Boolean.TRUE);
    fire(event, null);
    if (e.bubbles)
    {
      for (int i=0; i<path.size(); i++) ((DomNode)path.get(i)).peer.fire(event, Boolean.FALSE);
      if (win != null) win.fire(event, Boolean.FALSE);
    }

    return !(e.cancelable && e.defaultPrevented);
  }

  // Fire the listeners of this node for the phase: capture, bubble,
  // or null for both at the target
  private void fire(Event event, Boolean capture) { fire(listeners, event, capture); }

  static void fire(ArrayList listeners, Event event, Boolean capture)
  {
    if (event.peer.stopped) return;
    Object[] snapshot = listeners.toArray();
    for (int i=0; i<snapshot.length; i++)
    {
      Listener x = (Listener)snapshot[i];
      if (!x.type.equals(event.peer.type)) continue;
      if (capture != null && capture.booleanValue() != x.capture) continue;
      x.handler.call(event);
    }
  }

  static class Listener
  {
    Listener(String type, boolean capture, Func handler) { this.type = type; this.capture = capture; this.handler = handler; }
    boolean matches(String t, boolean c, Func h) { return type.equals(t) && capture == c && handler == h; }
    final String type;
    final boolean capture;
    final Func handler;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  DomNode parentNode;                 // null
  ArrayList kids = new ArrayList();   // DomNode
  ArrayList listeners = new ArrayList();  // Listener
  ArrayList observers = new ArrayList();  // MutationObserverPeer.Reg
  String text = "";                   // non-null
}
