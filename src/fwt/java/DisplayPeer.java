//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.browser.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Widget;

public class DisplayPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer
//////////////////////////////////////////////////////////////////////////

  public static DisplayPeer make(fan.fwt.Display self)
  {
    return new DisplayPeer(Env.get());
  }

  DisplayPeer(Env env) { this.env = env; }

//////////////////////////////////////////////////////////////////////////
// Native methods
//////////////////////////////////////////////////////////////////////////

  public static fan.fwt.Display current()
  {
    Env env = Env.get();
    if (env.fanDisplay == null) env.fanDisplay = fan.fwt.Display.make();
    return env.fanDisplay;
  }

  public fan.fwt.Widget focus(fan.fwt.Display self)
  {
    return WidgetPeer.toFanWidget(env.display.getFocusControl());
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Env env;
}