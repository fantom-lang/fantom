//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 07  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// Param represents one parameter definition of a Func (or Method).
  /// </summary>
  public class Param : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public Param(Str name, Type of, int mask)
    {
      this.m_name = name;
      this.m_of   = of;
      this.m_mask = mask;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.ParamType; }

    public Str name()  { return m_name; }
    public Type of()   { return m_of; }
    public Bool hasDefault() { return Bool.make(m_mask & HAS_DEFAULT); }

    public override Str toStr() { return Str.make(m_of + " " + m_name); }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly int HAS_DEFAULT = 0x01;  // is a default value provided

    internal readonly Str m_name;
    internal readonly Type m_of;
    internal readonly int m_mask;
  }
}