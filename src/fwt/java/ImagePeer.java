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
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Rectangle;

public class ImagePeer
{
  static final ImagePeer singleton = new ImagePeer();

  public static ImagePeer make(fan.fwt.Image self)
  {
    return singleton;
  }

  public Size size(fan.fwt.Image f)
  {
    Image x = Env.get().image(f);
    if (x == null) return Size.def;
    Rectangle r = x.getBounds();
    return Size.make(Int.make(r.width), Int.make(r.height));
  }

  public void dispose(fan.fwt.Image f)
  {
    Env.get().dispose(f);
  }

}
