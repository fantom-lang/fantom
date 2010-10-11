//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import fan.gfx.*;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Monitor;
import org.eclipse.swt.widgets.Widget;

public class MonitorPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static MonitorPeer make(fan.fwt.Monitor self)
  {
    return new MonitorPeer();
  }

  static fan.fwt.Monitor make(Monitor swt)
  {
    fan.fwt.Monitor self = fan.fwt.Monitor.make();
    self.peer.swt = swt;
    return self;
  }

//////////////////////////////////////////////////////////////////////////
// Native methods
//////////////////////////////////////////////////////////////////////////

  public static List list()
  {
    return Fwt.get().monitors();
  }

  public static fan.fwt.Monitor primary()
  {
    return Fwt.get().primaryMonitor();
  }

  public Rect bounds(fan.fwt.Monitor self)
  {
    return WidgetPeer.rect(swt.getClientArea());
  }

  public Rect screenBounds(fan.fwt.Monitor self)
  {
    return WidgetPeer.rect(swt.getBounds());
  }

  public Size dpi(fan.fwt.Monitor self)
  {
    return WidgetPeer.size(Fwt.get().display.getDPI());
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Monitor swt;

}