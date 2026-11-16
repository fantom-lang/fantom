//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 2026  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class DomTextPeer extends DomNodePeer
{
  public static DomTextPeer make(DomText fan)
  {
    DomTextPeer peer = DomPeerFactory.factory().makeDomText(fan);
    ((DomNode)fan).peer = peer; // override base class's peer field
    return peer;
  }

  public void _make(DomText self, String text) { this.text = text; }
}
