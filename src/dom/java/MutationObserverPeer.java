//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Nov 2026  Brian Frank  Creation
//

package fan.dom;

import java.util.ArrayList;
import fan.sys.*;

/**
 * MutationObserverPeer is the JVM implementation of MutationObserver.
 * It records changes to the nodes it observes.  A browser delivers the
 * records asynchronously; here they are delivered by `Win.runTimers`
 * or returned by `takeRecs`.
 */
public class MutationObserverPeer
{

//////////////////////////////////////////////////////////////////////////
// Natives
//////////////////////////////////////////////////////////////////////////

  public static MutationObserverPeer make(MutationObserver fan)
  {
    return new MutationObserverPeer();
  }

  public MutationObserver observe(MutationObserver self, DomNode target, Map opts)
  {
    Reg reg = new Reg(self, opts);
    if (!reg.childList && !reg.attrs && !reg.charData)
      throw ArgErr.make("Must observe one of childList, attrs or charData");

    // observing the same node again replaces its options
    unobserve(self, target);
    target.peer.observers.add(reg);
    targets.add(target);
    active.incrementAndGet();
    return self;
  }

  public List takeRecs(MutationObserver self)
  {
    List recs = List.make(Type.find("dom::MutationRec"), queue);
    queue.clear();
    return recs;
  }

  public MutationObserver disconnect(MutationObserver self)
  {
    Object[] all = targets.toArray();
    for (int i=0; i<all.length; i++) unobserve(self, (DomNode)all[i]);
    queue.clear();
    return self;
  }

  private void unobserve(MutationObserver self, DomNode target)
  {
    ArrayList regs = target.peer.observers;
    for (int i=0; i<regs.size(); i++)
    {
      if (((Reg)regs.get(i)).observer != self) continue;
      regs.remove(i);
      targets.remove(target);
      active.decrementAndGet();
      return;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Record
//////////////////////////////////////////////////////////////////////////

  // Return if any observer is registered.  Mutations use this to skip
  // the work of building a record when nobody is observing
  static boolean isActive() { return active.get() > 0; }

  // Record that a child was added to or removed from a node.  The
  // prev and next nodes are the siblings on either side of the change
  static void childList(DomNode target, DomNode added, DomNode removed, DomNode prev, DomNode next)
  {
    if (!isActive()) return;
    DomNode[] a = added == null ? new DomNode[0] : new DomNode[] { added };
    DomNode[] r = removed == null ? new DomNode[0] : new DomNode[] { removed };
    record(target, "childList", null, null, a, r, prev, next);
  }

  // Record that all children of a node were removed
  static void childrenRemoved(DomNode target, Object[] removed)
  {
    if (!isActive() || removed.length == 0) return;
    DomNode[] r = new DomNode[removed.length];
    System.arraycopy(removed, 0, r, 0, r.length);
    record(target, "childList", null, null, new DomNode[0], r, null, null);
  }

  // Record that an attribute was set or removed
  static void attr(DomNode target, String name, String oldVal)
  {
    if (!isActive()) return;
    record(target, "attrs", name, oldVal, new DomNode[0], new DomNode[0], null, null);
  }

  // Record that the text of a text node changed
  static void charData(DomNode target, String oldVal)
  {
    if (!isActive()) return;
    record(target, "charData", null, oldVal, new DomNode[0], new DomNode[0], null, null);
  }

  // Queue a record for every observer of the target, and for every
  // observer of an ancestor which is observing its subtree
  private static void record(DomNode target, String type, String attr, String oldVal,
                             DomNode[] added, DomNode[] removed, DomNode prev, DomNode next)
  {
    for (DomNode n = target; n != null; n = n.peer.parentNode)
    {
      ArrayList regs = n.peer.observers;
      for (int i=0; i<regs.size(); i++)
      {
        Reg reg = (Reg)regs.get(i);
        if (n != target && !reg.subtree) continue;
        if (!reg.takes(type, attr)) continue;

        MutationRec rec = new MutationRec();   // make checks the fields set here
        rec.type(type);
        rec.target(target);
        rec.added(List.make(Type.find("dom::DomNode"), added));
        rec.removed(List.make(Type.find("dom::DomNode"), removed));
        rec.prevSibling(prev);
        rec.nextSibling(next);
        rec.attr(attr);
        if (reg.oldVal(type)) rec.oldVal(oldVal);

        MutationObserverPeer peer = reg.observer.peer;
        peer.queue.add(rec);
        ArrayList pending = WinPeer.curPeer().pendingObservers;
        if (!pending.contains(reg.observer)) pending.add(reg.observer);
      }
    }
  }

  // Invoke the callback of every observer which has queued records
  static void deliver(WinPeer win)
  {
    while (win.pendingObservers.size() > 0)
    {
      MutationObserver observer = (MutationObserver)win.pendingObservers.remove(0);
      List recs = observer.peer.takeRecs(observer);
      if (recs.sz() > 0 && observer.callback() != null) observer.callback().call(recs);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Reg
//////////////////////////////////////////////////////////////////////////

  // Registration of an observer on one node with its options
  static class Reg
  {
    Reg(MutationObserver observer, Map opts)
    {
      this.observer       = observer;
      this.childList      = flag(opts, "childList");
      this.attrs          = flag(opts, "attrs");
      this.charData       = flag(opts, "charData");
      this.subtree        = flag(opts, "subtree");
      this.attrOldVal     = flag(opts, "attrOldVal");
      this.charDataOldVal = flag(opts, "charDataOldVal");
      this.attrFilter     = (List)opts.get("attrFilter");
    }

    private static boolean flag(Map opts, String name) { return Boolean.TRUE.equals(opts.get(name)); }

    boolean takes(String type, String attr)
    {
      if (type.equals("childList")) return childList;
      if (type.equals("charData")) return charData;
      return attrs && (attrFilter == null || attrFilter.contains(attr));
    }

    boolean oldVal(String type) { return type.equals("attrs") ? attrOldVal : (type.equals("charData") && charDataOldVal); }

    final MutationObserver observer;
    final boolean childList;
    final boolean attrs;
    final boolean charData;
    final boolean subtree;
    final boolean attrOldVal;
    final boolean charDataOldVal;
    final List attrFilter;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final java.util.concurrent.atomic.AtomicInteger active = new java.util.concurrent.atomic.AtomicInteger();   // registrations of every observer
  private final ArrayList targets = new ArrayList();    // DomNode
  private final ArrayList queue = new ArrayList();      // MutationRec
}
