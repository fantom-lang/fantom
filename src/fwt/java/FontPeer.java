//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.graphics.GC;

public class FontPeer
{
  static final FontPeer singleton = new FontPeer();

  public static FontPeer make(fan.fwt.Font self)
  {
    return singleton;
  }

  public Int height(fan.fwt.Font self)
  {
    return Int.make(scratchGC(self).getFontMetrics().getHeight());
  }

  public Int ascent(fan.fwt.Font self)
  {
    return Int.make(scratchGC(self).getFontMetrics().getAscent());
  }

  public Int descent(fan.fwt.Font self)
  {
    return Int.make(scratchGC(self).getFontMetrics().getDescent());
  }

  public Int leading(fan.fwt.Font self)
  {
    return Int.make(scratchGC(self).getFontMetrics().getLeading());
  }

  public Int width(fan.fwt.Font self, Str s)
  {
    return Int.make(scratchGC(self).textExtent(s.val).x);
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

}