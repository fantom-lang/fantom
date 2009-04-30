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

public class FwtEnvPeer
{
  static final FwtEnvPeer singleton = new FwtEnvPeer();

  public static FwtEnvPeer make(fan.fwt.FwtEnv self)
  {
    return singleton;
  }

  public long fontHeight(fan.fwt.FwtEnv self, fan.gfx.Font f)
  {
    return scratchGC(f).getFontMetrics().getHeight();
  }

  public long fontAscent(fan.fwt.FwtEnv self, fan.gfx.Font f)
  {
    return scratchGC(f).getFontMetrics().getAscent();
  }

  public long fontDescent(fan.fwt.FwtEnv self, fan.gfx.Font f)
  {
    return scratchGC(f).getFontMetrics().getDescent();
  }

  public long fontLeading(fan.fwt.FwtEnv self, fan.gfx.Font f)
  {
    return scratchGC(f).getFontMetrics().getLeading();
  }

  public long fontWidth(fan.fwt.FwtEnv self, fan.gfx.Font f, String s)
  {
    return scratchGC(f).textExtent(s).x;
  }

  private GC scratchGC(fan.gfx.Font f)
  {
    Env env = Env.get();
    GC gc = env.scratchGC();
    gc.setFont(env.font(f));
    return gc;
  }

}