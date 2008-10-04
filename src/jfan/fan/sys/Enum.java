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

  public static Enum make(Int ordinal, Str name)
  {
    // should never be used
    throw new IllegalStateException();
  }

  public static void make$(Enum self, Int ordinal, Str name)
  {
    if (ordinal == null || name == null) throw new NullErr().val;
    self.ordinal = ordinal;
    self.name    = name;
  }

  protected static Enum doFromStr(Type t, Str name, Bool checked)
  {
    // the compiler marks the value fields with the Enum flag
    Slot slot = t.slot(name.val, false);
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
    if (!checked.val) return null;
    throw ParseErr.make(t.qname().val, name).val;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Bool _equals(Object obj)
  {
    return this == obj ? Bool.True : Bool.False;
  }

  public final Int compare(Object obj)
  {
    return ordinal.compare(((Enum)obj).ordinal);
  }

  public Type type()
  {
    return Sys.EnumType;
  }

  public Str toStr()
  {
    return name;
  }

  public final Int ordinal()
  {
    return ordinal;
  }

  public final Str name()
  {
    return name;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Int ordinal;
  private Str name;

}