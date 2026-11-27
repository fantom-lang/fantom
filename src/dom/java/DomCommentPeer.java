//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 2026  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class DomCommentPeer extends DomNodePeer
{
  public static DomCommentPeer make(DomComment fan)
  {
    DomCommentPeer peer = DomPeerFactory.factory().makeDomComment(fan);
    ((DomNode)fan).peer = peer; // override base class's peer field
    return peer;
  }

  public void _make(DomComment self, String text) { this.text = text; }
}
