//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 2026  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class DomFragPeer extends DomNodePeer
{
  public static DomFragPeer make(DomFrag fan)
  {
    DomFragPeer peer = DomPeerFactory.factory().makeDomFrag(fan);
    ((DomNode)fan).peer = peer; // override base class's peer field
    return peer;
  }

  public void _make(DomFrag self) {}
}
