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

  public static Long doStaticA()
  {
    return 2006L;
  }

  public static Long doStaticB(Long a, Long b)
  {
    return Long.valueOf(a.longValue() + b.longValue());
  }

  public Long fX(Native t) { return t.x; }
  public void fX(Native t, Long x) { t.x = x; }

  public Long fA(Native t) { return fA; }
  public void fA(Native t, Long x) { fA = x; }

  public String fV(Native t) { return fV; }
  public void fV(Native t, String x) { fV = x; }

  public Long getPeerZ(Native t)
  {
    return z;
  }

  public void setPeerZ(Native t, Long z)
  {
    if (t.peer != this) throw new RuntimeException();
    this.z = z;
  }

  public Long getCtorY(Native t)
  {
    return ctorY;
  }

  public String defs1(Native t, String a) { return a; }
  public String defs2(Native t, String a, String b) { return a + b;  }
  public String defs3(Native t, String a, String b, String c) { return a + b + c;  }

  public static String sdefs1(String a) { return a; }
  public static String sdefs2(String a, String b) { return a + b;  }
  public static String sdefs3(String a, String b, String c) { return a + b + c;  }

  Long ctorY;  // value of y during make()
  Long z;
  Long fA = 444L;
  String fV = "fV";

}