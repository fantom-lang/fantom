//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Sep 06  Andy Frank  Creation
//

using System;
using Fanx.Serial;

namespace Fan.Sys
{
  ///
  /// Bool is a boolean m_value: true or false.
  ///
  public sealed class Bool : FanObj, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Bool fromStr(Str s) { return fromStr(s, Bool.True); }
    public static Bool fromStr(Str s, Bool check)
    {
      if (s.val == "true") return True;
      if (s.val == "false") return False;
      if (!check.val) return null;
      throw ParseErr.make("Bool", s).val;
    }

    public static Bool make(bool b)  { return b ? True : False; }
    public static Bool make(int b) { return b != 0 ? True : False; }

    private Bool(bool val)
    {
      this.val = val;
      this.str = val ? Str.make("true") : Str.make("false");
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Bool _equals(Obj obj)
    {
      return this == obj ? Bool.True : Bool.False;
    }

    public override int GetHashCode()
    {
      return val ? 1231 : 1237;
    }

    public override Int hash()
    {
      return val ? Int.make(1231) : Int.make(1237);
    }

    public override Type type()
    {
      return Sys.BoolType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public Bool not()
    {
      return val ? False : True;
    }

    public Bool and(Bool b)
    {
      return val & b.val ? True : False;
    }

    public Bool or(Bool b)
    {
      return val | b.val ? True : False;
    }

    public Bool xor(Bool b)
    {
      return val ^ b.val ? True : False;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public override Str toStr()
    {
      return str;
    }

    public void encode(ObjEncoder @out)
    {
      @out.w(str.val);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly Bool True  = new Bool(true);
    public static readonly Bool False = new Bool(false);

    public readonly bool val;
    public readonly Str str;
  }
}