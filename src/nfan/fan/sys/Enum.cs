//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jan 07  Andy Frank  Creation
//

using Fanx.Fcode;

namespace Fan.Sys
{
  /// <summary>
  /// Enum base class.
  /// </summary>
  public abstract class Enum : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Enum make(Long ordinal, string name)
    {
      // should never be used
      throw new System.Exception();
    }

    public static void make_(Enum self, Long ordinal, string name)
    {
      if (ordinal == null || name == null) throw new NullErr().val;
      self.m_ordinal = ordinal;
      self.m_name    = name;
    }

    protected static Enum doFromStr(Type t, string name, Boolean check)
    {
      // the compiler marks the value fields with the Enum flag
      Slot slot = t.slot(name, false);
      if (slot != null && (slot.m_flags & FConst.Enum) != 0)
      {
        try
        {
          return (Enum)((Field)slot).get(null);
        }
        catch (System.Exception)
        {
        }
      }
      if (!check.booleanValue()) return null;
      throw ParseErr.make(t.qname(), name).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override sealed Boolean _equals(object obj)
    {
      return this == obj ? Boolean.True : Boolean.False;
    }

    public override sealed Long compare(object obj)
    {
      return FanInt.compare(m_ordinal, ((Enum)obj).m_ordinal);
    }

    public override Type type()
    {
      return Sys.EnumType;
    }

    public override string toStr()
    {
      return m_name;
    }

    public Long ordinal()
    {
      return m_ordinal;
    }

    public string name()
    {
      return m_name;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Long m_ordinal = null;
    private string m_name = null;

  }
}