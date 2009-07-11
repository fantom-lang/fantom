//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Enum
 */
fan.sys.Enum = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Enum.prototype.$ctor = function() {}

fan.sys.Enum.prototype.make$ = function(ordinal, name)
{
  if (name == null) throw new fan.sys.NullErr();
  this.m_ordinal = ordinal;
  this.m_name = name;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Enum.prototype.equals = function(that)
{
  return this == that;
}

fan.sys.Enum.prototype.compare = function(that)
{
  if (this.m_ordinal < that.m_ordinal) return -1;
  if (this.m_ordinal == that.m_ordinal) return 0;
  return +1;
}

fan.sys.Enum.prototype.type = function()
{
  return fan.sys.Type.find("sys::Enum");
}

fan.sys.Enum.prototype.toStr = function()
{
  return this.m_name;
}

fan.sys.Enum.prototype.ordinal = function()
{
  return this.m_ordinal;
}

fan.sys.Enum.prototype.name = function()
{
  return this.m_name;
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Enum.make = function(ordinal, name)
{
  // should never be used
  throw new Error();
}

/*
fan.sys.Enum.doFromStr(t, name, checked)
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
  throw ParseErr.make(t.qname(), name).val;
}
*/