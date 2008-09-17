//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
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

  public static Str platform()
  {
    if (Env.isWindows()) return windows;
    if (Env.isMac()) return mac;
    return Str.make(SWT.getPlatform());
  }
  static final Str windows = Str.make("windows");
  static final Str mac = Str.make("mac");

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

  public static void callAsync(final Func func)
  {
    // check if running on UI thread
    Env env = Env.main();
    if (java.lang.Thread.currentThread() != env.display.getThread())
    {
      if (!func.isImmutable().val)
        throw NotImmutableErr.make("callAsync func must be immutable if not on UI thread").val;
    }

    // enqueue on main UI thread's display
    env.display.asyncExec(new Runnable()
    {
      public void run()
      {
        try
        {
          func.call0();
        }
        catch (Throwable e)
        {
          e.printStackTrace();
        }
      }
    });
  }

}