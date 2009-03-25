//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 09  Andy Frank  Creation
//

/**
 * Enum
 */
var sys_Enum = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function() {},
  $make: function(ordinal, name)
  {
    if (name == null) throw new sys_NullErr();
    this.m_ordinal = ordinal;
    this.m_name = name;
  },

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals: function(that)
  {
    return this == that;
  },

  compare: function(that)
  {
    if (this.m_ordinal < that.m_ordinal) return -1;
    if (this.m_ordinal == that.m_ordinal) return 0;
    return +1;
  },

  type: function()
  {
    return sys_Type.find("sys::Enum");
  },

  toStr: function()
  {
    return this.m_name;
  },

  ordinal: function()
  {
    return this.m_ordinal;
  },

  name: function()
  {
    return this.m_name;
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  m_ordinal: 0,
  m_name: ""

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Enum.make = function(ordinal, name)
{
  // should never be used
  throw new Error();
}

/*
sys_Enum.doFromStr(t, name, checked)
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