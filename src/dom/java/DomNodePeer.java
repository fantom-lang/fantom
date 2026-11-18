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
  public void text(DomNode self, String text) { this.text = text; }

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

  public boolean containsChild(DomNode self, DomNode node)
  {
    if (self == node) return true;
    for (int i=0; i<kids.size(); i++)
      if (((DomNode)kids.get(i)).containsChild(node)) return true;
    return false;
  }

  public DomNode clone(DomNode self, boolean deep) { throw UnsupportedErr.make(); }

  public void addChild(DomNode self, DomNode child)
  {
    if (child.parentNode() != null) throw new RuntimeException("child already parented");
    child.peer.parentNode = self;
    kids.add(child);
  }

  public void insertChildBefore(DomNode self, DomNode child, DomNode ref)
  {
    if (child.parentNode() != null) throw new RuntimeException("child already parented");
    int i = kids.indexOf(ref);
    if (i < 0) throw new RuntimeException("ref not a child of this node");
    child.peer.parentNode = self;
    kids.add(i, child);
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
  }

  public void removeChild(DomNode self, DomNode child)
  {
    child.peer.parentNode = null;
    kids.remove(child);
  }

  public void removeAllChildren(DomNode self)
  {
    for (int i=0; i<kids.size(); i++) ((DomNode)kids.get(i)).peer.parentNode = null;
    kids.clear();
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

  // Dispatch as the DOM does: capture down from the root, the
  // target's own listeners, then bubble back up if the event bubbles
  public boolean dispatchEvent(DomNode self, Event event)
  {
    EventPeer e = event.peer;
    e.target = self;

    ArrayList path = new ArrayList();
    for (DomNode p = parentNode; p != null; p = p.peer.parentNode) path.add(p);

    for (int i=path.size()-1; i>=0; i--) ((DomNode)path.get(i)).peer.fire(event, Boolean.TRUE);
    fire(event, null);
    if (e.bubbles)
      for (int i=0; i<path.size(); i++) ((DomNode)path.get(i)).peer.fire(event, Boolean.FALSE);

    return !(e.cancelable && e.defaultPrevented);
  }

  // Fire the listeners of this node for the phase: capture, bubble,
  // or null for both at the target
  private void fire(Event event, Boolean capture)
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
  String text = "";                   // non-null
}
