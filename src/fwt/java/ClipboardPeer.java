//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 11  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.dnd.*;

public class ClipboardPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer
//////////////////////////////////////////////////////////////////////////

  public static ClipboardPeer make(Clipboard self)
  {
    return new ClipboardPeer();
  }

  ClipboardPeer()
  {
    this.swt = new org.eclipse.swt.dnd.Clipboard(Fwt.get().display);
  }

//////////////////////////////////////////////////////////////////////////
// Native methods
//////////////////////////////////////////////////////////////////////////

  public String getText(Clipboard self)
  {
    return (String)swt.getContents(TextTransfer.getInstance());
  }

  public void setText(Clipboard self, String data)
  {
    swt.setContents(new String[]{data}, new Transfer[]{TextTransfer.getInstance()});
  }

  final org.eclipse.swt.dnd.Clipboard swt;

}