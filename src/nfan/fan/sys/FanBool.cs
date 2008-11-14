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
  /// FanBoolean defines the methods for sys::Bool.  The actual
  /// class used for representation is Fan.Sys.Boolean.
  /// </summary>
  public sealed class FanBool
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Boolean fromStr(string s) { return fromStr(s, Boolean.True); }
    public static Boolean fromStr(string s, Boolean check)
    {
      if (s == "true") return Boolean.True;
      if (s == "false") return Boolean.False;
      if (!check.booleanValue()) return null;
      throw ParseErr.make("Bool", s).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static Boolean equals(Boolean self, object obj)
    {
      return self == obj ? Boolean.True : Boolean.False;
    }

    public static long hash(Boolean self)
    {
      return self.booleanValue() ? 1231 : 1237;
    }

    public static Type type(Boolean self)
    {
      return Sys.BoolType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public static Boolean not(Boolean self)
    {
      return self.booleanValue() ? Boolean.False : Boolean.True;
    }

    public static Boolean and(Boolean self, Boolean b)
    {
      return self.booleanValue() & b.booleanValue() ? Boolean.True : Boolean.False;
    }

    public static Boolean or(Boolean self, Boolean b)
    {
      return self.booleanValue() | b.booleanValue() ? Boolean.True : Boolean.False;
    }

    public static Boolean xor(Boolean self, Boolean b)
    {
      return self.booleanValue() ^ b.booleanValue() ? Boolean.True : Boolean.False;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public static string toStr(Boolean self)
    {
      return self.booleanValue() ? "true" : "false";
    }

    public static void encode(Boolean self, ObjEncoder @out)
    {
      @out.w(self.booleanValue() ? "true" : "false");
    }

  }
}