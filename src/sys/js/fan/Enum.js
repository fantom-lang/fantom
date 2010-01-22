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

fan.sys.Enum.make = function(ordinal, name)
{
  // should never be used
  throw new Error();
}

fan.sys.Enum.make$ = function(self, ordinal, name)
{
  if (name == null) throw fan.sys.NullErr.make();
  self.m_ordinal = ordinal;
  self.m_name = name;
}

fan.sys.Enum.doFromStr = function(t, name, checked)
{
  // the compiler marks the value fields with the Enum flag
  var slot = t.slot(name, false);
  if (slot != null && (slot.m_flags & fan.sys.FConst.Enum) != 0)
  {
    try
    {
      return slot.get(null);
    }
    catch (err) {}
  }
  if (!checked) return null;
  throw fan.sys.ParseErr.make(t.qname(), name);
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

fan.sys.Enum.prototype.$typeof = function()    { return fan.sys.Enum.$type; }
fan.sys.Enum.prototype.toStr = function()   { return this.m_name; }
fan.sys.Enum.prototype.ordinal = function() { return this.m_ordinal; }
fan.sys.Enum.prototype.name = function()    { return this.m_name; }


