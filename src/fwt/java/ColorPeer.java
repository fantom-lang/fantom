//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

public class ColorPeer
{
  static final ColorPeer singleton = new ColorPeer();

  public static ColorPeer make(fan.fwt.Color self)
  {
    return singleton;
  }

  public void dispose(fan.fwt.Color f)
  {
    Env.get().dispose(f);
  }

}