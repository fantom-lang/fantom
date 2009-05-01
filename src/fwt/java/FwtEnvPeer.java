//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.gfx.Size;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.FontData;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.Rectangle;

public class FwtEnvPeer
{
  static final FwtEnvPeer singleton = new FwtEnvPeer();

  public static FwtEnvPeer make(fan.fwt.FwtEnv self)
  {
    return singleton;
  }

//////////////////////////////////////////////////////////////////////////
// Image Support
//////////////////////////////////////////////////////////////////////////

  public Size imageSize(FwtEnv self, fan.gfx.Image f)
  {
    Image x = Env.get().image(f);
    if (x == null) return Size.defVal;
    Rectangle r = x.getBounds();
    return Size.make(r.width, r.height);
  }

  public fan.gfx.Image imageResize(FwtEnv self, fan.gfx.Image f, fan.gfx.Size size)
  {
    int rw = (int)size.w;
    int rh = (int)size.h;

    // get SWT image
    Env env = Env.get();
    Image s = env.image(f);
    if (s == null) throw Err.make("Image not valid or not loaded yet").val;

    // if image already matches requested resize, return it
    Rectangle sbounds = s.getBounds();
    int sw = sbounds.width;
    int sh = sbounds.height;
    if (rw == sw && rh == sw) return f;

    // create new SWT image
    // TODO: this doesn't handle transparency
    ImageData sdata = s.getImageData();
    ImageData rdata = new ImageData(rw, rh, sdata.depth, sdata.palette);
    rdata.transparentPixel = sdata.transparentPixel; // this don't work
    Image resultSwt = new Image(env.display, rdata);

    // paint new SWT image
    GC gc = new GC(resultSwt);
    Color bg = resultSwt.getBackground();
    if (bg == null) bg = env.display.getSystemColor(SWT.COLOR_WHITE);
    gc.setBackground(bg);
    gc.fillRectangle(0, 0, rw, rh);
    gc.drawImage(s, 0, 0, sw, sh, 0, 0, rw, rh);
    gc.dispose();

    // return new gfx::Image backed by new SWT image
    Uri uri = Uri.fromStr("mem-" + Uuid.make());
    fan.gfx.Image resultFan = fan.gfx.Image.makeUri(uri);
    env.images.put(uri, resultSwt);
    return resultFan;
  }

//////////////////////////////////////////////////////////////////////////
// Font Support
//////////////////////////////////////////////////////////////////////////

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