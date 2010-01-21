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

    public static Enum make(long ordinal, string name)
    {
      // should never be used
      throw new System.Exception();
    }

    public static void make_(Enum self, long ordinal, string name)
    {
      if (name == null) throw new NullErr().val;
      self.m_ordinal = ordinal;
      self.m_name    = name;
    }

    protected static Enum doFromStr(Type t, string name, bool check)
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
      if (!check) return null;
      throw ParseErr.make(t.qname(), name).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override sealed long compare(object obj)
    {
      return FanInt.compare(m_ordinal, ((Enum)obj).m_ordinal);
    }

    public override Type @typeof()
    {
      return Sys.EnumType;
    }

    public override string toStr()
    {
      return m_name;
    }

    public long ordinal()
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

    private long m_ordinal;
    private string m_name;

  }
}