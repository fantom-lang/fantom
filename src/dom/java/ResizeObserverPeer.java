//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Nov 2026  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

/**
 * ResizeObserverPeer never calls back: nothing is laid out, so no
 * element has a size to change.
 */
public class ResizeObserverPeer
{
  public static ResizeObserverPeer make(ResizeObserver fan)
  {
    return DomPeerFactory.factory().makeResizeObserver(fan);
  }

  public ResizeObserver observe(ResizeObserver self, Elem target) { return self; }

  public ResizeObserver unobserve(ResizeObserver self, Elem target) { return self; }

  public ResizeObserver disconnect(ResizeObserver self) { return self; }
}
