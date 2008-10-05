//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//   4 Oct 08  Brian Frank  Refactor Boolean into Boolean/FanBool
//
package fan.sys;

import fanx.serial.*;

/**
 * FanBoolean defines the methods for sys::Bool.  The actual
 * class used for representation is java.lang.Boolean.
 */
public final class FanBool
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Boolean fromStr(Str s) { return fromStr(s, true); }
  public static Boolean fromStr(Str s, Boolean checked)
  {
    if (s.val.equals("true")) return true;
    if (s.val.equals("false")) return false;
    if (!checked) return null;
    throw ParseErr.make("Bool", s).val;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public static Boolean _equals(Boolean self, Object obj)
  {
    return self == obj;
  }

  public static Long hash(Boolean self)
  {
    return self ? Long.valueOf(1231) : Long.valueOf(1237);
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
    return !self;
  }

  public static Boolean and(Boolean self, Boolean b)
  {
    return self & b;
  }

  public static Boolean or(Boolean self, Boolean b)
  {
    return self | b;
  }

  public static Boolean xor(Boolean self, Boolean b)
  {
    return self ^ b;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public static Str toStr(Boolean self)
  {
    return self ? trueStr : falseStr;
  }

  public static void encode(Boolean self, ObjEncoder out)
  {
    out.w(self ? "true" : "false");
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Str trueStr = Str.make("true");
  public static final Str falseStr = Str.make("false");

}
