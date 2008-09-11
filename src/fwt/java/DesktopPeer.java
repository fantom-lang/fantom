//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Widget;

public class DesktopPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer
//////////////////////////////////////////////////////////////////////////

  public static DesktopPeer make(Desktop self)
  {
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Native methods
//////////////////////////////////////////////////////////////////////////

  public static Bool isWindows()
  {
    return Bool.make(Env.isWindows());
  }

  public static Bool isMac()
  {
    return Bool.make(Env.isMac());
  }

  public static Rect bounds()
  {
    return WidgetPeer.rect(Env.get().display.getBounds());
  }

  public static fan.fwt.Widget focus()
  {
    return WidgetPeer.toFanWidget(Env.get().display.getFocusControl());
  }

}