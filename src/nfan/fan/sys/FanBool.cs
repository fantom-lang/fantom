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

    public static Boolean fromStr(Str s) { return fromStr(s, Boolean.True); }
    public static Boolean fromStr(Str s, Boolean check)
    {
      if (s.val == "true") return Boolean.True;
      if (s.val == "false") return Boolean.False;
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

    public static Int hash(Boolean self)
    {
      return self.booleanValue() ? Int.make(1231) : Int.make(1237);
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

    public static Str toStr(Boolean self)
    {
      return self.booleanValue() ? trueStr : falseStr;
    }

    public static void encode(Boolean self, ObjEncoder @out)
    {
      @out.w(self.booleanValue() ? "true" : "false");
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly Str trueStr = Str.make("true");
    public static readonly Str falseStr = Str.make("false");

  }
}