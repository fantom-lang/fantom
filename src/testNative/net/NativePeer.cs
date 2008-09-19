//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Mar 06  Brian Frank  Creation
//

using Fan.Sys;

namespace Fan.TestNative
{
  /// <summary>
  /// Verify .NET native integration
  /// </summary>
  public class NativePeer
  {

    public static NativePeer make(Native t)
    {
      NativePeer peer = new NativePeer();
      peer.m_ctorY = t.m_y;
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

    public Int fX(Native t) { return t.m_x; }
    public void fX(Native t, Int x) { t.m_x = x; }

    public Int fA(Native t) { return m_fA; }
    public void fA(Native t, Int x) { m_fA = x; }

    public Str fV(Native t) { return m_fV; }
    public void fV(Native t, Str x) { m_fV = x; }

    public Int getPeerZ(Native t)
    {
      return m_z;
    }

    public void setPeerZ(Native t, Int z)
    {
      if (t.m_peer != this) throw new System.Exception();
      this.m_z = z;
    }

    public Int getCtorY(Native t)
    {
      return m_ctorY;
    }

    public Str defs1(Native t, Str a) { return a; }
    public Str defs2(Native t, Str a, Str b) { return Str.make(a.val+b.val);  }
    public Str defs3(Native t, Str a, Str b, Str c) { return Str.make(a.val+b.val+c.val);  }

    public static Str sdefs1(Str a) { return a; }
    public static Str sdefs2(Str a, Str b) { return Str.make(a.val+b.val);  }
    public static Str sdefs3(Str a, Str b, Str c) { return Str.make(a.val+b.val+c.val);  }

    Int m_ctorY;  // value of y during make()
    Int m_z;
    Int m_fA = Int.make(444);
    Str m_fV = Str.make("fV");

  }
}
