//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 2016  Andy Frank  Creation
//

using concurrent
using dom

**
** DomListener monitors the DOM and invokes callbacks when modifications occur.
**
** DomListener works by registering a global
** [MutationObserver]`dom::MutationObserver` on the 'body' tag and collects
** all 'childList' events for his subtree.  All mutation events are queued and
** processed on a [reqAnimationFrame]`dom::Win.reqAnimationFrame`.  Registered
** nodes are held with weak references, and will be garbage collected when out
** of scope.
**
@Js class DomListener
{
  static DomListener cur()
  {
    r := Actor.locals["domkit.DomListener"] as DomListener
    if (r == null) Actor.locals["domkit.DomListener"] = r = DomListener()
    return r
  }

  ** Private ctor.
  private new make()
  {
    this.observer = MutationObserver() |recs| { checkMutations.addAll(recs) }
    this.observer.observe(Win.cur.doc.body, ["childList":true, "subtree":true])
    reqCheck
  }

  ** Request callback when target node is mounted into document.
  Void onMount(Elem target, |Elem| f)
  {
    DomState state := map.get(target) ?: DomState()
    state.onMount = f
    map.set(target, state)
  }

  ** Request callback when target node is unmounted from document.
  Void onUnmount(Elem target, |Elem| f)
  {
    DomState state := map.get(target) ?: DomState()
    state.onUnmount = f
    map.set(target, state)
  }

  ** Request callback when target node size has changed.
  Void onResize(Elem target, |Elem| f)
  {
    DomState state := map.get(target) ?: DomState()
    state.onResize = f
    map.set(target, state)
  }

  ** Request check callback.
  private Void reqCheck()
  {
    Win.cur.reqAnimationFrame |->| { onCheck }
  }

  ** Callback to check elements.
  private Void onCheck()
  {
    try
    {
      // throttle checks
      nowTicks := Duration.nowTicks
      if (lastTicks != null && nowTicks-lastTicks < checkFreq) return
      this.lastTicks = nowTicks

      // debug
      // start := Duration.now

      // check mount/unmount
      checkMutations.each |r,i|
      {
        checkState.clear
        r.added.each |e| { findRegNodes(e, checkState) }
        checkState.each |e|
        {
          DomState s := map[e]
          s.fireMount(e)
          mounted[e.hash] = e
        }

        checkState.clear
        r.removed.each |e| { findRegNodes(e, checkState) }
        checkState.each |e|
        {
          DomState s := map[e]
          s.fireUnmount(e)
          mounted.remove(e.hash)
        }
      }

      // make sure we cleanup refs
      checkMutations.clear
      checkState.clear

      // check for resize events
      mounted.each |e|
      {
        DomState s := map[e]
        if (s.onResize != null)
        {
          s.newSize = e.size
          if (s.lastSize == null) s.lastSize = s.newSize
          if (s.lastSize != s.newSize) s.fireResize(e)
          s.lastSize = s.newSize
        }
      }

      // debug
      // dur := Duration.now - start
      // echo("# DomListener.onCheck [${dur.toMillis}ms]")
    }
    catch (Err err) { err.trace }
    finally
    {
      reqCheck
    }
  }

  ** Walk subtree to find all registered nodes.
  private Void findRegNodes(Elem elem, Elem[] list)
  {
    if (map.has(elem)) list.add(elem)
    elem.children.each |c| { findRegNodes(c, list) }
  }

  private Int checkFreq := 1sec.ticks
  private Int? lastTicks

  private MutationObserver observer
  private WeakMap map := WeakMap()
  private Int:Elem mounted := [:]

  private MutationRec[] checkMutations := [,]
  private Elem[] checkState := [,]
}

**************************************************************************
** DomState
**************************************************************************

@Js internal class DomState
{
  Func? onMount   := null
  Func? onUnmount := null
  Func? onResize  := null

  Size? lastSize
  Size? newSize

  Void fireMount(Elem elem)
  {
    if (mounted) return
    mounted = true
    unmounted = false
    try { onMount?.call(elem) }
    catch (Err err) { err.trace }
  }

  Void fireUnmount(Elem elem)
  {
    if (unmounted) return
    mounted = false
    unmounted = true
    try { onUnmount?.call(elem) }
    catch (Err err) { err.trace }
  }

  Void fireResize(Elem elem)
  {
    try { onResize?.call(elem) }
    catch (Err err) { err.trace }
  }

  private Bool mounted   := false
  private Bool unmounted := true
}