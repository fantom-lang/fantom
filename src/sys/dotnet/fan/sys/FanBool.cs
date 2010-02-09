//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Sep 06  Andy Frank  Creation
//   16 Oct 08  Andy Frank  Refactor to FanBool
//

using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// Fanbool defines the methods for sys::Bool.  The actual
  /// class used for representation is System.Boolean.
  /// </summary>
  public sealed class FanBool
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Boolean fromStr(string s) { return fromStr(s, true); }
    public static Boolean fromStr(string s, bool check)
    {
      if (s == "true") return Boolean.True;
      if (s == "false") return Boolean.False;
      if (!check) return null;
      throw ParseErr.make("Bool", s).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static bool equals(bool self, object obj)
    {
      if (obj is Boolean)
        return self == ((Boolean)obj).booleanValue();
      else
        return false;
    }

    public static long hash(bool self)
    {
      return self ? 1231 : 1237;
    }

    public static Type type(bool self)
    {
      return Sys.BoolType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public static bool not(bool self)
    {
      return !self;
    }

    public static bool and(bool self, bool b)
    {
      return self & b;
    }

    public static bool or(bool self, bool b)
    {
      return self | b;
    }

    public static bool xor(bool self, bool b)
    {
      return self ^ b;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public static string toStr(bool self)
    {
      return self ? "true" : "false";
    }

    public static void encode(bool self, ObjEncoder @out)
    {
      @out.w(self ? "true" : "false");
    }

    public static string toCode(bool self)
    {
      return self ? "true" : "false";
    }

    public static string toLocale(bool self)
    {
      return Env.cur().locale(Sys.m_sysPod, self ? "boolTrue" : "boolFalse", toStr(self));
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly bool m_defVal = false;

  }
}