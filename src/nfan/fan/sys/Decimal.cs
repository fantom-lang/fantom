//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 08  Andy Frank  Creation
//

using System.Globalization;
using Fanx.Serial;

namespace Fan.Sys
{
  ////<summary>
  /// Decimal
  /// </summary>
  public sealed class Decimal : Num, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static decimal Parse(string s)
    {
      return decimal.Parse(s,
          NumberStyles.AllowLeadingSign |
          NumberStyles.AllowExponent |
          NumberStyles.AllowDecimalPoint);
    }

    public static Decimal fromStr(Str s) { return fromStr(s.val, true); }
    public static Decimal fromStr(Str s, Bool check) { return fromStr(s.val, check.val); }
    public static Decimal fromStr(string s, bool check)
    {
      try
      {
        return make(Parse(s));
      }
      catch (System.FormatException)
      {
        if (!check) return null;
        throw ParseErr.make("Decimal",  s).val;
      }
    }

    public static Decimal make(decimal val)
    {
      return new Decimal(val);
    }

    private Decimal(decimal val) { this.val = val; }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Bool equals(Obj obj)
    {
      if (obj is Decimal)
      {
        return val == (obj as Decimal).val ? Bool.True : Bool.False;
      }
      return Bool.False;
    }

    public override Int compare(Obj obj)
    {
      return Int.make(val.CompareTo((obj as Decimal).val));
    }

    public override int GetHashCode()
    {
      return val.GetHashCode();
    }

    public override Int hash()
    {
      return Int.make(val.GetHashCode());
    }

    public override Type type()
    {
      return Sys.DecimalType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public Decimal negate    ()          { return make(-val); }
    public Decimal mult      (Decimal x) { return make(val * x.val); }
    public Decimal div       (Decimal x) { return make(val / x.val); }
    public Decimal mod       (Decimal x) { return make(val % x.val); }
    public Decimal plus      (Decimal x) { return make(val + x.val); }
    public Decimal minus     (Decimal x) { return make(val - x.val); }
    public Decimal increment ()          { return make(val+1); }
    public Decimal decrement ()          { return make(val-1); }

  //////////////////////////////////////////////////////////////////////////
  // Num
  //////////////////////////////////////////////////////////////////////////

    public override Int toInt() { return Int.make((long)val); }

    public override Float toFloat() { return Float.make((double)val); }

    public override Decimal toDecimal() { return this; }

  //////////////////////////////////////////////////////////////////////////
  // Math
  //////////////////////////////////////////////////////////////////////////

    public Decimal abs()
    {
      return (val >= 0) ? this : Decimal.make(-val);
    }

    public Decimal min(Decimal that)
    {
      if (val.CompareTo(that.val) <= 0) return this;
      return that;
    }

    public Decimal max(Decimal that)
    {
      if (val.CompareTo(that.val) >= 0) return this;
      return that;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public override Str toStr()
    {
      return Str.make(val.ToString());
    }

    public void encode(ObjEncoder @out)
    {
      @out.w(val.ToString()).w("d");
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly decimal val;

  }
}