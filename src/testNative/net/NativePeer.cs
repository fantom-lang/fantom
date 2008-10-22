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

    public static Long doStaticA()
    {
      return Long.valueOf(2006);
    }

    public static Long doStaticB(Long a, Long b)
    {
      return Long.valueOf(a.longValue() + b.longValue());
    }

    public Long fX(Native t) { return t.m_x; }
    public void fX(Native t, Long x) { t.m_x = x; }

    public Long fA(Native t) { return m_fA; }
    public void fA(Native t, Long x) { m_fA = x; }

    public string fV(Native t) { return m_fV; }
    public void fV(Native t, string x) { m_fV = x; }

    public Long getPeerZ(Native t)
    {
      return m_z;
    }

    public void setPeerZ(Native t, Long z)
    {
      if (t.m_peer != this) throw new System.Exception();
      this.m_z = z;
    }

    public Long getCtorY(Native t)
    {
      return m_ctorY;
    }

    public string defs1(Native t, string a) { return a; }
    public string defs2(Native t, string a, string b) { return string.make(a.val+b.val);  }
    public string defs3(Native t, string a, string b, string c) { return string.make(a.val+b.val+c.val);  }

    public static string sdefs1(string a) { return a; }
    public static string sdefs2(string a, string b) { return string.make(a.val+b.val);  }
    public static string sdefs3(string a, string b, string c) { return string.make(a.val+b.val+c.val);  }

    Long m_ctorY;  // value of y during make()
    Long m_z;
    Long m_fA = Long.valueOf(444);
    string m_fV = string.make("fV");

  }
}