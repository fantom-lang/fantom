//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 08  Andy Frank  Creation
//

/**
 * Range represents a contiguous range of integers from start to end.
 */
var sys_Range = Class.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(start, end, exclusive)
  {
    this.m_start = start;
    this.m_end = end;
    if (exclusive != null) this.m_exclusive = exclusive;
  },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  type: function()
  {
    return sys_Type.find("sys::Range")
  },

  start: function(size)
  {
    if (size == null) return this.m_start;

    var x = this.m_start;
    if (x < 0) x = size + x;
    if (x > size) throw new sys_IndexErr(this);
    return x;
  },

  end: function(size)
  {
    if (size == null) return this.m_end;

    var x = this.m_end;
    if (x < 0) x = size + x;
    if (this.m_exclusive) x--;
    if (x >= size) throw new sys_IndexErr(this);
    return x;
  },

  toString: function()
  {
    if (this.m_exclusive)
      return this.m_start + "..." + this.m_end;
    else
      return this.m_start + ".." + this.m_end;
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  m_start: 0,
  m_end:   0,
  m_exclusive: false

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Range.make = function(start, end, exclusive)
{
  return new sys_Range(start, end, exclusive);
}