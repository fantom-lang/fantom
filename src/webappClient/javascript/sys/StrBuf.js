//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 08  Andy Frank  Creation
//

/**
 * StrBuf
 */
var sys_StrBuf = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function()
  {
    this.m_str = "";
  },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  type: function()
  {
    return sys_Type.find("sys::StrBuf");
  },

  add: function(obj)
  {
    this.m_str += obj==null ? "null" : sys_Obj._toStr(obj);
    return this;
  },

  addChar: function(ch)
  {
    this.m_str += ch;
    return this;
  },

  isEmpty: function()
  {
    return this.m_str == 0;
  },

  toStr: function()
  {
    return this.m_str;
  }

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_StrBuf.make = function() { return new sys_StrBuf(); }