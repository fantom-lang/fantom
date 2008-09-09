//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Mar 06  Brian Frank  Creation
//
package fan.testNative;

import fan.sys.*;

/**
 * Verify Java native integration
 */
public class NativePeer
{

  public static NativePeer make(Native t)
  {
    NativePeer peer = new NativePeer();
    peer.ctorY = t.y;
    return peer;
  }

  public static Int doStaticA()
  {
    return Int.make(2006);
  }

  public static Int doStaticB(Int a, Int b)
  {
    return a.plus(b);
  }

  public Int fX(Native t) { return t.x; }
  public void fX(Native t, Int x) { t.x = x; }

  public Int fA(Native t) { return fA; }
  public void fA(Native t, Int x) { fA = x; }

  public Str fV(Native t) { return fV; }
  public void fV(Native t, Str x) { fV = x; }

  public Int getPeerZ(Native t)
  {
    return z;
  }

  public void setPeerZ(Native t, Int z)
  {
    if (t.peer != this) throw new RuntimeException();
    this.z = z;
  }

  public Int getCtorY(Native t)
  {
    return ctorY;
  }

  public Str defs1(Native t, Str a) { return a; }
  public Str defs2(Native t, Str a, Str b) { return Str.make(a.val+b.val);  }
  public Str defs3(Native t, Str a, Str b, Str c) { return Str.make(a.val+b.val+c.val);  }

  public static Str sdefs1(Str a) { return a; }
  public static Str sdefs2(Str a, Str b) { return Str.make(a.val+b.val);  }
  public static Str sdefs3(Str a, Str b, Str c) { return Str.make(a.val+b.val+c.val);  }

  Int ctorY;  // value of y during make()
  Int z;
  Int fA = Int.make(444);
  Str fV = Str.make("fV");

}