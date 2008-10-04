//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//
package fan.sys;

import fanx.serial.*;

/**
 * Bool is a boolean value: true or false.
 */
public final class Bool
  extends FanObj
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Bool fromStr(Str s) { return fromStr(s, Bool.True); }
  public static Bool fromStr(Str s, Bool checked)
  {
    if (s.val.equals("true")) return True;
    if (s.val.equals("false")) return False;
    if (!checked.val) return null;
    throw ParseErr.make("Bool",  s).val;
  }

  public static Bool make(boolean b)  { return b ? True : False; }
  public static Bool make(int b) { return b != 0 ? True : False; }

  private Bool(boolean val)
  {
    this.val = val;
    this.str = val ? Str.make("true") : Str.make("false");
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Bool _equals(Obj obj)
  {
    return this == obj ? Bool.True : Bool.False;
  }

  public int hashCode()
  {
    return val ? 1231 : 1237;
  }

  public Int hash()
  {
    return val ? Int.make(1231) : Int.make(1237);
  }

  public Type type()
  {
    return Sys.BoolType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public final Bool not()
  {
    return val ? False : True;
  }

  public final Bool and(Bool b)
  {
    return val & b.val ? True : False;
  }

  public final Bool or(Bool b)
  {
    return val | b.val ? True : False;
  }

  public final Bool xor(Bool b)
  {
    return val ^ b.val ? True : False;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public final Str toStr()
  {
    return str;
  }

  public void encode(ObjEncoder out)
  {
    out.w(str.val);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Bool True  = new Bool(true);
  public static final Bool False = new Bool(false);

  public final boolean val;
  public final Str str;

}