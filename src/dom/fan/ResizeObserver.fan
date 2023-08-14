//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2022  Andy Frank  Creation
//

using graphics
using web

**************************************************************************
** ResizeObserver
**************************************************************************

** ResizeObserver invokes a callback when Elem size is changed.
@Js class ResizeObserver
{
  ** Create a new ResizeObserver instance.
  new make() {}

  ** Register to receive resize events for given node.
  native This observe(Elem target)

  ** Stop receiving resize events for given node.
  native This unobserve(Elem target)

  ** Disconnect this observer from all resize events for all nodes.
  native This disconnect()

  ** Callback when an observed target size has been modified.
  Void onResize(|ResizeObserverEntry[] entries| callback)
  {
    this.callback = callback
  }

  @NoDoc
  internal Func? callback
}

*************************************************************************
** ResizeObserverEntry
*************************************************************************

** ResizeObserverEntry models a resize event for `ResizeObserver`.
@Js class ResizeObserverEntry
{
  ** It-block ctor invoked from ResizeObserverPeer.
  internal new make(|This|? f := null) { if (f != null) f(this) }

  ** Elem that has been resized.
  Elem target { private set }

  ** New size of `target` element.
  const Size size

  override Str toStr()
  {
    "ResizeObserverEntry { target=${target} size=${size} }"
  }
}