//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Range represents a contiguous range of integers from start to end.
 */
fan.sys.Range = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Range.prototype.$ctor = function(start, end, exclusive)
{
  this.m_start = start;
  this.m_end = end;
  this.m_exclusive = (exclusive == undefined) ? false : exclusive;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Range.prototype.type = function()
{
  return fan.sys.Type.find("sys::Range")
}

fan.sys.Range.prototype.start = function(size)
{
  if (size == null) return this.m_start;

  var x = this.m_start;
  if (x < 0) x = size + x;
  if (x > size) throw new fan.sys.IndexErr(this);
  return x;
}

fan.sys.Range.prototype.end = function(size)
{
  if (size == null) return this.m_end;

  var x = this.m_end;
  if (x < 0) x = size + x;
  if (this.m_exclusive) x--;
  if (x >= size) throw new fan.sys.IndexErr(this);
  return x;
}

fan.sys.Range.prototype.toString = function()
{
  if (this.m_exclusive)
    return this.m_start + "..." + this.m_end;
  else
    return this.m_start + ".." + this.m_end;
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Range.makeInclusive = function(start, end)
{
  return new fan.sys.Range(start, end, false);
}

fan.sys.Range.makeExclusive = function(start, end)
{
  return new fan.sys.Range(start, end, true);
}

fan.sys.Range.make = function(start, end, exclusive)
{
  return new fan.sys.Range(start, end, exclusive);
}

