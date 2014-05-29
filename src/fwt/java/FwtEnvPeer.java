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
import org.eclipse.swt.graphics.ImageLoader;
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
    Image x = Fwt.get().image(f);
    if (x == null) return Size.defVal;
    Rectangle r = x.getBounds();
    return Size.make(r.width, r.height);
  }

  public fan.gfx.Image imageResize(FwtEnv self, fan.gfx.Image f, fan.gfx.Size size)
  {
    int rw = (int)size.w;
    int rh = (int)size.h;

    // get SWT image
    Fwt fwt = Fwt.get();
    Image s = fwt.image(f);
    if (s == null) throw Err.make("Image not valid or not loaded yet");

    // if image already matches requested resize, return it
    Rectangle sbounds = s.getBounds();
    int sw = sbounds.width;
    int sh = sbounds.height;
    if (rw == sw && rh == sw) return f;

    // create new SWT image
    // TODO: this doesn't handle transparency
    ImageData sdata = s.getImageData();
    ImageData rdata = sdata.scaledTo(rw, rh);
    Image resultSwt = new Image(fwt.display, rdata);

    // paint new SWT image
    GC gc = new GC(resultSwt);
    Color bg = resultSwt.getBackground();
    if (bg == null) bg = fwt.display.getSystemColor(SWT.COLOR_WHITE);
    gc.setBackground(bg);
    gc.fillRectangle(0, 0, rw, rh);
    gc.drawImage(s, 0, 0, sw, sh, 0, 0, rw, rh);
    gc.dispose();

    return toFanImage(resultSwt);
  }

  public fan.gfx.Image imagePaint(FwtEnv self, fan.gfx.Size size, Func f)
  {
    int w = (int)size.w;
    int h = (int)size.h;
    Fwt fwt = Fwt.get();

    Image img = new Image(fwt.display, w, h);
    FwtGraphics g = new FwtGraphics(new GC(img), 0, 0, w, h);
    try
    {
      f.call(g);
      return toFanImage(img);
    }
    finally
    {
      g.dispose();
    }
  }

  // return new gfx::Image backed by new SWT image
  private fan.gfx.Image toFanImage(Image swtImage)
  {
    Uri uri = Uri.fromStr("mem-" + Uuid.make());
    fan.gfx.Image fanImage = fan.gfx.Image.makeFields(uri, null);
    Fwt.get().images.put(uri, swtImage);
    return fanImage;
  }

  public void imageDispose(FwtEnv self, fan.gfx.Image x)
  {
    Fwt.get().dispose(x);
  }

  public void imageWrite(FwtEnv self, fan.gfx.Image img, MimeType type, OutStream out)
  {
    try
    {
      // map mime type to SWT constant
      int format = -1;
      String mime = type.noParams().toString();
      if (mime.equals("image/png"))       format = SWT.IMAGE_PNG;
      else if (mime.equals("image/jpeg")) format = SWT.IMAGE_JPEG;
      else if (mime.equals("image/gif"))  format = SWT.IMAGE_GIF;
      else throw ArgErr.make("Unsupported mime type: " + mime);

      // map Fantom image to SWT image
      Fwt fwt = Fwt.get();
      Image swtImg = fwt.image(img);
      if (swtImg == null) throw Err.make("Image not valid or not loaded yet");

      // map Fantom output stream to Java output stream
      java.io.OutputStream jout = SysOutStream.java(out);

      // write the image
      ImageLoader saver = new ImageLoader();
      saver.data = new ImageData[] { swtImg.getImageData() };
      saver.save(jout, format);
      jout.flush();
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
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

  public void fontDispose(FwtEnv self, fan.gfx.Font x)
  {
    Fwt.get().dispose(x);
  }

  private GC scratchGC(fan.gfx.Font f)
  {
    Fwt fwt = Fwt.get();
    GC gc = fwt.scratchGC();
    gc.setFont(fwt.font(f));
    return gc;
  }

//////////////////////////////////////////////////////////////////////////
// Color Support
//////////////////////////////////////////////////////////////////////////

  public void colorDispose(FwtEnv self, fan.gfx.Color x)
  {
    Fwt.get().dispose(x);
  }

}
