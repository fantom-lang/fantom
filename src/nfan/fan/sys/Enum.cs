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

    public static Enum make(Int ordinal, Str name)
    {
      // should never be used
      throw new System.Exception();
    }

    public static void make_(Enum self, Int ordinal, Str name)
    {
      if (ordinal == null || name == null) throw new NullErr().val;
      self.m_ordinal = ordinal;
      self.m_name    = name;
    }

    protected static Enum doFromStr(Type t, Str name, Bool check)
    {
      // the compiler marks the value fields with the Enum flag
      Slot slot = t.slot(name.val, false);
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
      if (!check.val) return null;
      throw ParseErr.make(t.qname().val, name).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override sealed Bool equals(Obj obj)
    {
      return this == obj ? Bool.True : Bool.False;
    }

    public override sealed Int compare(Obj obj)
    {
      return m_ordinal.compare(((Enum)obj).m_ordinal);
    }

    public override Type type()
    {
      return Sys.EnumType;
    }

    public override Str toStr()
    {
      return m_name;
    }

    public Int ordinal()
    {
      return m_ordinal;
    }

    public Str name()
    {
      return m_name;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Int m_ordinal = null;
    private Str m_name = null;

  }
}
