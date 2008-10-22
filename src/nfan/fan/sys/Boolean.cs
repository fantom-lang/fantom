//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Oct 08  Andy Frank  Creation
//

namespace Fan.Sys
{
  ///
  /// Temp wrapper for bool primitive
  ///
  public sealed class Boolean
  {
    private Boolean(bool val)
    {
      this.val = val;
    }

    public override int GetHashCode()
    {
      return val ? 1231 : 1237;
    }

    public bool booleanValue() { return val; }

    public static Boolean valueOf(bool b) { return b ? True : False; }
    public static Boolean valueOf(int i)  { return i != 0 ? True : False; }
    public static Boolean valueOf(string s) { return valueOf(System.Boolean.Parse(s)); }

    public override string ToString() { return val ? "true" : "false"; }
    public static string toString(bool b) { return Boolean.valueOf(b).ToString(); }

    public static readonly Boolean True = new Boolean(true);
    public static readonly Boolean False = new Boolean(false);

    private bool val = false;
  }
}