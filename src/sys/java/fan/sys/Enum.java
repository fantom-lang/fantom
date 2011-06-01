//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 06  Brian Frank  Creation
//
package fan.sys;

import fanx.fcode.*;

/**
 * Enum base class.
 */
public abstract class Enum
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Enum make(long ordinal, String name)
  {
    // should never be used
    throw new IllegalStateException();
  }

  public static void make$(Enum self, long ordinal, String name)
  {
    if (name == null) throw NullErr.make();
    self.ordinal = ordinal;
    self.name    = name;
  }

  protected static Enum doFromStr(Type t, String name, boolean checked)
  {
    // the compiler marks the value fields with the Enum flag
    Slot slot = t.slot(name, false);
    if (slot != null && (slot.flags & FConst.Enum) != 0)
    {
      try
      {
        return (Enum)((Field)slot).get(null);
      }
      catch (Exception e)
      {
      }
    }
    if (!checked) return null;
    throw ParseErr.make(t.qname(), name);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final boolean equals(Object obj)
  {
    return this == obj;
  }

  public final long compare(Object obj)
  {
    return FanInt.compare(ordinal, ((Enum)obj).ordinal);
  }

  public Type typeof()
  {
    return Sys.EnumType;
  }

  public String toStr()
  {
    return name;
  }

  public final long ordinal()
  {
    return ordinal;
  }

  public final String name()
  {
    return name;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private long ordinal;
  private String name;

}