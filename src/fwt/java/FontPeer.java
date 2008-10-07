//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.FontData;
import org.eclipse.swt.graphics.GC;

public class FontPeer
{
  static final FontPeer singleton = new FontPeer();

  public static FontPeer make(fan.fwt.Font self)
  {
    return singleton;
  }

  public Long height(fan.fwt.Font self)
  {
    return Long.valueOf(scratchGC(self).getFontMetrics().getHeight());
  }

  public Long ascent(fan.fwt.Font self)
  {
    return Long.valueOf(scratchGC(self).getFontMetrics().getAscent());
  }

  public Long descent(fan.fwt.Font self)
  {
    return Long.valueOf(scratchGC(self).getFontMetrics().getDescent());
  }

  public Long leading(fan.fwt.Font self)
  {
    return Long.valueOf(scratchGC(self).getFontMetrics().getLeading());
  }

  public Long width(fan.fwt.Font self, String s)
  {
    return Long.valueOf(scratchGC(self).textExtent(s).x);
  }

  private GC scratchGC(fan.fwt.Font self)
  {
    Env env = Env.get();
    GC gc = env.scratchGC();
    gc.setFont(env.font(self));
    return gc;
  }

  public void dispose(fan.fwt.Font f)
  {
    Env.get().dispose(f);
  }

  public static fan.fwt.Font sys()
  {
    if (sys == null)
    {
      FontData data = Env.get().display.getSystemFont().getFontData()[0];
      sys = fan.fwt.Font.make(data.getName(), Long.valueOf(data.getHeight()));
    }
    return sys;
  }
  private static fan.fwt.Font sys;

  public static fan.fwt.Font sysMonospace()
  {
    if (sysMonospace == null)
    {
      String name = "Courier New"; int size = 9;
      if (Env.isMac()) { name = "Monaco"; size = 12; }
      sysMonospace = fan.fwt.Font.make(name, Long.valueOf(size));
    }
    return sysMonospace;
  }
  private static fan.fwt.Font sysMonospace;

}