//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.gfx.*;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.Rectangle;

public class ImagePeer
{
  public static ImagePeer make(fan.fwt.Image self)
  {
    return new ImagePeer();
  }

  public ImagePeer() {}
  public ImagePeer(Image swt) { this.swt = swt; }

  public Size size(fan.fwt.Image f)
  {
    Image x = Env.get().image(f);
    if (x == null) return Size.defVal;
    Rectangle r = x.getBounds();
    return Size.make(r.width, r.height);
  }

  public fan.fwt.Image resize(fan.fwt.Image f, fan.gfx.Size size)
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

    // return new Fan MemImage backed by new SWT image
    fan.fwt.Image resultFan = MemImage.internalMake();
    resultFan.peer = new ImagePeer(resultSwt);
    return resultFan;
  }

  public void dispose(fan.fwt.Image f)
  {
    Env.get().dispose(f);
  }
  Image swt;

}